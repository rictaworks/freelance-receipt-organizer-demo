# frozen_string_literal: true

# 金額ラベル辞書（設計書 1.6 マスタ 6件）。F2 金額抽出のラベル優先辞書。
class AmountLabel < ApplicationRecord
  KIND_ADOPT = "adopt"
  KIND_EXCLUDE = "exclude"

  validates :label, presence: true, uniqueness: true
  validates :kind, inclusion: { in: [KIND_ADOPT, KIND_EXCLUDE] }

  # 採用ラベルを優先度の高い順（合計>税込合計>お買上げ計）に返す。
  def self.adopt_labels
    where(kind: KIND_ADOPT).order(priority: :desc)
  end

  # 除外ラベル（小計/お預り/お釣り）。
  def self.exclude_labels
    where(kind: KIND_EXCLUDE)
  end
end
