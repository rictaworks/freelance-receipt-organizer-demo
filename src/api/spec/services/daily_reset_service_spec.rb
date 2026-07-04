# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

# F7 日次リセット（設計書 1.5 F7）。
# 観点: オーナーデータの白紙化 / マスタ保持 / storage の物理削除禁止（DELETE/ へ移動）。
RSpec.describe DailyResetService do
  around do |example|
    Dir.mktmpdir do |storage|
      Dir.mktmpdir do |trash|
        @storage_root = Pathname(storage)
        @trash_root   = Pathname(trash)
        example.run
      end
    end
  end

  let(:service) do
    described_class.new(storage_root: @storage_root, trash_root: @trash_root)
  end

  # 対象 storage サブディレクトリにダミー画像/PDF を作る。
  def seed_storage_file(target, rel_path)
    path = @storage_root.join(target, rel_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, "dummy")
    path
  end

  def seed_owner_records
    session = Session.create!(session_id: SecureRandom.uuid, last_accessed_at: Time.current)
    Receipt.create!(session_id: session.session_id, amount_yen: 1_480, store_name: "テスト商店",
                    issued_on: Date.new(2026, 6, 30))
    Report.create!(session_id: session.session_id, target_year: 2026,
                   pdf_path: "storage/reports/#{session.session_id}/1.pdf",
                   generated_at: Time.current)
    session
  end

  it "オーナーテーブル（sessions/receipts/reports）を白紙化する" do
    seed_owner_records
    expect { service.call }
      .to change { [Session.count, Receipt.count, Report.count] }
      .to([0, 0, 0])
  end

  it "マスタ（勘定科目/分類ルール/金額ラベル）は保持する" do
    seed_owner_records
    expect { service.call }
      .not_to change { [AccountCategory.count, ClassifyRule.count, AmountLabel.count] }
  end

  it "storage 配下のファイルを物理削除せず DELETE/ ゴミ箱へ移動する" do
    img = seed_storage_file("uploads", "sess-a/1.png")
    pdf = seed_storage_file("reports", "sess-a/1.pdf")

    result = service.call

    # 元の場所からは無くなる（が、退避先に実体が残っている＝削除ではなく移動）。
    expect(img.exist?).to be(false)
    expect(pdf.exist?).to be(false)
    trash = Pathname(result.trash_path)
    expect(trash.join("uploads", "sess-a", "1.png").read).to eq("dummy")
    expect(trash.join("reports", "sess-a", "1.pdf").read).to eq("dummy")
  end

  it "移動後も storage の対象ディレクトリは空で再作成される（後続アップロードの保存先を確保）" do
    seed_storage_file("uploads", "sess-a/1.png")
    service.call
    uploads = @storage_root.join("uploads")
    expect(uploads.directory?).to be(true)
    expect(uploads.children).to be_empty
  end

  it "実行結果に trace_id とクリア件数を含む（デバッグ追跡可能）" do
    seed_owner_records
    result = service.call
    expect(result.trace_id).to match(/\A[0-9a-f-]{36}\z/)
    expect(result.cleared_counts).to include("sessions" => 1, "receipts" => 1, "reports" => 1)
  end
end
