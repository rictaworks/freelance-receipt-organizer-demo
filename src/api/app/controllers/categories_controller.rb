# frozen_string_literal: true

# 勘定科目マスタ取得（F3 / SPEC/api/categories.md）。GET /categories。
class CategoriesController < ApplicationController
  def index
    categories = AccountCategory.ordered.to_a
    # 12件未満は握りつぶさず MASTER_NOT_SEEDED（フォールバック禁止）。
    if categories.size < AccountCategory::EXPECTED_COUNT
      raise ApiError.new("MASTER_NOT_SEEDED", details: [{ "count" => categories.size }])
    end

    render json: {
      "categories" => categories.map { |c| { "id" => c.id, "code" => c.code, "name" => c.name } },
      "count" => categories.size
    }, status: :ok
  end
end
