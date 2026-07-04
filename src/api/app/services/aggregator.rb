# frozen_string_literal: true

# 集計（設計書 5 クラス図 Aggregator / F4）。
# session_id 配下の領収書を 月×勘定科目 で集計し、科目別年間合計・総合計を返す（整数円）。
# 未分類（category_id = null）も独立区分として集計する。
class Aggregator
  # session_id と対象年から集計結果ハッシュを構築する（SPEC/api/aggregations.md 準拠）。
  def aggregate(session_id:, year:)
    receipts = Receipt.where(session_id: session_id)
                      .where(issued_on: Date.new(year, 1, 1)..Date.new(year, 12, 31))
                      .to_a

    {
      "target_year" => year,
      "months" => build_months(receipts),
      "category_yearly_totals" => build_yearly_totals(receipts),
      "grand_total_yen" => receipts.sum { |r| r.amount_yen.to_i }
    }
  end

  private

  def uncategorized_label
    AppConfig.report.fetch("uncategorized_label")
  end

  def category_names
    @category_names ||= AccountCategory.pluck(:id, :name).to_h
  end

  def name_for(category_id)
    category_id.nil? ? uncategorized_label : category_names[category_id]
  end

  # 月ごと（データのある月のみ）に科目別合計を構築する。
  def build_months(receipts)
    by_month = receipts.group_by { |r| r.issued_on.month }
    by_month.keys.sort.map do |month|
      month_receipts = by_month[month]
      {
        "month" => month,
        "categories" => category_rows(month_receipts),
        "month_total_yen" => month_receipts.sum { |r| r.amount_yen.to_i }
      }
    end
  end

  # 科目別行（未分類は末尾）。
  def category_rows(receipts)
    by_cat = receipts.group_by(&:category_id)
    sorted_ids = by_cat.keys.sort_by { |cid| cid.nil? ? Float::INFINITY : cid }
    sorted_ids.map do |cid|
      {
        "category_id" => cid,
        "category_name" => name_for(cid),
        "total_yen" => by_cat[cid].sum { |r| r.amount_yen.to_i }
      }
    end
  end

  # 科目別年間合計（出現科目を id 昇順、末尾に未分類を必ず付す）。
  def build_yearly_totals(receipts)
    by_cat = receipts.group_by(&:category_id)
    present_ids = by_cat.keys.compact.sort
    rows = present_ids.map do |cid|
      {
        "category_id" => cid,
        "category_name" => name_for(cid),
        "total_yen" => by_cat[cid].sum { |r| r.amount_yen.to_i }
      }
    end
    uncategorized_total = (by_cat[nil] || []).sum { |r| r.amount_yen.to_i }
    rows << {
      "category_id" => nil,
      "category_name" => uncategorized_label,
      "total_yen" => uncategorized_total
    }
    rows
  end
end
