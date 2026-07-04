Rails.application.routes.draw do
  # ヘルスチェック（起動確認用）。
  get "up" => "rails/health#show", as: :rails_health_check

  # セッション発行（F6）。
  get "/session", to: "sessions#show"

  # 領収書（F1/F2/F3/F6/F8）。
  post  "/receipts",     to: "receipts#create"
  get   "/receipts",     to: "receipts#index"
  patch "/receipts/:id", to: "receipts#update"

  # 勘定科目マスタ（F3）。
  get "/categories", to: "categories#index"

  # 集計（F4）。
  get "/aggregations", to: "aggregations#index"

  # 帳票（F5/F6）。/reports/:id.pdf は format=pdf として download へ。
  post "/reports", to: "reports#create"
  get  "/reports/:id", to: "reports#download", constraints: { id: /\d+/ }, defaults: { format: "pdf" }
end
