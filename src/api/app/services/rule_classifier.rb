# frozen_string_literal: true

# 勘定科目分類（設計書 5 クラス図 RuleClassifier / F3）。
# 店名＋OCR全文に対しキーワードルールをマッチし、
# 優先度→出現回数→科目コード(id)昇順 でタイ解決する。マッチなしは nil（未分類）。
class RuleClassifier
  # text: 店名＋OCR全文を結合したテキスト。
  # 戻り値: 採用した account_category の id、マッチなしは nil。
  def classify(text)
    return nil if text.nil? || text.strip.empty?

    matched = ClassifyRule.all.select { |rule| rule.matches?(text) }
    return nil if matched.empty?

    resolve_tie(matched, text)
  end

  private

  # タイ解決（設計書 5: resolveTie）。
  # 1. 科目ごとの最大優先度が高い科目
  # 2. 同点なら全文中のキーワード出現回数の合計が多い科目
  # 3. なお同点なら科目コード(id)昇順
  def resolve_tie(matched_rules, text)
    scored = matched_rules.group_by(&:account_category_id).map do |category_id, rules|
      max_priority = rules.map(&:priority).max
      occurrences = rules.sum { |rule| text.scan(rule.keyword).size }
      { category_id: category_id, priority: max_priority, occurrences: occurrences }
    end

    best = scored.max_by { |s| [s[:priority], s[:occurrences], -s[:category_id]] }
    best[:category_id]
  end
end
