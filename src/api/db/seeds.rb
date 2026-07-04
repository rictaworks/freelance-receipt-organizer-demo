# frozen_string_literal: true

# マスタ seed（設計書 1.6 / SPEC/api/categories.md）。
# 勘定科目 12件・分類キーワードルール 36件（各科目3語, priority付き）・金額ラベル辞書 6件。
# priority は数値が大きいほど分類の優先度が高い（F3）。キーワード文字列は DB に分離（CLAUDE.md §4）。

# id は SPEC/api/categories.md の並び順(1〜12)に一致させる。
CATEGORIES = [
  { code: "SHOMOHIN", name: "消耗品費",   keywords: [["文具", 3], ["事務用品", 3], ["ホームセンター", 2]] },
  { code: "RYOHI",    name: "旅費交通費", keywords: [["タクシー", 3], ["JR", 3], ["航空", 3]] },
  { code: "TSUSHIN",  name: "通信費",     keywords: [["携帯", 3], ["インターネット", 3], ["切手", 2]] },
  { code: "SETTAI",   name: "接待交際費", keywords: [["居酒屋", 3], ["レストラン", 2], ["贈答", 3]] },
  { code: "KAIGI",    name: "会議費",     keywords: [["会議室", 3], ["喫茶", 2], ["カフェ", 2]] },
  { code: "TOSHO",    name: "新聞図書費", keywords: [["書店", 3], ["新聞", 3], ["書籍", 3]] },
  { code: "KONETSU",  name: "水道光熱費", keywords: [["電気", 3], ["ガス", 3], ["水道", 3]] },
  { code: "YACHIN",   name: "地代家賃",   keywords: [["家賃", 3], ["賃料", 3], ["駐車場", 2]] },
  { code: "GAICHU",   name: "外注工賃",   keywords: [["外注", 3], ["業務委託", 3], ["委託", 2]] },
  { code: "SHUZEN",   name: "修繕費",     keywords: [["修理", 3], ["修繕", 3], ["メンテナンス", 2]] },
  { code: "SOZEI",    name: "租税公課",   keywords: [["収入印紙", 3], ["印紙", 2], ["登録免許税", 3]] },
  { code: "ZAPPI",    name: "雑費",       keywords: [["手数料", 2], ["サービス料", 2], ["雑費", 3]] }
].freeze

# 金額ラベル辞書（採用: 合計>税込合計>お買上げ計 / 除外: 小計/お預り/お釣り）。
AMOUNT_LABELS = [
  { label: "合計",       kind: "adopt",   priority: 30 },
  { label: "税込合計",   kind: "adopt",   priority: 20 },
  { label: "お買上げ計", kind: "adopt",   priority: 10 },
  { label: "小計",       kind: "exclude", priority: 0 },
  { label: "お預り",     kind: "exclude", priority: 0 },
  { label: "お釣り",     kind: "exclude", priority: 0 }
].freeze

ActiveRecord::Base.transaction do
  CATEGORIES.each do |attrs|
    category = AccountCategory.find_or_create_by!(code: attrs[:code]) do |c|
      c.name = attrs[:name]
    end
    category.update!(name: attrs[:name])

    attrs[:keywords].each do |(keyword, priority)|
      rule = ClassifyRule.find_or_initialize_by(account_category_id: category.id, keyword: keyword)
      rule.priority = priority
      rule.save!
    end
  end

  AMOUNT_LABELS.each do |attrs|
    label = AmountLabel.find_or_initialize_by(label: attrs[:label])
    label.kind = attrs[:kind]
    label.priority = attrs[:priority]
    label.save!
  end
end

Rails.logger.info(
  {
    event: "seed_completed",
    account_categories: AccountCategory.count,
    classify_rules: ClassifyRule.count,
    amount_labels: AmountLabel.count
  }.to_json
)
