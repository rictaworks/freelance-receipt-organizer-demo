// API クライアント層（薄いラッパ）。
// - すべての呼び出しに credentials:"include" を付与し、HttpOnly の session_id Cookie を送受信する。
// - エラーは握りつぶさず ApiError として送出する（CLAUDE.md §4 フォールバック禁止）。
// - 文言はここに埋め込まない。表示側で翻訳リソースの errors.<code> を引く。

import type {
  AggregationResponse,
  ApiErrorBody,
  CategoriesResponse,
  ReceiptPatchInput,
  ReceiptPatchResponse,
  ReceiptsListResponse,
  ReportResponse,
  SessionInfo,
  UploadResponse,
} from "./types";

const DEFAULT_API_BASE = "http://localhost:4000";

export function getApiBase(): string {
  const base = process.env.NEXT_PUBLIC_API_BASE;
  return base && base.length > 0 ? base : DEFAULT_API_BASE;
}

// サーバの {error:{code,message,trace_id}} を保持する例外。
export class ApiError extends Error {
  readonly code: string;
  readonly status: number;
  readonly traceId: string | null;
  readonly details: { field: string; reason: string }[] | null;

  constructor(params: {
    code: string;
    message: string;
    status: number;
    traceId: string | null;
    details?: { field: string; reason: string }[] | null;
  }) {
    super(params.message);
    this.name = "ApiError";
    this.code = params.code;
    this.status = params.status;
    this.traceId = params.traceId;
    this.details = params.details ?? null;
  }
}

// ネットワーク到達不能・CORS 等の通信レベル失敗。
export class NetworkError extends Error {
  readonly cause: unknown;
  constructor(cause: unknown) {
    super("NETWORK_ERROR");
    this.name = "NetworkError";
    this.cause = cause;
  }
}

async function request<T>(
  path: string,
  init: RequestInit,
): Promise<T> {
  const url = `${getApiBase()}${path}`;
  let res: Response;
  try {
    res = await fetch(url, {
      ...init,
      credentials: "include",
    });
  } catch (cause) {
    // フォールバックせず通信失敗を明示する。
    throw new NetworkError(cause);
  }

  if (res.status === 204) {
    return undefined as unknown as T;
  }

  const contentType = res.headers.get("content-type") ?? "";
  const isJson = contentType.includes("application/json");

  if (!res.ok) {
    if (isJson) {
      const body = (await res.json()) as ApiErrorBody;
      if (body && body.error) {
        throw new ApiError({
          code: body.error.code,
          message: body.error.message,
          status: res.status,
          traceId: body.error.trace_id ?? null,
          details: body.error.details ?? null,
        });
      }
    }
    // JSON でないエラーも握りつぶさず、ステータスから合成する。
    throw new ApiError({
      code: `HTTP_${res.status}`,
      message: res.statusText || `HTTP ${res.status}`,
      status: res.status,
      traceId: null,
    });
  }

  if (!isJson) {
    return undefined as unknown as T;
  }
  return (await res.json()) as T;
}

// --- 各エンドポイント -------------------------------------------------------

export function getSession(): Promise<SessionInfo> {
  return request<SessionInfo>("/session", { method: "GET" });
}

export function getCategories(): Promise<CategoriesResponse> {
  return request<CategoriesResponse>("/categories", { method: "GET" });
}

// アップロード。honeypot（website）は通常空。値があってもフォームどおり送る（判定はサーバ側）。
export function uploadReceipt(
  file: File,
  honeypot: string,
): Promise<UploadResponse> {
  const form = new FormData();
  form.append("file", file);
  form.append("website", honeypot);
  return request<UploadResponse>("/receipts", {
    method: "POST",
    body: form,
  });
}

export function listReceipts(params?: {
  year?: number;
  categoryId?: number | null;
}): Promise<ReceiptsListResponse> {
  const query = new URLSearchParams();
  if (params?.year !== undefined) query.set("year", String(params.year));
  if (params?.categoryId !== undefined && params.categoryId !== null) {
    query.set("category_id", String(params.categoryId));
  }
  const qs = query.toString();
  return request<ReceiptsListResponse>(`/receipts${qs ? `?${qs}` : ""}`, {
    method: "GET",
  });
}

export function patchReceipt(
  id: number,
  input: ReceiptPatchInput,
): Promise<ReceiptPatchResponse> {
  return request<ReceiptPatchResponse>(`/receipts/${id}`, {
    method: "PATCH",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(input),
  });
}

export function getAggregations(year?: number): Promise<AggregationResponse> {
  const qs = year !== undefined ? `?year=${year}` : "";
  return request<AggregationResponse>(`/aggregations${qs}`, { method: "GET" });
}

export function createReport(targetYear?: number): Promise<ReportResponse> {
  return request<ReportResponse>("/reports", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(
      targetYear !== undefined ? { target_year: targetYear } : {},
    ),
  });
}

// PDF は同一オリジンでない場合 Cookie 送信のため直接遷移させる。絶対 URL を生成する。
export function reportPdfUrl(reportId: number): string {
  return `${getApiBase()}/reports/${reportId}.pdf`;
}
