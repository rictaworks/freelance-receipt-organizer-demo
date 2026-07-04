require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Api
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # 時刻はすべて JST（CLAUDE.md）。DB 保存も含め Asia/Tokyo で扱う。
    config.time_zone = "Asia/Tokyo"
    config.active_record.default_timezone = :local

    # API モードでは Cookie ミドルウェアが外れているため明示的に復帰させる。
    # セッションID（F6）を HttpOnly Cookie で受け渡すために必須。
    config.middleware.use ActionDispatch::Cookies

    # フロント（Next.js）からの Cookie 付きクロスオリジン通信を許可する。
    # 許可オリジンは FRONTEND_ORIGIN（カンマ区切りで複数可。例: 本番ドメイン + プレビュー URL）。
    _frontend_origins = ENV.fetch("FRONTEND_ORIGIN", "http://localhost:3000")
                           .split(",").map(&:strip).reject(&:empty?)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins(*_frontend_origins)
        resource "*",
                 headers: :any,
                 methods: %i[get post patch put delete options head],
                 credentials: true
      end
    end
  end
end
