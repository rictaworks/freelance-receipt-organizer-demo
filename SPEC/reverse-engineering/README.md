# リバースエンジニアリング図

本ディレクトリは、設計書（`freelance-receipt-organizer-demo_設計書.md`）に記載された mermaid 図を、個別の `.mmd` ソースファイルとして分割・管理します。各ファイルは `mermaid` フェンス（```mermaid ... ```）を含まない純粋な mermaid 記法で記述されており、`@mermaid-js/mermaid-cli`（mmdc）でそのまま SVG 化できます。

コードを変更した際は、対応する図を必ず本ディレクトリで追従更新してください（正典は設計書です）。

## 図の一覧

| ファイル | 種別 | 説明 |
|---|---|---|
| `er.mmd` | ER図（erDiagram） | SESSIONS / RECEIPTS / ACCOUNT_CATEGORIES / CLASSIFY_RULES / REPORTS の 5 テーブルと関連。認証なしのためユーザーテーブルは存在せず、個人情報カラムも持たない。session_id を全所有テーブルのオーナーキーとする。 |
| `dfd.mmd` | DFD（flowchart LR） | 画像受付（P1）→OCR/項目抽出（P2）→ルールベース分類（P3）→集計（P4）→帳票生成（P5）のデータフロー。日次リセット（P6）はスケジューラ起動で receipts / 画像 / reports を全削除。 |
| `sequence.mmd` | シーケンス図（sequenceDiagram） | 初回アクセスのセッション発行から、領収書アップロード（ハニーポット分岐含む）、OCR、抽出・分類・重複チェック・INSERT、帳票生成までの一連の流れ。 |
| `class.mmd` | クラス図（classDiagram） | Session / Receipt / AccountCategory / ClassifyRule / Report の各エンティティと、OcrService / FieldExtractor / RuleClassifier / Aggregator / ReportGenerator / DailyResetJob / HoneypotFilter のサービス群の関係。 |
| `state.mmd` | 状態遷移図（stateDiagram-v2） | 領収書レコードのライフサイクル。アップロード受付→OCR処理中→抽出完了→登録済み→（集計反映）→日次リセットで終了。ハニーポット検知・サイズ超過・非対応形式・ユーザー取消は破棄へ遷移。 |
| `usecase.mmd` | ユースケース図（flowchart TB） | フリーランスユーザー・スケジューラ・Bot の 3 アクターと 8 ユースケース。認証系ユースケースはデモ版制約により存在しない。 |

## 注意事項

- mermaid のノードラベル内の改行は、mmdc でのエラーを避けるため `\n` ではなく `<br/>` を使用しています。
- 図の内容を変更する場合は、必ず設計書と整合させてください。

## SVG 化手順（mmdc）

`@mermaid-js/mermaid-cli` を用いて `.mmd` を SVG へ変換します。リポジトリ直下の `package.json` に以下のスクリプトを定義しておくと便利です。

```json
{
  "scripts": {
    "docs:render": "mmdc -i SPEC/reverse-engineering/er.mmd -o SPEC/reverse-engineering/er.svg && mmdc -i SPEC/reverse-engineering/dfd.mmd -o SPEC/reverse-engineering/dfd.svg && mmdc -i SPEC/reverse-engineering/sequence.mmd -o SPEC/reverse-engineering/sequence.svg && mmdc -i SPEC/reverse-engineering/class.mmd -o SPEC/reverse-engineering/class.svg && mmdc -i SPEC/reverse-engineering/state.mmd -o SPEC/reverse-engineering/state.svg && mmdc -i SPEC/reverse-engineering/usecase.mmd -o SPEC/reverse-engineering/usecase.svg"
  }
}
```

導入と実行:

```bash
# 一時導入して実行
npx -y @mermaid-js/mermaid-cli -i SPEC/reverse-engineering/er.mmd -o SPEC/reverse-engineering/er.svg

# もしくは開発依存として導入後
npm install -D @mermaid-js/mermaid-cli
npm run docs:render
```

日本語フォントが埋め込まれない環境では、`-c` オプションで mermaid 設定（テーマ・フォント）を指定してください。
