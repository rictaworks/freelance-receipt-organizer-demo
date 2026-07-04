// API 契約（SPEC/api/*）に対応する型定義。サーバのレスポンス形状をそのまま表現する。

export interface SessionInfo {
  session_id: string;
  created_at: string;
  last_accessed_at: string;
  is_new: boolean;
}

export interface Category {
  id: number;
  code: string;
  name: string;
}

export interface CategoriesResponse {
  categories: Category[];
  count: number;
}

// 警告コード（SPEC/api/receipts.md）
export type WarningCode =
  | "duplicate"
  | "non_positive_amount"
  | "uncategorized"
  | "low_confidence_manual_input";

export interface ReceiptWarning {
  code: WarningCode;
  message: string;
}

export interface Receipt {
  id: number;
  issued_on: string | null;
  amount_yen: number | null;
  store_name: string | null;
  category_id: number | null;
  category_name: string | null;
  ocr_confidence: number | null;
  image_path?: string;
  manually_edited: boolean;
  created_at?: string;
}

export interface UploadResponse {
  receipt: Receipt;
  warnings: ReceiptWarning[];
}

// ハニーポット破棄時のレスポンス（正常時と区別できない体裁）
export interface HoneypotAcceptedResponse {
  status: "accepted";
}

export interface ReceiptsListResponse {
  receipts: Receipt[];
  count: number;
}

export interface ReceiptPatchResponse {
  receipt: Receipt;
}

export interface ReceiptPatchInput {
  issued_on?: string | null;
  amount_yen?: number | null;
  store_name?: string | null;
  category_id?: number | null;
}

// 集計（SPEC/api/aggregations.md）
export interface AggregationCategoryTotal {
  category_id: number | null;
  category_name: string;
  total_yen: number;
}

export interface AggregationMonth {
  month: number;
  categories: AggregationCategoryTotal[];
  month_total_yen: number;
}

export interface AggregationResponse {
  target_year: number;
  months: AggregationMonth[];
  category_yearly_totals: AggregationCategoryTotal[];
  grand_total_yen: number;
}

// 帳票（SPEC/api/reports.md）
export interface Report {
  id: number;
  target_year: number;
  generated_at: string;
  pdf_url: string;
  grand_total_yen: number;
  notice: string;
}

export interface ReportResponse {
  report: Report;
  preview_html: string;
}

// エラーレスポンス共通形式（SPEC/api/README.md）
export interface ApiErrorDetail {
  field: string;
  reason: string;
}

export interface ApiErrorBody {
  error: {
    code: string;
    message: string;
    details?: ApiErrorDetail[];
    trace_id: string;
  };
}
