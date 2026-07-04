# frozen_string_literal: true

# 領収書のレスポンス整形（SPEC/api/receipts.md）。category_name を解決する。
module ReceiptPresenter
  module_function

  def category_name_for(category_id)
    return nil if category_id.nil?

    AccountCategory.find_by(id: category_id)&.name
  end

  # POST /receipts の詳細表現（image_path 等を含む）。
  def detail(receipt)
    {
      "id" => receipt.id,
      "issued_on" => receipt.issued_on&.iso8601,
      "amount_yen" => receipt.amount_yen,
      "store_name" => receipt.store_name,
      "category_id" => receipt.category_id,
      "category_name" => category_name_for(receipt.category_id),
      "ocr_confidence" => receipt.ocr_confidence,
      "image_path" => receipt.image_path,
      "manually_edited" => receipt.manually_edited,
      "created_at" => receipt.created_at&.iso8601
    }
  end

  # GET /receipts 一覧の表現。
  def summary(receipt)
    {
      "id" => receipt.id,
      "issued_on" => receipt.issued_on&.iso8601,
      "amount_yen" => receipt.amount_yen,
      "store_name" => receipt.store_name,
      "category_id" => receipt.category_id,
      "category_name" => category_name_for(receipt.category_id),
      "ocr_confidence" => receipt.ocr_confidence,
      "manually_edited" => receipt.manually_edited
    }
  end

  # PATCH /receipts/:id の表現。
  def updated(receipt)
    {
      "id" => receipt.id,
      "issued_on" => receipt.issued_on&.iso8601,
      "amount_yen" => receipt.amount_yen,
      "store_name" => receipt.store_name,
      "category_id" => receipt.category_id,
      "category_name" => category_name_for(receipt.category_id),
      "manually_edited" => receipt.manually_edited
    }
  end
end
