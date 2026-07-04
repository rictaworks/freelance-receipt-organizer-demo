# frozen_string_literal: true

# 分類キーワードルール（設計書 5 クラス図 ClassifyRule / 1.6 マスタ 36件）。
class ClassifyRule < ApplicationRecord
  belongs_to :account_category

  validates :keyword, presence: true
  validates :priority, numericality: { only_integer: true }

  # 対象テキストにキーワードが含まれるか（設計書 5: matches(text)）。
  def matches?(text)
    return false if text.nil?

    text.include?(keyword)
  end
end
