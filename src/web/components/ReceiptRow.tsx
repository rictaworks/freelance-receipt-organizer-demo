"use client";

// 領収書 1 行。表示モードと編集モードを切り替える（UC2 抽出結果修正 / UC3 科目変更）。
// null フィールド（抽出失敗）は編集モードで手動入力へ誘導する。
import { useState } from "react";
import { Icon } from "./ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";
import { formatConfidence, formatYen, isValidDateString } from "@/lib/format";
import { patchReceipt } from "@/lib/api";
import type { Category, Receipt } from "@/lib/types";
import { useApiError } from "@/lib/useApiError";
import { useToast } from "./ui/Toast";

interface Props {
  receipt: Receipt;
  categories: Category[];
  onUpdated: (updated: Receipt) => void;
}

export function ReceiptRow({ receipt, categories, onUpdated }: Props) {
  const { t, locale } = useI18n();
  const { showToast } = useToast();
  const handleError = useApiError();
  const [editing, setEditing] = useState(false);
  const [busy, setBusy] = useState(false);

  const [issuedOn, setIssuedOn] = useState(receipt.issued_on ?? "");
  const [storeName, setStoreName] = useState(receipt.store_name ?? "");
  const [amount, setAmount] = useState(
    receipt.amount_yen !== null ? String(receipt.amount_yen) : "",
  );
  const [categoryId, setCategoryId] = useState<string>(
    receipt.category_id !== null ? String(receipt.category_id) : "",
  );
  const [dateError, setDateError] = useState<string | null>(null);
  const [amountError, setAmountError] = useState<string | null>(null);

  const needsManual =
    receipt.issued_on === null || receipt.amount_yen === null;

  const resetFromReceipt = (r: Receipt) => {
    setIssuedOn(r.issued_on ?? "");
    setStoreName(r.store_name ?? "");
    setAmount(r.amount_yen !== null ? String(r.amount_yen) : "");
    setCategoryId(r.category_id !== null ? String(r.category_id) : "");
    setDateError(null);
    setAmountError(null);
  };

  const onSave = async () => {
    setDateError(null);
    setAmountError(null);

    // クライアント側バリデーション（Fail Fast）。
    if (issuedOn !== "" && !isValidDateString(issuedOn)) {
      setDateError(t("errors.INVALID_DATE_FORMAT"));
      return;
    }
    let amountValue: number | null = null;
    if (amount !== "") {
      const parsed = Number(amount);
      if (!Number.isInteger(parsed)) {
        setAmountError(t("errors.INVALID_AMOUNT"));
        return;
      }
      amountValue = parsed;
    }

    setBusy(true);
    try {
      const res = await patchReceipt(receipt.id, {
        issued_on: issuedOn === "" ? null : issuedOn,
        store_name: storeName === "" ? null : storeName,
        amount_yen: amountValue,
        category_id: categoryId === "" ? null : Number(categoryId),
      });
      onUpdated(res.receipt);
      setEditing(false);
      showToast({
        type: "success",
        title: t("receipts.savedTitle"),
        message: t("receipts.savedBody"),
      });
    } catch (err) {
      handleError(err);
    } finally {
      setBusy(false);
    }
  };

  if (editing) {
    return (
      <tr className="receipt-row receipt-row--editing">
        <td data-label={t("receipts.colDate")}>
          <input
            className="cell-input"
            type="text"
            value={issuedOn}
            placeholder={t("receipts.placeholderDate")}
            onChange={(e) => setIssuedOn(e.target.value)}
            aria-label={t("receipts.colDate")}
          />
          {dateError ? <span className="field-error">{dateError}</span> : null}
        </td>
        <td data-label={t("receipts.colStore")}>
          <input
            className="cell-input"
            type="text"
            value={storeName}
            placeholder={t("receipts.placeholderStore")}
            onChange={(e) => setStoreName(e.target.value)}
            aria-label={t("receipts.colStore")}
          />
        </td>
        <td data-label={t("receipts.colAmount")}>
          <input
            className="cell-input cell-input--number"
            type="number"
            inputMode="numeric"
            value={amount}
            placeholder={t("receipts.placeholderAmount")}
            onChange={(e) => setAmount(e.target.value)}
            aria-label={t("receipts.colAmount")}
          />
          {amountError ? <span className="field-error">{amountError}</span> : null}
        </td>
        <td data-label={t("receipts.colCategory")}>
          <select
            className="cell-input"
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            aria-label={t("receipts.colCategory")}
          >
            <option value="">{t("common.uncategorized")}</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </td>
        <td data-label={t("receipts.colConfidence")}>
          {formatConfidence(receipt.ocr_confidence)}
        </td>
        <td className="receipt-row__actions" colSpan={2}>
          <button
            type="button"
            className="btn btn--primary btn--sm"
            onClick={onSave}
            disabled={busy}
          >
            {busy ? <Icon name="spinner" spin /> : <Icon name="check" />}{" "}
            {t("common.save")}
          </button>
          <button
            type="button"
            className="btn btn--ghost btn--sm"
            onClick={() => {
              resetFromReceipt(receipt);
              setEditing(false);
            }}
            disabled={busy}
          >
            <Icon name="close" /> {t("common.cancel")}
          </button>
        </td>
      </tr>
    );
  }

  return (
    <tr className={`receipt-row${needsManual ? " receipt-row--attention" : ""}`}>
      <td data-label={t("receipts.colDate")}>
        {receipt.issued_on ?? <span className="muted">{t("common.none")}</span>}
      </td>
      <td data-label={t("receipts.colStore")}>
        {receipt.store_name ?? <span className="muted">{t("common.none")}</span>}
      </td>
      <td data-label={t("receipts.colAmount")} className="num">
        {receipt.amount_yen !== null ? (
          <>
            {formatYen(receipt.amount_yen, locale)}
            <span className="unit"> {t("common.yen")}</span>
          </>
        ) : (
          <span className="muted">{t("common.none")}</span>
        )}
      </td>
      <td data-label={t("receipts.colCategory")}>
        {receipt.category_name ? (
          <span className="chip">
            <Icon name="tag" /> {receipt.category_name}
          </span>
        ) : (
          <span className="chip chip--warn">
            <Icon name="tag" /> {t("common.uncategorized")}
          </span>
        )}
      </td>
      <td data-label={t("receipts.colConfidence")}>
        {formatConfidence(receipt.ocr_confidence)}
      </td>
      <td data-label={t("receipts.colEdited")}>
        {needsManual ? (
          <span className="badge badge--attention">{t("receipts.manualInput")}</span>
        ) : receipt.manually_edited ? (
          <span className="badge badge--edited">{t("receipts.editedBadge")}</span>
        ) : (
          <span className="badge badge--auto">{t("receipts.autoBadge")}</span>
        )}
      </td>
      <td className="receipt-row__actions">
        <button
          type="button"
          className="btn btn--ghost btn--sm"
          onClick={() => setEditing(true)}
          aria-label={t("receipts.editRow")}
        >
          <Icon name="edit" /> {t("common.edit")}
        </button>
      </td>
    </tr>
  );
}
