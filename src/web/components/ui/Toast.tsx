"use client";

// トースト通知。ネイティブ alert() の代替（CLAUDE.md §5 で alert 禁止）。
// aria-live で読み上げ、Font Awesome アイコンで種別を示す。
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { Icon } from "./Icon";
import { useI18n } from "@/i18n/I18nProvider";

export type ToastType = "success" | "error" | "info" | "warning";

export interface ToastInput {
  type: ToastType;
  title: string;
  message?: string;
  traceId?: string | null;
  durationMs?: number;
}

interface ToastItem extends ToastInput {
  id: number;
}

interface ToastContextValue {
  showToast: (input: ToastInput) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

const ICON_BY_TYPE = {
  success: "success",
  error: "error",
  info: "info",
  warning: "warning",
} as const;

const DEFAULT_DURATION = 6000;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const seqRef = useRef(0);
  const { t } = useI18n();

  const dismiss = useCallback((id: number) => {
    setToasts((prev) => prev.filter((item) => item.id !== id));
  }, []);

  const showToast = useCallback(
    (input: ToastInput) => {
      seqRef.current += 1;
      const id = seqRef.current;
      const item: ToastItem = { id, ...input };
      setToasts((prev) => [...prev, item]);
      const duration = input.durationMs ?? DEFAULT_DURATION;
      // エラーは自動で消さず、ユーザーが閉じるまで残す（trace_id の確認機会を保つ）。
      if (input.type !== "error" && duration > 0) {
        window.setTimeout(() => dismiss(id), duration);
      }
    },
    [dismiss],
  );

  const value = useMemo<ToastContextValue>(() => ({ showToast }), [showToast]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toast-region" role="region" aria-live="polite" aria-atomic="false">
        {toasts.map((item) => (
          <div key={item.id} className={`toast toast--${item.type}`} role="status">
            <span className="toast__icon" aria-hidden="true">
              <Icon name={ICON_BY_TYPE[item.type]} />
            </span>
            <div className="toast__body">
              <p className="toast__title">{item.title}</p>
              {item.message ? <p className="toast__message">{item.message}</p> : null}
              {item.traceId ? (
                <p className="toast__trace">
                  {t("errors.traceLabel")}: <code>{item.traceId}</code>
                </p>
              ) : null}
            </div>
            <button
              type="button"
              className="toast__close"
              onClick={() => dismiss(item.id)}
              aria-label={t("a11y.closeToast")}
            >
              <Icon name="close" />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error("useToast は ToastProvider の内側で使用してください。");
  }
  return ctx;
}
