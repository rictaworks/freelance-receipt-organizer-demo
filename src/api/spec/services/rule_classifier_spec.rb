# frozen_string_literal: true

require "rails_helper"

# F3 ルールベース分類の単体テスト（seed 済みルールを利用）。
RSpec.describe RuleClassifier do
  subject(:classifier) { described_class.new }

  def category_id(code)
    AccountCategory.find_by!(code: code).id
  end

  it "キーワード一致で科目を返す" do
    expect(classifier.classify("タクシー領収書")).to eq(category_id("RYOHI"))
  end

  it "マッチしなければ未分類（nil）" do
    expect(classifier.classify("全く関係のないテキスト")).to be_nil
  end

  it "優先度が高い科目を採用する" do
    # 喫茶(KAIGI, priority2) と タクシー(RYOHI, priority3) を含む → RYOHI が勝つ。
    expect(classifier.classify("喫茶店とタクシーを利用")).to eq(category_id("RYOHI"))
  end

  it "優先度同点なら出現回数が多い科目を採用する" do
    # 文具(SHOMOHIN, pri3) が2回・書店(TOSHO, pri3) が1回 → SHOMOHIN。
    expect(classifier.classify("文具 文具 書店")).to eq(category_id("SHOMOHIN"))
  end

  it "優先度・出現回数が同点なら科目ID昇順で採用する" do
    # 文具(id小, pri3) と 書店(id大, pri3) が各1回 → 小さいID（SHOMOHIN）。
    expect(classifier.classify("文具 書店")).to eq(category_id("SHOMOHIN"))
  end

  it "空文字は nil" do
    expect(classifier.classify("")).to be_nil
  end
end
