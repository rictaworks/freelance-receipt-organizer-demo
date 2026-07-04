# frozen_string_literal: true

# セッション（設計書 5 クラス図 Session）。UUID v4 を主キーとするオーナーキー（F6）。
class Session < ApplicationRecord
  self.primary_key = "session_id"

  has_many :receipts, foreign_key: "session_id", primary_key: "session_id", dependent: :destroy, inverse_of: :session
  has_many :reports,  foreign_key: "session_id", primary_key: "session_id", dependent: :destroy, inverse_of: :session

  validates :session_id, presence: true, uniqueness: true

  # 最終アクセス時刻を更新する（設計書 5: touch()）。
  def touch_access!
    update!(last_accessed_at: Time.current)
  end
end
