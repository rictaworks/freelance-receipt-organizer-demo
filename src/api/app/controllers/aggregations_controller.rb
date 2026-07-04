# frozen_string_literal: true

# 集計取得（F4 / SPEC/api/aggregations.md）。GET /aggregations。
class AggregationsController < ApplicationController
  def index
    year = parse_year(params[:year], field: "year")
    result = Aggregator.new.aggregate(session_id: current_session.session_id, year: year)
    render json: result, status: :ok
  end
end
