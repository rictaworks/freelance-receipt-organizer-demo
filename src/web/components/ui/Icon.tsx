"use client";

// Font Awesome ラッパ。アイコンは icons.ts に集約したものだけを名前で参照する。
// 絵文字は使わない（CLAUDE.md §5）。装飾目的の場合は aria-hidden、意味を持つ場合は title を渡す。
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { icons, type IconName } from "@/lib/icons";

interface IconProps {
  name: IconName;
  className?: string;
  spin?: boolean;
  title?: string;
}

export function Icon({ name, className, spin, title }: IconProps) {
  return (
    <FontAwesomeIcon
      icon={icons[name]}
      className={className}
      spin={spin}
      title={title}
      aria-hidden={title ? undefined : true}
    />
  );
}
