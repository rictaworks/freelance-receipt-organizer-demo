# frozen_string_literal: true

# 環境判定（ENV/DEVELOPMENT.md）。開発は「認証済み」に自動分岐し、本番は Google ログイン前提。
# フォールバックで暗黙に本番扱いにしない（判定は明示的に行う）。
module EnvironmentPolicy
  module_function

  # APP_ENV が development のとき開発環境と判定する。
  def development?
    ENV.fetch("APP_ENV", "development") == "development"
  end

  def production?
    ENV["APP_ENV"] == "production"
  end

  # 開発環境かつ DEV_AUTO_LOGIN=true のとき、認証をバイパスして「認証済み」に固定する。
  def auto_login?
    development? && ENV.fetch("DEV_AUTO_LOGIN", "true") == "true"
  end
end
