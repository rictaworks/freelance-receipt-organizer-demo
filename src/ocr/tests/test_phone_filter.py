"""電話番号スクラブの単体テスト（個人情報保護・設計書 1.4）。

電話番号は除去され件数がカウントされること、金額（¥1,480 等）は保持されることを
文字列処理として検証する（日本語フォント非依存）。
"""
from app.phone_filter import PhoneNumberScrubber


def test_removes_hyphenated_landline():
    r = PhoneNumberScrubber().scrub("お問合せ 03-1234-5678 まで")
    assert "03-1234-5678" not in r.text
    assert r.removed_count == 1


def test_removes_mobile_number():
    r = PhoneNumberScrubber().scrub("担当 090-1234-5678")
    assert "090-1234-5678" not in r.text
    assert r.removed_count == 1


def test_removes_freedial_number():
    r = PhoneNumberScrubber().scrub("フリーダイヤル 0120-000-000")
    assert "0120-000-000" not in r.text
    assert r.removed_count == 1


def test_removes_parenthesized_area_code():
    r = PhoneNumberScrubber().scrub("TEL (03)1234-5678")
    assert "1234-5678" not in r.text
    assert r.removed_count == 1


def test_removes_space_separated_number():
    r = PhoneNumberScrubber().scrub("電話 03 1234 5678")
    assert r.removed_count == 1


def test_removes_contiguous_digits():
    r = PhoneNumberScrubber().scrub("代表 0312345678 内線")
    assert "0312345678" not in r.text
    assert r.removed_count == 1


def test_keeps_amount_with_yen_and_comma():
    r = PhoneNumberScrubber().scrub("合計 ¥1,480")
    assert "¥1,480" in r.text
    assert r.removed_count == 0


def test_keeps_amount_with_yen_kanji():
    r = PhoneNumberScrubber().scrub("小計 1,480円")
    assert "1,480円" in r.text
    assert r.removed_count == 0


def test_keeps_western_date():
    r = PhoneNumberScrubber().scrub("2026-06-30 発行")
    assert "2026-06-30" in r.text
    assert r.removed_count == 0


def test_phone_removed_but_amount_preserved_together():
    text = "タクシー株式会社\nTEL 03-1234-5678\n合計 ¥1,480"
    r = PhoneNumberScrubber().scrub(text)
    assert "03-1234-5678" not in r.text
    assert "¥1,480" in r.text
    assert r.removed_count == 1
