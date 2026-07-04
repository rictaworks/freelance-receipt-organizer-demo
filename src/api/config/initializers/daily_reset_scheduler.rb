# frozen_string_literal: true

# F7 日次リセットのアプリ内スケジューラ（JST 03:00）。
#
# 【背景（CLAUDE.md / インフラ制約）】
# 本番は Railway 上の api コンテナ + SQLite で稼働する。SQLite の DB ファイルは
# api コンテナのファイルシステムに存在し、別サービス（Railway Cron）からは共有できない
# （ボリュームは単一アタッチのため、別サービスは空の ephemeral SQLite を掴む）。
# よって日次リセットは外部 Cron ではなく、api プロセス内のスケジューラで実行する。
#
# 【動作条件】
# - `./bin/rails server` 起動時のみ（rake タスク db:prepare 等では起動しない）
# - 本番（APP_ENV=production → Rails.env.production?）のみ
# DailyResetService は DELETE/ ゴミ箱への「移動」のみ行い物理削除しない（安全ルール準拠）。
if defined?(Rails::Server) && Rails.env.production?
  Rails.application.config.after_initialize do
    Thread.new do
      Rails.logger.info("[daily_reset_scheduler] started")
      loop do
        begin
          now = Time.now.getlocal("+09:00")
          next_run = Time.new(now.year, now.month, now.day, 3, 0, 0, "+09:00")
          next_run += 86_400 if next_run <= now
          sleep((next_run - now).to_f)

          DailyResetService.new.call
          Rails.logger.info("[daily_reset_scheduler] done at #{Time.now.getlocal('+09:00')}")
        rescue => e
          Rails.logger.error("[daily_reset_scheduler] #{e.class}: #{e.message}")
          sleep 60 # 連続失敗時のビジーループを避ける
        end
      end
    end
  end
end
