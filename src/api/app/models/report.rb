# frozen_string_literal: true

# 帳票（設計書 5 クラス図 Report）。session_id で強制フィルタ（F6）。
class Report < ApplicationRecord
  belongs_to :session, foreign_key: "session_id", primary_key: "session_id", inverse_of: :reports

  validates :session_id, presence: true
  validates :target_year, numericality: { only_integer: true }
  validates :pdf_path, presence: true

  # PDF 実体が存在するか（F7 日次リセットで消えていれば false → 410 REPORT_EXPIRED）。
  def pdf_available?
    pdf_path.present? && File.exist?(pdf_path)
  end
end
