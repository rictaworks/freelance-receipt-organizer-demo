#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""収支内訳書（白色申告）風 帳票 PDF 生成スクリプト（F5）。

Rails の ReportGenerator から呼び出される。標準入力に集計サマリ JSON を受け取り、
argv[1] のパスへ PDF を出力する。ReportLab 同梱の CID フォント
(HeiseiKakuGo-W5) を用いるため外部フォントファイルを必要としない。

フォールバック禁止: 例外は握りつぶさず stderr に出力し exit(1) する。
"""
import json
import sys


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("出力パスが指定されていません。\n")
        return 1
    out_path = sys.argv[1]

    payload = json.load(sys.stdin)

    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import mm
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.cidfonts import UnicodeCIDFont
    from reportlab.pdfgen import canvas

    font_name = "HeiseiKakuGo-W5"
    pdfmetrics.registerFont(UnicodeCIDFont(font_name))

    c = canvas.Canvas(out_path, pagesize=A4)
    width, height = A4

    y = height - 25 * mm

    def line(text, size=11, dy=7 * mm, x=20 * mm):
        nonlocal y
        c.setFont(font_name, size)
        c.drawString(x, y, text)
        y -= dy

    line(payload.get("title", ""), size=16, dy=10 * mm)
    line("対象年: {} 年".format(payload.get("target_year", "")), size=12)
    line("{}: {}".format(payload.get("name_label", "氏名"), payload.get("name_placeholder", "")), size=11)
    line("{}: {}".format(payload.get("address_label", "住所"), payload.get("address_placeholder", "")), size=11)
    line("{}: {}".format(payload.get("sales_label", "売上"), ""), size=11)

    y -= 3 * mm
    line(payload.get("expense_label", "経費"), size=13, dy=8 * mm)

    for row in payload.get("expenses", []):
        name = row.get("category_name", "")
        total = row.get("total_yen", 0)
        line("　{}　　{:,} 円".format(name, total), size=11, dy=6 * mm)

    y -= 2 * mm
    line("{}: {:,} 円".format(payload.get("grand_total_label", "経費合計"),
                              payload.get("grand_total_yen", 0)), size=13, dy=10 * mm)

    # 注記（必ず出力する: F5 / 免責）。
    c.setFont(font_name, 10)
    c.drawString(20 * mm, 20 * mm, payload.get("notice", ""))

    c.showPage()
    c.save()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001 フォールバック禁止のため明示的に失敗させる
        sys.stderr.write("PDF生成に失敗しました: {}: {}\n".format(type(exc).__name__, exc))
        sys.exit(1)
