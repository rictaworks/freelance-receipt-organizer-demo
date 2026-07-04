# frozen_string_literal: true

require "rails_helper"

# 領収書 API（F1/F2/F3/F6/F8）。
RSpec.describe "Receipts API", type: :request do
  describe "POST /receipts" do
    it "ハニーポット（website）に値があれば 200 で無言破棄し DB/OCR を呼ばない（F8）" do
      expect(OcrClient).not_to receive(:call)

      post "/receipts", params: { file: png_upload, website: "http://spam.example" }

      expect(response).to have_http_status(:ok)
      expect(json_body).to eq("status" => "accepted")
      expect(Receipt.count).to eq(0)
    end

    it "file 未指定は 400 FILE_MISSING" do
      post "/receipts", params: { website: "" }
      expect(response).to have_http_status(:bad_request)
      expect(json_body.dig("error", "code")).to eq("FILE_MISSING")
    end

    it "JPEG/PNG 以外は 415 UNSUPPORTED_MEDIA_TYPE" do
      post "/receipts", params: { file: txt_upload }
      expect(response).to have_http_status(:unsupported_media_type)
      expect(json_body.dig("error", "code")).to eq("UNSUPPORTED_MEDIA_TYPE")
    end

    it "10MB 超過は 413 FILE_TOO_LARGE" do
      post "/receipts", params: { file: oversized_png_upload }
      expect(response).to have_http_status(413)
      expect(json_body.dig("error", "code")).to eq("FILE_TOO_LARGE")
    end

    it "正常時は抽出・分類して 201 で登録する" do
      stub_ocr(full_text: "タクシー株式会社\n東京都新宿区\n2026/06/30\n利用料金\n合計 ¥1,480", confidence: 0.82)

      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(:created)
      receipt = json_body["receipt"]
      expect(receipt["issued_on"]).to eq("2026-06-30")
      expect(receipt["amount_yen"]).to eq(1480)
      expect(receipt["store_name"]).to eq("タクシー株式会社")
      expect(receipt["category_name"]).to eq("旅費交通費")
      expect(receipt["image_path"]).to match(%r{\A/uploads/})
      expect(Receipt.count).to eq(1)
    end

    it "キーワード未一致は未分類として登録し warning=uncategorized" do
      stub_ocr(full_text: "無名の商店\n2026/06/30\n合計 ¥500", confidence: 0.82)

      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(:created)
      expect(json_body["receipt"]["category_id"]).to be_nil
      expect(warning_codes).to include("uncategorized")
    end

    it "金額 0 以下は warning=non_positive_amount 付きで登録する" do
      stub_ocr(full_text: "返品店\n2026/06/30\n合計 ▲500", confidence: 0.82)

      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(:created)
      expect(json_body["receipt"]["amount_yen"]).to eq(-500)
      expect(warning_codes).to include("non_positive_amount")
    end

    it "日付＋金額＋店名の完全一致は warning=duplicate" do
      stub_ocr(full_text: "タクシー株式会社\n2026/06/30\n合計 ¥1,480", confidence: 0.82)
      post "/receipts", params: { file: png_upload }
      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(:created)
      expect(warning_codes).to include("duplicate")
      expect(Receipt.count).to eq(2)
    end

    it "信頼度低＋日付金額抽出不能（店名あり）は 201 で warning=low_confidence_manual_input" do
      stub_ocr(full_text: "うすい印字のレシート\nありがとうございました", confidence: 0.1)

      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(:created)
      expect(json_body["receipt"]["issued_on"]).to be_nil
      expect(json_body["receipt"]["amount_yen"]).to be_nil
      expect(warning_codes).to include("low_confidence_manual_input")
    end

    it "信頼度低＋全項目抽出不能は 422 OCR_UNRECOGNIZABLE" do
      stub_ocr(full_text: "", confidence: 0.1)

      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(422)
      expect(json_body.dig("error", "code")).to eq("OCR_UNRECOGNIZABLE")
      expect(Receipt.count).to eq(0)
    end

    it "OCR 呼び出し失敗は 502 OCR_SERVICE_UNAVAILABLE（フォールバック分類しない）" do
      allow(OcrClient).to receive(:call).and_raise(ApiError.new("OCR_SERVICE_UNAVAILABLE"))

      post "/receipts", params: { file: png_upload }

      expect(response).to have_http_status(:bad_gateway)
      expect(json_body.dig("error", "code")).to eq("OCR_SERVICE_UNAVAILABLE")
      expect(Receipt.count).to eq(0)
    end
  end

  describe "GET /receipts" do
    it "0 件でも 200 で空配列を返す" do
      get "/receipts"
      expect(response).to have_http_status(:ok)
      expect(json_body).to eq("receipts" => [], "count" => 0)
    end

    it "session_id で強制フィルタし他セッションの領収書は返さない（F6）" do
      other = Session.create!(session_id: SecureRandom.uuid, created_at: Time.current, last_accessed_at: Time.current)
      Receipt.create!(session_id: other.session_id, issued_on: Date.new(2026, 6, 1), amount_yen: 100,
                      store_name: "他人の店", manually_edited: false, created_at: Time.current)

      get "/receipts"

      expect(response).to have_http_status(:ok)
      expect(json_body["count"]).to eq(0)
    end

    it "category_id=0 で未分類のみ絞り込む" do
      stub_ocr(full_text: "無名の商店\n2026/06/30\n合計 ¥500", confidence: 0.82)
      post "/receipts", params: { file: png_upload } # 未分類
      stub_ocr(full_text: "タクシー株式会社\n2026/06/30\n合計 ¥1,480", confidence: 0.82)
      post "/receipts", params: { file: png_upload } # 旅費交通費

      get "/receipts", params: { category_id: 0 }

      expect(json_body["count"]).to eq(1)
      expect(json_body["receipts"].first["category_id"]).to be_nil
    end
  end

  describe "PATCH /receipts/:id" do
    let(:receipt) do
      stub_ocr(full_text: "タクシー株式会社\n2026/06/30\n合計 ¥1,480", confidence: 0.82)
      post "/receipts", params: { file: png_upload }
      Receipt.find(json_body["receipt"]["id"])
    end

    it "科目を変更し manually_edited=true にする" do
      patch "/receipts/#{receipt.id}", params: { category_id: 3 }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["receipt"]["category_id"]).to eq(3)
      expect(json_body["receipt"]["category_name"]).to eq("通信費")
      expect(json_body["receipt"]["manually_edited"]).to be(true)
    end

    it "存在しない/他セッションは 404 RECEIPT_NOT_FOUND（存在秘匿）" do
      other = Session.create!(session_id: SecureRandom.uuid, created_at: Time.current, last_accessed_at: Time.current)
      foreign = Receipt.create!(session_id: other.session_id, issued_on: Date.new(2026, 6, 1), amount_yen: 100,
                                store_name: "他人", manually_edited: false, created_at: Time.current)

      get "/session" # 自セッション確立
      patch "/receipts/#{foreign.id}", params: { category_id: 3 }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json_body.dig("error", "code")).to eq("RECEIPT_NOT_FOUND")
    end

    it "存在しない科目は 422 INVALID_CATEGORY" do
      patch "/receipts/#{receipt.id}", params: { category_id: 999 }, as: :json
      expect(response).to have_http_status(422)
      expect(json_body.dig("error", "code")).to eq("INVALID_CATEGORY")
    end

    it "整数でない金額は 422 INVALID_AMOUNT" do
      patch "/receipts/#{receipt.id}", params: { amount_yen: "abc" }, as: :json
      expect(response).to have_http_status(422)
      expect(json_body.dig("error", "code")).to eq("INVALID_AMOUNT")
    end

    it "不正な日付形式は 400 INVALID_DATE_FORMAT" do
      patch "/receipts/#{receipt.id}", params: { issued_on: "2026/06/30" }, as: :json
      expect(response).to have_http_status(:bad_request)
      expect(json_body.dig("error", "code")).to eq("INVALID_DATE_FORMAT")
    end
  end

  def warning_codes
    json_body["warnings"].map { |w| w["code"] }
  end
end
