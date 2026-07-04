# frozen_string_literal: true

# 勘定科目マスタ（設計書 5 クラス図 AccountCategory / 1.6 マスタ 12件）。
class AccountCategory < ApplicationRecord
  # マスタ期待件数（categories.md: 12件未満は MASTER_NOT_SEEDED）。
  EXPECTED_COUNT = 12

  has_many :classify_rules, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # SPEC/api/categories.md の並び順（id 昇順）で全件返す。
  def self.ordered
    order(:id)
  end
end
