# frozen_string_literal: true

# 項目抽出（設計書 5 クラス図 FieldExtractor / F2）。
# OCR 全文テキストから 日付・金額・店名 を抽出する。抽出不能なフィールドは nil。
# 金額ラベル辞書は DB（AmountLabels）から取得する（文字列リテラルの分離: CLAUDE.md §4）。
class FieldExtractor
  # 令和元年 = 西暦2019年（2018 + N）。
  REIWA_BASE_YEAR = 2018

  # 抽出結果。
  Result = Struct.new(:issued_on, :amount_yen, :store_name, keyword_init: true)

  # 全項目をまとめて抽出する。
  def extract(full_text)
    Result.new(
      issued_on: extract_date(full_text),
      amount_yen: extract_amount(full_text),
      store_name: extract_store_name(full_text)
    )
  end

  # --- 日付抽出（西暦・和暦・年省略補完） ---------------------------------

  def extract_date(text)
    return nil if text.nil? || text.strip.empty?

    text.each_line do |line|
      date = try_western(line) ||
             try_wareki_kanji(line) ||
             try_wareki_abbrev(line) ||
             try_yearless(line)
      return date if date
    end
    nil
  end

  # --- 金額抽出（ラベル辞書優先→最大値） -------------------------------

  def extract_amount(text)
    return nil if text.nil? || text.strip.empty?

    lines = text.lines.map { |l| l.chomp.strip }
    exclude = exclude_labels

    # 1) 採用ラベル（合計>税込合計>お買上げ計）の近傍数値を優先度順に探す。
    adopt_labels.each do |label|
      lines.each do |line|
        next unless line.include?(label)
        next if exclude.any? { |ex| line.include?(ex) }

        amount = largest_number_in(line)
        return amount unless amount.nil?
      end
    end

    # 2) ラベルが無い場合のみ最大値を採用（除外ラベル行・日付行は対象外）。
    monetary = lines.reject { |l| exclude.any? { |ex| l.include?(ex) } }
                    .flat_map { |l| monetary_numbers_in(l) }
    return monetary.max unless monetary.empty?

    # 3) 通貨記号なしの数値しかない場合は日付行以外の最大値。
    plain = lines.reject { |l| exclude.any? { |ex| l.include?(ex) } || date_like?(l) }
                 .flat_map { |l| all_numbers_in(l) }
    plain.max
  end

  # --- 店名抽出（先頭3行の最長行） -------------------------------------

  def extract_store_name(text)
    return nil if text.nil? || text.strip.empty?

    lines = text.lines.map(&:strip).reject(&:empty?)
    head = lines.first(3)
    candidates = head.reject { |l| date_like?(l) || phone_like?(l) || postal_like?(l) }
    return nil if candidates.empty?

    candidates.max_by(&:length)
  end

  private

  # 西暦: YYYY/MM/DD, YYYY-MM-DD, YYYY年MM月DD日
  def try_western(line)
    m = line.match(%r{(\d{4})[/\-年](\d{1,2})[/\-月](\d{1,2})日?})
    return nil unless m

    build_date(m[1].to_i, m[2].to_i, m[3].to_i)
  end

  # 和暦（漢字）: 令和N年M月D日
  def try_wareki_kanji(line)
    m = line.match(/令和(\d{1,2})年(\d{1,2})月(\d{1,2})日?/)
    return nil unless m

    build_date(REIWA_BASE_YEAR + m[1].to_i, m[2].to_i, m[3].to_i)
  end

  # 和暦（略記）: RN.M.D
  def try_wareki_abbrev(line)
    m = line.match(/R(\d{1,2})\.(\d{1,2})\.(\d{1,2})/)
    return nil unless m

    build_date(REIWA_BASE_YEAR + m[1].to_i, m[2].to_i, m[3].to_i)
  end

  # 年省略: MM/DD, MM月DD日 → 当年補完。未来日なら前年へ補正。
  def try_yearless(line)
    m = line.match(%r{(?<![\d/\-年])(\d{1,2})[/月](\d{1,2})日?})
    return nil unless m

    today = Time.zone.today
    date = build_date(today.year, m[1].to_i, m[2].to_i)
    return nil if date.nil?

    date = date.prev_year if date > today
    date
  end

  # 妥当な日付なら Date を返し、不正（2月30日等）は nil。
  def build_date(year, month, day)
    Date.new(year, month, day)
  rescue ArgumentError
    nil
  end

  def adopt_labels
    AmountLabel.adopt_labels.pluck(:label)
  end

  def exclude_labels
    AmountLabel.exclude_labels.pluck(:label)
  end

  # 行内の数値トークンの最大値（¥・カンマ・円を除去）。負記号(-/△/▲)を考慮。
  def largest_number_in(line)
    all_numbers_in(line).max
  end

  def all_numbers_in(line)
    line.scan(/([-△▲]?)\s*[¥\\]?\s*(\d[\d,]*)\s*円?/).map do |sign, digits|
      value = digits.delete(",").to_i
      negative?(sign) ? -value : value
    end
  end

  # 通貨コンテキスト（¥ / 円 / カンマ区切り）を持つ数値のみ抽出する。
  def monetary_numbers_in(line)
    results = []
    line.scan(/([-△▲]?)\s*[¥\\]\s*(\d[\d,]*)/) do |sign, digits|
      results << signed(sign, digits)
    end
    line.scan(/([-△▲]?)\s*(\d[\d,]*)\s*円/) do |sign, digits|
      results << signed(sign, digits)
    end
    line.scan(/([-△▲]?)\s*(\d{1,3}(?:,\d{3})+)/) do |sign, digits|
      results << signed(sign, digits)
    end
    results
  end

  def signed(sign, digits)
    value = digits.delete(",").to_i
    negative?(sign) ? -value : value
  end

  def negative?(sign)
    ["-", "△", "▲"].include?(sign)
  end

  def date_like?(line)
    line.match?(%r{\d{4}[/\-年]\d{1,2}[/\-月]\d{1,2}}) ||
      line.match?(/令和\d{1,2}年/) ||
      line.match?(/R\d{1,2}\.\d{1,2}\.\d{1,2}/)
  end

  def phone_like?(line)
    line.match?(/\d{2,4}-\d{2,4}-\d{3,4}/) ||
      line.match?(/(電話|TEL|ＴＥＬ|℡)/i)
  end

  def postal_like?(line)
    line.match?(/〒\s*\d{3}-?\d{4}/) || line.match?(/\b\d{3}-\d{4}\b/)
  end
end
