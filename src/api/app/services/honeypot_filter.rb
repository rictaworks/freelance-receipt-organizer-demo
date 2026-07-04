# frozen_string_literal: true

# ハニーポット（設計書 5 クラス図 HoneypotFilter / F8）。
# 不可視フィールド website に値があれば Bot とみなし破棄対象と判定する。
module HoneypotFilter
  # 不可視フィールド名。フロントの非表示 input と一致させる。
  FIELD_NAME = "website"

  module_function

  # 破棄すべきか（値が入っていれば true）。空文字・nil は通常ユーザー。
  def should_discard?(params)
    value = params[FIELD_NAME]
    value.present?
  end
end
