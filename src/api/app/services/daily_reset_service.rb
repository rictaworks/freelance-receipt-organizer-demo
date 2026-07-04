# frozen_string_literal: true

require "fileutils"

# F7 日次リセット（JST 03:00）。設計書 1.5 F7 / DFD P6。
# セッション配下のオーナーデータ（sessions/receipts/reports）を白紙化し、
# アップロード画像・生成PDF をリセットする。リセット直後のアクセスは新規セッションと同等に動作する。
#
# 【安全ルールとの整合（CLAUDE.md §0 最優先）】
# - ファイル/ディレクトリは物理削除（rm 等）しない。storage 配下は DELETE/ ゴミ箱へ「移動」する。
# - DB のオーナーテーブルはアプリ層でクリアする。マスタ（勘定科目/分類ルール/金額ラベル）は保持する。
# - 本処理はスケジューラ（Railway Cron 等）が JST 03:00 に起動する rake タスク（demo:daily_reset）から
#   呼ばれる想定であり、Claude が自動で削除判断を行うものではない（運用者が明示的にスケジュールする）。
#
# フォールバック禁止（CLAUDE.md §4）: 失敗は握りつぶさず例外を送出し、trace_id で追跡可能にする。
class DailyResetService
  # 実行結果（構造化ログ・呼び出し元での確認用）。
  Result = Struct.new(:trace_id, :cleared_counts, :moved_targets, :trash_path, keyword_init: true)

  # マスタは保持し、オーナーテーブルのみを外部キー安全順（子→親）でクリアする。
  OWNER_MODELS = [Report, Receipt, Session].freeze

  # storage_root / trash_root はテスト時に一時ディレクトリを注入できるようにする。
  # clock は JST 時刻源（既定 Time。ActiveSupport の time_zone=Asia/Tokyo に従う）。
  def initialize(storage_root: default_storage_root, trash_root: default_trash_root, clock: Time)
    @storage_root = Pathname(storage_root)
    @trash_root   = Pathname(trash_root)
    @clock        = clock
    @config       = AppConfig.reset
  end

  def call
    trace_id = SecureRandom.uuid
    log(@config.dig("log", "started"), trace_id: trace_id)

    trash_path    = prepare_trash_dir
    moved_targets = move_storage_to_trash(trash_path)
    cleared       = clear_owner_tables

    result = Result.new(
      trace_id: trace_id,
      cleared_counts: cleared,
      moved_targets: moved_targets,
      trash_path: trash_path.to_s
    )
    log(@config.dig("log", "completed"), trace_id: trace_id,
        cleared: cleared, moved: moved_targets, trash: trash_path.to_s)
    result
  end

  private

  # オーナーテーブルを子→親の順でクリアし、テーブルごとの件数を返す。マスタは対象外。
  def clear_owner_tables
    OWNER_MODELS.each_with_object({}) do |model, acc|
      acc[model.table_name] = model.delete_all
    end
  end

  # storage 配下の対象ディレクトリを DELETE/ ゴミ箱へ「移動」する（物理削除しない）。
  # 移動後は空ディレクトリを再作成し、後続アップロードの保存先を確保する。
  def move_storage_to_trash(trash_path)
    Array(@config.fetch("storage_targets")).filter_map do |name|
      src = @storage_root.join(name)
      next unless src.directory? && src.children.any?

      dest = trash_path.join(name)
      FileUtils.mkdir_p(dest.dirname)
      FileUtils.mv(src.to_s, dest.to_s)
      FileUtils.mkdir_p(src.to_s)
      name
    end
  end

  # ゴミ箱の退避先ディレクトリ（DELETE/daily-reset-<JST timestamp>/）を作成する。
  def prepare_trash_dir
    stamp = jst_now.strftime("%Y%m%d-%H%M%S")
    path = @trash_root.join("#{@config.fetch('trash_prefix')}-#{stamp}")
    FileUtils.mkdir_p(path)
    path
  end

  def jst_now
    @clock.respond_to?(:current) ? @clock.current : @clock.now.getlocal("+09:00")
  end

  def default_storage_root
    Rails.root.join("storage")
  end

  # リポジトリ直下の DELETE/ ゴミ箱（Rails.root は src/api のためリポジトリルートへ遡る）。
  # 環境変数 DEMO_TRASH_DIR で上書き可能。
  def default_trash_root
    ENV.fetch("DEMO_TRASH_DIR") { Rails.root.join("..", "..", "DELETE").to_s }
  end

  def log(message, **context)
    Rails.logger.info({ event: "daily_reset", message: message }.merge(context).to_json)
  end
end
