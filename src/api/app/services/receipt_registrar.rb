# frozen_string_literal: true

require "fileutils"

# 領収書アップロード処理（F1/F2/F3/F8 / SPEC/api/receipts.md）。
# 検証→OCR→項目抽出(F2)→分類(F3)→重複検知→INSERT→画像保存 を一貫して行う。
# フォールバック禁止: 各失敗は ApiError として明示的に分類する（CLAUDE.md §4）。
class ReceiptRegistrar
  Result = Struct.new(:receipt, :warnings, keyword_init: true)

  def initialize(field_extractor: FieldExtractor.new, classifier: RuleClassifier.new, ocr_client: OcrClient)
    @field_extractor = field_extractor
    @classifier = classifier
    @ocr_client = ocr_client
  end

  # session（Session）と uploaded_file（ActionDispatch::Http::UploadedFile）から登録する。
  def call(session:, uploaded_file:)
    validate_content_type!(uploaded_file)
    validate_size!(uploaded_file)

    ocr = @ocr_client.call(
      file_path: uploaded_file.tempfile.path,
      content_type: uploaded_file.content_type,
      filename: uploaded_file.original_filename
    )
    full_text = ocr["full_text"].to_s
    confidence = ocr["confidence"]

    fields = @field_extractor.extract(full_text)

    # 認識不能（信頼度低＋日付金額とも抽出不能＋手動入力も不能）→ 422（F1）。
    if unrecognizable?(confidence, fields, full_text)
      raise ApiError.new("OCR_UNRECOGNIZABLE")
    end

    classify_text = [fields.store_name, full_text].compact.join("\n")
    category_id = @classifier.classify(classify_text)

    duplicate = Receipt.duplicate_exists?(
      session_id: session.session_id,
      issued_on: fields.issued_on,
      amount_yen: fields.amount_yen,
      store_name: fields.store_name
    )

    receipt = Receipt.create!(
      session_id: session.session_id,
      category_id: category_id,
      issued_on: fields.issued_on,
      amount_yen: fields.amount_yen,
      store_name: fields.store_name,
      ocr_confidence: confidence,
      manually_edited: false,
      created_at: Time.current
    )

    store_image!(receipt, uploaded_file)

    Result.new(
      receipt: receipt,
      warnings: build_warnings(fields, category_id, confidence, duplicate)
    )
  end

  private

  def config
    AppConfig.ocr
  end

  def validate_content_type!(file)
    allowed = config.fetch("allowed_content_types")
    return if allowed.include?(file.content_type)

    raise ApiError.new(
      "UNSUPPORTED_MEDIA_TYPE",
      details: [{ "field" => "file", "reason" => "unsupported_content_type" }]
    )
  end

  def validate_size!(file)
    max = config.fetch("max_file_size_bytes")
    return if file.size <= max

    raise ApiError.new("FILE_TOO_LARGE", details: [{ "field" => "file", "reason" => "too_large", "max_bytes" => max }])
  end

  def threshold
    config.fetch("low_confidence_threshold")
  end

  def low_confidence?(confidence)
    !confidence.nil? && confidence < threshold
  end

  # 日付・金額とも抽出不能かつ信頼度低。手動入力にも誘導不能（店名も全文も無い）→ 認識不能。
  def unrecognizable?(confidence, fields, full_text)
    low_confidence?(confidence) &&
      fields.issued_on.nil? &&
      fields.amount_yen.nil? &&
      fields.store_name.nil? &&
      full_text.strip.empty?
  end

  # 信頼度低かつ日付・金額とも抽出不能（ただし手動入力へ誘導は可能）。
  def low_confidence_manual_input?(confidence, fields)
    low_confidence?(confidence) && fields.issued_on.nil? && fields.amount_yen.nil?
  end

  def build_warnings(fields, category_id, confidence, duplicate)
    warnings = []
    warnings << warning(:duplicate) if duplicate
    warnings << warning(:non_positive_amount) if !fields.amount_yen.nil? && fields.amount_yen <= 0
    warnings << warning(:uncategorized) if category_id.nil?
    warnings << warning(:low_confidence_manual_input) if low_confidence_manual_input?(confidence, fields)
    warnings
  end

  def warning(code)
    { "code" => code.to_s, "message" => AppConfig.warnings.fetch(code.to_s) }
  end

  # 原本画像を storage/uploads/<session_id>/<receipt_id>.<ext> に保存し image_path を記録する。
  # image_path には Web 公開向けの相対パス（/uploads/...）を保持する。
  # F7 日次リセット(JST03:00)で storage/uploads 配下は全削除される（親担当）。
  def store_image!(receipt, uploaded_file)
    ext = uploaded_file.content_type == "image/png" ? "png" : "jpg"
    dir = Rails.root.join("storage", "uploads", receipt.session_id)
    FileUtils.mkdir_p(dir)
    absolute = dir.join("#{receipt.id}.#{ext}")
    File.binwrite(absolute, File.binread(uploaded_file.tempfile.path))
    receipt.update!(image_path: "/uploads/#{receipt.session_id}/#{receipt.id}.#{ext}")
  end
end
