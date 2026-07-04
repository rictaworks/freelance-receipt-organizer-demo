// Font Awesome を自己ホスト（外部 CDN に依存しない）。使用アイコンをここに集約する。
// 絵文字は一切使用しない（CLAUDE.md §5）。CSS の自動注入は無効化し、layout で明示 import する。
import { config } from "@fortawesome/fontawesome-svg-core";
import {
  faReceipt,
  faCloudArrowUp,
  faFileInvoiceDollar,
  faChartColumn,
  faHouse,
  faPen,
  faCheck,
  faXmark,
  faTriangleExclamation,
  faCircleInfo,
  faCircleCheck,
  faCircleXmark,
  faRotateRight,
  faDownload,
  faSpinner,
  faLanguage,
  faTag,
  faCalendarDay,
  faStore,
  faYenSign,
  faArrowRightFromBracket,
  faFilePdf,
  faCircleExclamation,
  faCommentDots,
  faArrowLeft,
} from "@fortawesome/free-solid-svg-icons";

// Next.js では layout での "@fortawesome/fontawesome-svg-core/styles.css" 明示 import と併用するため
// 自動 CSS 挿入を無効化して FOUC（スタイル未適用のちらつき）を防ぐ。
config.autoAddCss = false;

export const icons = {
  receipt: faReceipt,
  upload: faCloudArrowUp,
  report: faFileInvoiceDollar,
  chart: faChartColumn,
  home: faHouse,
  edit: faPen,
  check: faCheck,
  close: faXmark,
  warning: faTriangleExclamation,
  info: faCircleInfo,
  success: faCircleCheck,
  error: faCircleXmark,
  retry: faRotateRight,
  download: faDownload,
  spinner: faSpinner,
  language: faLanguage,
  tag: faTag,
  date: faCalendarDay,
  store: faStore,
  yen: faYenSign,
  exit: faArrowRightFromBracket,
  pdf: faFilePdf,
  exclamation: faCircleExclamation,
  consult: faCommentDots,
  back: faArrowLeft,
};

export type IconName = keyof typeof icons;
