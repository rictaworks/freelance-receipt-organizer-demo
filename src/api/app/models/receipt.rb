# frozen_string_literal: true

# 領収書（設計書 5 クラス図 Receipt）。session_id で強制フィルタ（F6）。
class Receipt < ApplicationRecord
  belongs_to :session, foreign_key: "session_id", primary_key: "session_id", inverse_of: :receipts
  belongs_to :account_category, foreign_key: "category_id", optional: true, inverse_of: false

  validates :session_id, presence: true

  # 勘定科目を割り当てる（設計書 5: assignCategory(c)）。
  def assign_category(category_id)
    self.category_id = category_id
  end

  # 重複判定（設計書 5: isDuplicateOf(r)）。日付＋金額＋店名の完全一致（F2）。
  def duplicate_of?(other)
    issued_on == other.issued_on &&
      amount_yen == other.amount_yen &&
      store_name == other.store_name
  end

  # 同一セッション内に日付＋金額＋店名が完全一致するレコードが存在するか。
  def self.duplicate_exists?(session_id:, issued_on:, amount_yen:, store_name:, excluding_id: nil)
    scope = where(session_id: session_id, issued_on: issued_on, amount_yen: amount_yen, store_name: store_name)
    scope = scope.where.not(id: excluding_id) if excluding_id
    scope.exists?
  end
end
