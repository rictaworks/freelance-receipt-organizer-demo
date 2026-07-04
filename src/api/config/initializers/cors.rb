# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors
#
# フロント（Vercel）は API（Railway）と別オリジンのため、CORS を明示許可する。
# 許可オリジンは環境変数 WEB_ORIGIN（カンマ区切りで複数可）で与える。
# 未設定時は開発フロント（http://localhost:3000）のみ許可する（ワイルドカード + credentials は不可のため）。
# Cookie（HttpOnly セッション）を送受信するため credentials: true を必須とする。

_allowed_origins = ENV.fetch("WEB_ORIGIN", "http://localhost:3000")
                      .split(",").map(&:strip).reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*_allowed_origins)

    resource "*",
      headers: :any,
      methods: [:get, :post, :patch, :delete, :options, :head],
      credentials: true
  end
end
