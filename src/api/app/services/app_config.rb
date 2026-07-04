# frozen_string_literal: true

# 文字列リテラル（メッセージ等）を config/*.yml から読み込むローダ（CLAUDE.md §4）。
# ハードコードを避け、メッセージはすべて設定ファイルに分離する。
module AppConfig
  module_function

  # config/<name>.yml を読み込む。存在しない/破損時は握りつぶさず例外にする（フォールバック禁止）。
  def load(name)
    @cache ||= {}
    @cache[name] ||= begin
      path = Rails.root.join("config", "#{name}.yml")
      raise "設定ファイルが見つかりません: #{path}" unless File.exist?(path)

      YAML.safe_load_file(path) || raise("設定ファイルが空です: #{path}")
    end
  end

  def api_errors
    load("api_errors")
  end

  def warnings
    load("warnings")
  end

  def report
    load("report")
  end

  def ocr
    load("ocr")
  end

  def reset
    load("reset")
  end

  # テスト・リロード用にキャッシュを破棄する。
  def reset!
    @cache = {}
  end
end
