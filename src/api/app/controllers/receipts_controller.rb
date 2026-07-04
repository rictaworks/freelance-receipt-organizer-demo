# frozen_string_literal: true

# 領収書 API（F1/F2/F3/F6/F8 / SPEC/api/receipts.md）。
class ReceiptsController < ApplicationController
  # POST /receipts（アップロード）。
  def create
    # ハニーポット（F8）: 値があれば 200 で無言破棄（DB/OCR 一切呼ばない）。
    if HoneypotFilter.should_discard?(params)
      return render json: { "status" => "accepted" }, status: :ok
    end

    uploaded_file = params[:file]
    raise ApiError.new("FILE_MISSING", details: [{ "field" => "file", "reason" => "missing" }]) if uploaded_file.blank?

    result = ReceiptRegistrar.new.call(session: current_session, uploaded_file: uploaded_file)

    render json: {
      "receipt" => ReceiptPresenter.detail(result.receipt),
      "warnings" => result.warnings
    }, status: :created
  end

  # GET /receipts（一覧）。session_id 強制フィルタ（F6）。
  def index
    scope = Receipt.where(session_id: current_session.session_id)
    scope = apply_year_filter(scope)
    scope = apply_category_filter(scope)
    receipts = scope.order(issued_on: :desc, id: :desc).to_a

    render json: {
      "receipts" => receipts.map { |r| ReceiptPresenter.summary(r) },
      "count" => receipts.size
    }, status: :ok
  end

  # PATCH /receipts/:id（手動修正・科目変更）。manually_edited=true。
  def update
    receipt = Receipt.find_by(session_id: current_session.session_id, id: params[:id])
    # 存在しない or 他セッション → 一律 404（存在秘匿, F6）。
    raise ApiError.new("RECEIPT_NOT_FOUND") if receipt.nil?

    receipt.update!(build_update_attributes.merge(manually_edited: true))

    render json: { "receipt" => ReceiptPresenter.updated(receipt) }, status: :ok
  end

  private

  def apply_year_filter(scope)
    return scope if params[:year].blank?

    year = integer_or_nil(params[:year])
    return scope if year.nil?

    scope.where(issued_on: Date.new(year, 1, 1)..Date.new(year, 12, 31))
  end

  def apply_category_filter(scope)
    return scope unless params.key?(:category_id)

    raw = params[:category_id]
    # 0 または null 指定は未分類（category_id IS NULL）。
    if raw.nil? || raw.to_s == "0" || raw.to_s.downcase == "null"
      scope.where(category_id: nil)
    else
      scope.where(category_id: integer_or_nil(raw))
    end
  end

  # 部分更新の属性を構築しつつ、各フィールドを明示的に検証する（フォールバック禁止）。
  def build_update_attributes
    attrs = {}
    attrs[:issued_on] = parse_issued_on(params[:issued_on]) if params.key?(:issued_on)
    attrs[:amount_yen] = parse_amount(params[:amount_yen]) if params.key?(:amount_yen)
    attrs[:store_name] = params[:store_name] if params.key?(:store_name)
    attrs[:category_id] = parse_category_id(params[:category_id]) if params.key?(:category_id)
    attrs
  end

  def parse_issued_on(value)
    return nil if value.nil?

    Date.strptime(value.to_s, "%Y-%m-%d")
  rescue ArgumentError
    raise ApiError.new("INVALID_DATE_FORMAT", details: [{ "field" => "issued_on", "reason" => "invalid_format" }])
  end

  def parse_amount(value)
    # 0 以下は手動確定を許容（警告扱いだが登録可）。整数でなければ 422。
    return value if value.is_a?(Integer)
    return Integer(value.to_s, 10) if value.is_a?(String) && value.match?(/\A-?\d+\z/)

    raise ApiError.new("INVALID_AMOUNT", details: [{ "field" => "amount_yen", "reason" => "not_an_integer" }])
  end

  def parse_category_id(value)
    # null または 0 は未分類へ戻す。
    return nil if value.nil? || value.to_s == "0"

    category_id = integer_or_nil(value)
    if category_id.nil? || !AccountCategory.exists?(id: category_id)
      raise ApiError.new("INVALID_CATEGORY", details: [{ "field" => "category_id", "reason" => "not_found" }])
    end

    category_id
  end

  def integer_or_nil(value)
    Integer(value.to_s, 10)
  rescue ArgumentError, TypeError
    nil
  end
end
