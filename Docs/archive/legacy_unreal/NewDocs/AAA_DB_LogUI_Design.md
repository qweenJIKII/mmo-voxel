# AAA DB & Log UI 設計メモ

## 1. 目的
- ランタイム中にサーバー/クライアントの SQLite アクセス結果とログを確認できるデバッグ UI を提供する。
- QA・サポート担当が即時にクエリ実行やログフィルタを行い、不具合報告の精度を向上させる。

## 2. 機能概要
### 2.1 DB ビューア
- 事前登録クエリ（プリセット）と任意 SQL の両方をサポート。
- `USQLiteSubsystem` を仲介として非同期実行（ゲームスレッドへ結果コールバック）。
- ページング・ソート（UI 側でカラムソート）対応。

### 2.2 ログビューア
- `GLog` へ専用 `FOutputDevice` を追加し、リングバッファ形式でログを収集。
- カテゴリ（`LogInventory` など）や Verbosity（`Warning` など）でフィルタ。
- ピン留め / 検索 / 一括コピーに対応。

## 3. コンポーネント構成
- `UDBQueryManagerComponent`
  - プリセット定義（`TMap<FName, FDBQueryPreset>`）。
  - `ExecutePreset()` / `ExecuteQuery()` で結果を `OnQueryCompleted` デリゲートへ送信。
- `ULogCaptureComponent`
  - 内部に `FDBLogEntry` リングバッファ。
  - `StartCapture()` / `StopCapture()` を公開。
  - `OnLogAppended` デリゲートで UI に更新通知。
  - `CopyToClipboard()`、`GetBufferedLogs()` 等のユーティリティ。

## 4. データフロー
1. UI から DB プリセット選択 → `UDBQueryManagerComponent::ExecutePreset()`。
2. `USQLiteSubsystem` 経由でクエリ実行 → 完了時 `FDbQueryResult` を取得。
3. 結果は `FDBQueryResultView` に変換し、UI 側で `TArray<FDBQueryRowView>` としてバインド。
4. ログは `ULogCaptureComponent` が `FOutputDevice` 経由で受信 → バッファ追加 → `OnLogBufferUpdated` を発火。

## 5. UI ガイド
- `WBP_DebugConsole`
  - タブ: `DB`, `Logs`。
  - DB: プリセット一覧（ListView）＋ クエリエディタ（`MultiLineEditableText`）＋ 結果グリッド（`ListView`）。
  - Logs: フィルタ（カテゴリ, Verbosity, 検索文字列）＋ ログリスト（`ListView`）＋ ピン留め領域。
- トースト通知との連携: 重大ログは `NotificationManagerComponent` を通じて通知。

## 6. 実装タスク
1. `Public/UI/DBLog/` に型定義（`DBQueryTypes.h` / `LogCaptureTypes.h`）。
2. `UDBQueryManagerComponent` / `ULogCaptureComponent` 実装。
3. `SQLiteSubsystem` との連携メソッド追加（必要に応じて）
4. ドキュメント更新と使用例追記。

## 7. 今後の拡張候補
- DB 結果の CSV 書き出し。
- ネットワーク越しのクエリ実行（サーバー権限チェック）。
- ログ強調表示（正規表現によるカラーリング）。
