# frozen_string_literal: true

# RECEIPTS（設計書 2 ER図）。session_id をオーナーキーとして全クエリで強制フィルタ（F6）。
class CreateReceipts < ActiveRecord::Migration[7.2]
  def change
    create_table :receipts do |t|
      t.string  :session_id, null: false            # オーナーキー（SESSIONS.session_id）
      t.integer :category_id                         # null = 未分類（F3）
      t.date    :issued_on                           # 抽出/手動入力（null 可）
      t.integer :amount_yen                          # 整数円。手動確定時は 0 以下も許容（F2）
      t.string  :store_name
      # image_path: 原本画像の保存先。storage/uploads/<session_id>/<id>.<ext>。
      # F7 日次リセット(JST03:00)で storage/uploads 配下は全削除される（親担当）。
      t.string  :image_path
      t.float   :ocr_confidence
      t.boolean :manually_edited, null: false, default: false
      t.datetime :created_at, null: false
    end
    add_index :receipts, :session_id
    add_index :receipts, %i[session_id category_id]
  end
end
