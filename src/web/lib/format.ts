// 表示整形ユーティリティ。金額は整数円、時刻は JST 前提（CLAUDE.md）。

export function formatYen(value: number | null, locale: string): string {
  if (value === null || value === undefined) return "-";
  // 通貨記号は付けず桁区切りのみ（単位はラベルで別途表示）。
  return new Intl.NumberFormat(locale).format(value);
}

export function formatConfidence(value: number | null): string {
  if (value === null || value === undefined) return "-";
  return `${Math.round(value * 100)}%`;
}

// ISO 日時を JST の日付＋時刻へ整形。
export function formatDateTimeJst(iso: string | null | undefined): string {
  if (!iso) return "-";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "-";
  return new Intl.DateTimeFormat("ja-JP", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(d);
}

// YYYY-MM-DD の簡易妥当性チェック（クライアント側 Fail Fast 用）。
export function isValidDateString(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const d = new Date(`${value}T00:00:00+09:00`);
  return !Number.isNaN(d.getTime());
}
