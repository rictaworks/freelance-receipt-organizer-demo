# frozen_string_literal: true

require "rails_helper"

# F2 項目抽出の単体テスト。
RSpec.describe FieldExtractor do
  subject(:extractor) { described_class.new }

  describe "#extract_date" do
    it "西暦 YYYY/MM/DD を抽出する" do
      expect(extractor.extract_date("2026/06/30")).to eq(Date.new(2026, 6, 30))
    end

    it "西暦 YYYY年MM月DD日 を抽出する" do
      expect(extractor.extract_date("2026年6月30日")).to eq(Date.new(2026, 6, 30))
    end

    it "西暦 YYYY-MM-DD を抽出する" do
      expect(extractor.extract_date("2026-06-30")).to eq(Date.new(2026, 6, 30))
    end

    it "和暦（令和N年M月D日）を西暦へ変換する" do
      expect(extractor.extract_date("令和8年6月30日")).to eq(Date.new(2026, 6, 30))
    end

    it "和暦（RN.M.D）を西暦へ変換する" do
      expect(extractor.extract_date("R8.6.30")).to eq(Date.new(2026, 6, 30))
    end

    context "年省略（MM/DD）" do
      before { allow(Time.zone).to receive(:today).and_return(Date.new(2026, 7, 4)) }

      it "当年で補完する" do
        expect(extractor.extract_date("01/15")).to eq(Date.new(2026, 1, 15))
      end

      it "補完結果が未来日なら前年へ補正する" do
        expect(extractor.extract_date("12/31")).to eq(Date.new(2025, 12, 31))
      end
    end

    it "複数候補は最上部の行を採用する" do
      text = "2026/01/10\n2025/12/01"
      expect(extractor.extract_date(text)).to eq(Date.new(2026, 1, 10))
    end

    it "不正な日付は抽出しない（nil）" do
      expect(extractor.extract_date("店名だけの行")).to be_nil
    end
  end

  describe "#extract_amount" do
    it "ラベル『合計』の近傍数値を採用し ¥・カンマを除去する" do
      expect(extractor.extract_amount("合計 ¥1,480")).to eq(1480)
    end

    it "『円』表記を除去する" do
      expect(extractor.extract_amount("合計 1,480円")).to eq(1480)
    end

    it "小計は除外し合計を採用する" do
      text = "小計 ¥1,000\n消費税 ¥100\n合計 ¥1,100"
      expect(extractor.extract_amount(text)).to eq(1100)
    end

    it "お預り・お釣りは除外する" do
      text = "合計 ¥4,980\nお預り ¥5,000\nお釣り ¥20"
      expect(extractor.extract_amount(text)).to eq(4980)
    end

    it "税込合計を採用する（合計行が無い場合）" do
      expect(extractor.extract_amount("税込合計 ¥1,480")).to eq(1480)
    end

    it "ラベルが無い場合は最大値を採用する" do
      text = "1,000\n500\n2,000"
      expect(extractor.extract_amount(text)).to eq(2000)
    end

    it "0以下（返品）の金額も抽出する" do
      expect(extractor.extract_amount("合計 ▲500")).to eq(-500)
    end

    it "抽出不能なら nil" do
      expect(extractor.extract_amount("金額のない行")).to be_nil
    end
  end

  describe "#extract_store_name" do
    it "先頭3行のうち日付を含まない最長行を採用する" do
      text = "スーパーマルエツ\n2026/06/30\n合計 1480"
      expect(extractor.extract_store_name(text)).to eq("スーパーマルエツ")
    end

    it "郵便番号・電話番号の行を除外する" do
      text = "〒123-4567 東京都\n電話 03-1234-5678\nカフェドトール"
      expect(extractor.extract_store_name(text)).to eq("カフェドトール")
    end

    it "候補が無ければ nil" do
      expect(extractor.extract_store_name("2026/06/30")).to be_nil
    end
  end

  describe "#extract" do
    it "日付・金額・店名をまとめて返す" do
      text = "セブンイレブン\n2026/06/30\n合計 ¥550"
      result = extractor.extract(text)
      expect(result.issued_on).to eq(Date.new(2026, 6, 30))
      expect(result.amount_yen).to eq(550)
      expect(result.store_name).to eq("セブンイレブン")
    end
  end
end
