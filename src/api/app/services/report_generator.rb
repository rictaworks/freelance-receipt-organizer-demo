# frozen_string_literal: true

require "open3"
require "fileutils"

# 帳票生成（設計書 5 クラス図 ReportGenerator / F5）。
# 集計（Aggregator）を元に ReportLab（Python）で PDF を生成し、プレビュー HTML を返す。
# PDF 実体は storage/reports/<session_id>/<report_id>.pdf に保存する
# （F7 日次リセット JST03:00 で削除対象。実体喪失時は 410 REPORT_EXPIRED）。
class ReportGenerator
  PDF_SCRIPT = Rails.root.join("lib", "report_pdf.py").freeze

  Result = Struct.new(:report, :summary, :preview_html, keyword_init: true)

  # session（Session）と対象年から帳票を生成する。
  def generate(session:, year:)
    summary = Aggregator.new.aggregate(session_id: session.session_id, year: year)

    report = Report.create!(
      session_id: session.session_id,
      target_year: year,
      pdf_path: pending_path(session.session_id),
      generated_at: Time.current
    )

    pdf_path = build_pdf_path(session.session_id, report.id)
    generate_pdf!(summary, pdf_path)
    report.update!(pdf_path: pdf_path.to_s)

    Result.new(report: report, summary: summary, preview_html: render_html(summary))
  end

  private

  # create! の presence 検証を満たすための一時値（直後に実 ID パスへ更新する）。
  def pending_path(session_id)
    reports_dir(session_id).join("pending.pdf").to_s
  end

  def reports_dir(session_id)
    Rails.root.join("storage", "reports", session_id)
  end

  def build_pdf_path(session_id, report_id)
    reports_dir(session_id).join("#{report_id}.pdf")
  end

  # Python(ReportLab) を呼び出して PDF を生成する。失敗はフォールバックせず明示エラー。
  def generate_pdf!(summary, pdf_path)
    FileUtils.mkdir_p(File.dirname(pdf_path))
    payload = JSON.generate(pdf_payload(summary))

    stdout, stderr, status = Open3.capture3("python3", PDF_SCRIPT.to_s, pdf_path.to_s, stdin_data: payload)

    unless status.success? && File.exist?(pdf_path)
      raise ApiError.new(
        "PDF_GENERATION_FAILED",
        details: [{ "stage" => "reportlab", "stderr" => stderr.to_s.byteslice(0, 500) }],
        cause_message: stdout.to_s
      )
    end
  end

  # Python スクリプトへ渡す描画データ（文字列は config/report.yml から取得）。
  def pdf_payload(summary)
    cfg = AppConfig.report
    {
      "title" => cfg.fetch("title"),
      "notice" => cfg.fetch("notice"),
      "target_year" => summary["target_year"],
      "name_label" => cfg.fetch("name_label"),
      "address_label" => cfg.fetch("address_label"),
      "name_placeholder" => cfg.fetch("name_placeholder"),
      "address_placeholder" => cfg.fetch("address_placeholder"),
      "sales_label" => cfg.fetch("sales_label"),
      "expense_label" => cfg.fetch("expense_label"),
      "grand_total_label" => cfg.fetch("grand_total_label"),
      "grand_total_yen" => summary["grand_total_yen"],
      "expenses" => summary["category_yearly_totals"]
    }
  end

  # プレビュー用 HTML。注記を必ず含める（F5）。
  def render_html(summary)
    cfg = AppConfig.report
    rows = summary["category_yearly_totals"].map do |row|
      format(
        '<tr><td>%<name>s</td><td class="amount">%<total>s 円</td></tr>',
        name: ERB::Util.html_escape(row["category_name"]),
        total: format_yen(row["total_yen"])
      )
    end.join

    <<~HTML.strip
      <section class="report-preview">
        <h1>#{ERB::Util.html_escape(cfg.fetch('title'))}</h1>
        <p class="target-year">対象年: #{summary['target_year']} 年</p>
        <p class="person">#{ERB::Util.html_escape(cfg.fetch('name_label'))}: #{ERB::Util.html_escape(cfg.fetch('name_placeholder'))}</p>
        <p class="person">#{ERB::Util.html_escape(cfg.fetch('address_label'))}: #{ERB::Util.html_escape(cfg.fetch('address_placeholder'))}</p>
        <p class="sales">#{ERB::Util.html_escape(cfg.fetch('sales_label'))}: </p>
        <h2>#{ERB::Util.html_escape(cfg.fetch('expense_label'))}</h2>
        <table class="expenses"><tbody>#{rows}</tbody></table>
        <p class="grand-total">#{ERB::Util.html_escape(cfg.fetch('grand_total_label'))}: #{format_yen(summary['grand_total_yen'])} 円</p>
        <p class="notice">#{ERB::Util.html_escape(cfg.fetch('notice'))}</p>
      </section>
    HTML
  end

  def format_yen(value)
    value.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
