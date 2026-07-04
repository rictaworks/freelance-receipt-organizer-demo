# frozen_string_literal: true

# F7 日次リセット（JST 03:00）を起動する rake タスク。
# 運用: プラットフォームのスケジューラ（Railway Cron / cron 等）で JST 03:00 に
#   `bin/rails demo:daily_reset` を実行する（TZ=Asia/Tokyo）。
# 例（crontab, JSTサーバ）: 0 3 * * * cd /path/to/src/api && bin/rails demo:daily_reset
namespace :demo do
  desc "F7 日次リセット: オーナーデータを白紙化し、storage(画像/PDF)を DELETE/ ゴミ箱へ移動する"
  task daily_reset: :environment do
    result = DailyResetService.new.call
    Rails.logger.info(
      "[demo:daily_reset] trace_id=#{result.trace_id} " \
      "cleared=#{result.cleared_counts} moved=#{result.moved_targets} trash=#{result.trash_path}"
    )
    puts "日次リセット完了: #{result.cleared_counts}（退避先: #{result.trash_path}）"
  end
end
