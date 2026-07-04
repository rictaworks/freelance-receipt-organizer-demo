"use client";

// API 例外を独自 UI（トースト）で表示するためのフック。
// フォールバックで握りつぶさず、code/trace_id を保持したまま翻訳文言へ写像する。
import { useCallback } from "react";
import { ApiError, NetworkError } from "./api";
import { useToast } from "@/components/ui/Toast";
import { useI18n } from "@/i18n/I18nProvider";

export function useApiError() {
  const { showToast } = useToast();
  const { t } = useI18n();

  return useCallback(
    (error: unknown) => {
      if (error instanceof NetworkError) {
        showToast({
          type: "error",
          title: t("errors.genericTitle"),
          message: t("errors.network"),
        });
        return;
      }
      if (error instanceof ApiError) {
        // errors.<CODE> があればそれを、無ければサーバの message を使う。
        const localized = t(`errors.${error.code}`);
        const message =
          localized === `errors.${error.code}` ? error.message : localized;
        showToast({
          type: "error",
          title: t("errors.genericTitle"),
          message,
          traceId: error.traceId,
        });
        return;
      }
      // 想定外の例外も無言化しない。
      showToast({
        type: "error",
        title: t("errors.genericTitle"),
        message: t("errors.unknown"),
      });
    },
    [showToast, t],
  );
}
