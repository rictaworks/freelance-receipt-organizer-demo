# frozen_string_literal: true

# REPORTS（設計書 2 ER図）。session_id をオーナーキーとして強制フィルタ（F6）。
class CreateReports < ActiveRecord::Migration[7.2]
  def change
    create_table :reports do |t|
      t.string  :session_id, null: false
      t.integer :target_year, null: false
      # pdf_path: storage/reports/<session_id>/<id>.pdf。
      # F7 日次リセット(JST03:00)で storage/reports 配下は全削除される（親担当）。
      # 実体が消えている場合は 410 REPORT_EXPIRED を返す。
      t.string  :pdf_path, null: false
      t.datetime :generated_at, null: false
    end
    add_index :reports, :session_id
  end
end
