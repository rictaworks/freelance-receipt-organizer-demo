# frozen_string_literal: true

# CLASSIFY_RULES（設計書 2 ER図 / 1.6 マスタ 36件）: F3 ルールベース分類のキーワード。
# キーワード文字列は seed（DB）に分離する（CLAUDE.md §4）。
class CreateClassifyRules < ActiveRecord::Migration[7.2]
  def change
    create_table :classify_rules do |t|
      t.references :account_category, null: false, foreign_key: true
      t.string :keyword, null: false
      # priority: 数値が大きいほど分類の優先度が高い（F3）。
      t.integer :priority, null: false, default: 1
    end
    add_index :classify_rules, :keyword
  end
end
