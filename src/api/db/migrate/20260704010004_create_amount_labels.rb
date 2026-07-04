# frozen_string_literal: true

# AMOUNT_LABELS（金額ラベル辞書 6件: 設計書 1.6）。
# kind: adopt=採用対象 / exclude=除外対象。priority が大きいほど採用優先（合計>税込合計>お買上げ計）。
class CreateAmountLabels < ActiveRecord::Migration[7.2]
  def change
    create_table :amount_labels do |t|
      t.string :label, null: false
      t.string :kind, null: false # "adopt" or "exclude"
      t.integer :priority, null: false, default: 0
    end
    add_index :amount_labels, :label, unique: true
  end
end
