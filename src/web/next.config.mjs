/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // 文言・設定値はコードに埋め込まず、環境変数／翻訳リソースへ分離する（CLAUDE.md §4/§8）。
  // API ベース URL は NEXT_PUBLIC_API_BASE を参照する（既定は開発環境の Rails: http://localhost:4000）。
};

export default nextConfig;
