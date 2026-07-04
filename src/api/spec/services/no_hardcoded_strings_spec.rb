# frozen_string_literal: true

require "rails_helper"

# ハードコード検出テスト（CLAUDE.md §4）。
# ユーザー向けメッセージ（エラー/警告）と分類キーワードが
# app コード内にリテラルで埋め込まれていないこと（config/DB に分離）を検証する。
RSpec.describe "文字列リテラルの分離（ハードコード検出）" do
  let(:app_sources) do
    Rails.root.glob("app/**/*.rb").map { |path| [path, File.read(path)] }
  end

  it "API エラーメッセージが app コードに直書きされていない（config/api_errors.yml に分離）" do
    messages = AppConfig.api_errors.values.map { |v| v.fetch("message") }
    offenders = app_sources.select do |_path, content|
      messages.any? { |message| content.include?(message) }
    end
    expect(offenders.map(&:first)).to be_empty
  end

  it "警告メッセージが app コードに直書きされていない（config/warnings.yml に分離）" do
    messages = AppConfig.warnings.values
    offenders = app_sources.select do |_path, content|
      messages.any? { |message| content.include?(message) }
    end
    expect(offenders.map(&:first)).to be_empty
  end

  it "分類キーワードが app コードに直書きされていない（DB seed に分離）" do
    keywords = ClassifyRule.pluck(:keyword)
    offenders = app_sources.select do |_path, content|
      keywords.any? { |keyword| content.include?(%("#{keyword}")) }
    end
    expect(offenders.map(&:first)).to be_empty
  end
end
