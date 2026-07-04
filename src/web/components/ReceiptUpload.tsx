"use client";

// 領収書アップロード（UC1）。
// - クライアント側で形式/サイズを事前検証（Fail Fast）。
// - ハニーポット不可視フィールド `website`（F8）を設置。視覚・スクリーンリーダーから隠し、
//   autocomplete=off / tabindex=-1 / aria-hidden。通常ユーザーには到達不能。
// - 成功時は warnings を親へ渡し、確認フローへ誘導する。
import { useCallback, useRef, useState } from "react";
import { Icon } from "./ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";
import { uploadReceipt } from "@/lib/api";
import type { UploadResponse } from "@/lib/types";
import { useApiError } from "@/lib/useApiError";
import { useToast } from "./ui/Toast";

const MAX_BYTES = 10 * 1024 * 1024; // 10MB（F1）
const ACCEPTED = ["image/jpeg", "image/png"];

interface Props {
  onUploaded: (result: UploadResponse) => void;
}

export function ReceiptUpload({ onUploaded }: Props) {
  const { t } = useI18n();
  const { showToast } = useToast();
  const handleError = useApiError();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const honeypotRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const [busy, setBusy] = useState(false);
  const [clientError, setClientError] = useState<string | null>(null);

  const validate = useCallback(
    (candidate: File): string | null => {
      if (!ACCEPTED.includes(candidate.type)) return t("upload.clientWrongType");
      if (candidate.size > MAX_BYTES) return t("upload.clientTooLarge");
      return null;
    },
    [t],
  );

  const pick = useCallback(
    (candidate: File | null) => {
      if (!candidate) return;
      const err = validate(candidate);
      if (err) {
        setClientError(err);
        setFile(null);
        return;
      }
      setClientError(null);
      setFile(candidate);
    },
    [validate],
  );

  const onSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      if (!file) {
        setClientError(t("upload.noFile"));
        return;
      }
      setBusy(true);
      try {
        const honeypot = honeypotRef.current?.value ?? "";
        const result = await uploadReceipt(file, honeypot);
        // ハニーポット破棄時は receipt を含まない場合がある。存在時のみ確認フローへ。
        if (result && result.receipt) {
          onUploaded(result);
          showToast({
            type: "success",
            title: t("upload.successTitle"),
            message: t("upload.successBody"),
          });
        }
        setFile(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
      } catch (err) {
        handleError(err);
      } finally {
        setBusy(false);
      }
    },
    [file, onUploaded, handleError, showToast, t],
  );

  return (
    <form className="upload" onSubmit={onSubmit}>
      <div
        className={`upload__dropzone${dragOver ? " upload__dropzone--over" : ""}`}
        onDragOver={(e) => {
          e.preventDefault();
          setDragOver(true);
        }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragOver(false);
          pick(e.dataTransfer.files?.[0] ?? null);
        }}
        onClick={() => fileInputRef.current?.click()}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            fileInputRef.current?.click();
          }
        }}
      >
        <span className="upload__big-icon" aria-hidden="true">
          <Icon name="upload" />
        </span>
        <p className="upload__hint">{file ? file.name : t("upload.dropHint")}</p>
        <p className="upload__meta">
          {t("upload.formats")}　/　{t("upload.maxSize")}
        </p>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/jpeg,image/png"
          className="visually-hidden"
          onChange={(e) => pick(e.target.files?.[0] ?? null)}
        />
      </div>

      {/*
        ハニーポット（F8）。人間には見えず、スクリーンリーダーからも隠す。
        Bot が値を埋めるとサーバ側で無言破棄される。
      */}
      <div className="honeypot" aria-hidden="true">
        <label htmlFor="website">{t("a11y.honeypotLabel")}</label>
        <input
          ref={honeypotRef}
          id="website"
          name="website"
          type="text"
          tabIndex={-1}
          autoComplete="off"
          defaultValue=""
        />
      </div>

      {clientError ? (
        <p className="field-error" role="alert">
          <Icon name="exclamation" /> {clientError}
        </p>
      ) : null}

      <button type="submit" className="btn btn--primary btn--block" disabled={busy}>
        {busy ? (
          <>
            <Icon name="spinner" spin /> {t("upload.uploading")}
          </>
        ) : (
          <>
            <Icon name="upload" /> {t("upload.submit")}
          </>
        )}
      </button>
    </form>
  );
}
