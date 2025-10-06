# 次の作業計画（SQLite スキーマ確定と DAO 実装）

更新: 2025-09-03
対象: `g:/Unreal Projects/MyTEST`

---

## サマリ
- 目的: SQLite 永続化の土台（DDL）を確定し、Mail/Inventory の DAO と運用コマンドを実装・統合する。
- 現状: EnsureSchema は正準スキーマへ完全移行済み（`mail`, `inventory(amount)`）。既存DBは起動時にトランザクション内で安全に自動移行。互換ビュー（`mail_canonical_view`, `inventory_amount_view`）は廃止。`bank_cards`/`card_usage_history` は作成済み。DAO は正準テーブル/カラムに整合（Inventory は DB列 `amount`、Mail は `mail`）。`sqlite.EnsureSchema` 等のコンソール統合は継続。DAO のテストは Editor 内で手動確認想定。ヘッドレス実行（CLI/CI）は当面無し。加えて、`mail.ClaimAll` は添付JSONを解析し Inventory 追加とマルチ通貨の銀行入金＋`bank_tx`記録を単一SQLiteトランザクションで原子的に実行。検索最適化のため `mail(player_id, claimed, expire_at)` 複合インデックスを追加・常時保証。SelfTest は bank/mail に加え inventory スキーマ（必須列、(player_id,item_id) 複合PK、レガシー列/ビュー不在）の検証を実装済み。
- 範囲: `USQLiteSubsystem` の DDL/ユーティリティ強化と、`ULocalOpsSubsystem` からの運用導線。Automation クイックアクセスは未導入（任意、必要になれば追加）。

---

## タスク分析
- 目的: サーバー相当ワールドで安定稼働するデータ永続化を提供し、今後の機能拡張（ポイント・特典、取引履歴UI 等）の基盤とする。
- 技術要件:
  - WITH_SQLITE 無効でもビルド可能（No-Op 維持）
  - DDL は IF NOT EXISTS / トランザクション対応
  - Exec/Query のエラー可視化（JSONL へ）
- 実装手順:
  1) EnsureSchema へ DDL 追加（正準スキーマ＋互換ビュー／移行 DDL）
  2) Bank DAO（残高取得/入金/全プレイヤー取得）
  3) Mail DAO（保存/取得/期限スイープ連携）
  4) Inventory DAO（追加/消費/一覧）
  5) テスト用コンソールコマンド
- リスク:
  - 既存仮実装とのデータ整合（一時期は混在可）
  - 利息計算仕様の確定（月次/日次/5分分割）
- 品質基準:
  - UTF-8 BOM なし出力
  - サーバーワールドのみ作動
  - 例外/失敗時は JSONL へ構造化ログ

---

## スキーマ（DDL 状況）
適用箇所: `USQLiteSubsystem::EnsureSchema()` in `Source/MyTEST/Private/SQLiteSubsystem.cpp`

### ターゲット（正準）
- bank_accounts
  - `player_id TEXT`, `currency TEXT`, `balance INTEGER`, `updated_at TEXT`, `PRIMARY KEY(player_id, currency)`
- bank_tx
  - `id INTEGER PRIMARY KEY AUTOINCREMENT`, `player_id TEXT`, `currency TEXT`, `delta INTEGER`, `reason TEXT`, `ts TEXT`
  - Index: `CREATE INDEX IF NOT EXISTS idx_bank_tx_player ON bank_tx(player_id, ts);`
- mail（正準）
  - `mail_id TEXT PRIMARY KEY`, `player_id TEXT NOT NULL`, `subject TEXT NOT NULL`, `body TEXT NOT NULL`, `attachments_json TEXT NOT NULL`, `expire_at INTEGER NOT NULL /* UNIX秒 */`, `created_at INTEGER NOT NULL /* UNIX秒 */`, `claimed INTEGER NOT NULL DEFAULT 0`
  - Index: `CREATE INDEX IF NOT EXISTS idx_mail_player ON mail(player_id);` / `CREATE INDEX IF NOT EXISTS idx_mail_player_claimed_expire ON mail(player_id, claimed, expire_at);`
- inventory（正準）
  - `player_id TEXT`, `item_id TEXT`, `amount INTEGER`, `meta_json TEXT`, `updated_at INTEGER /* UNIX秒 */`, `PRIMARY KEY(player_id, item_id)`
  - 備考: 互換ビューは廃止。既存DBは起動時の移行でこの定義へ統一。
- bank_cards / card_usage_history
  - 現行定義のまま（変更なし）

### 既存DBの自動移行（要点）
- mail: 旧`mail`/`mails`から正準`mail(mail_id TEXT, ...)`へデータ移行。旧`mail`は`mail_legacy_backup`に退避。インデックス`idx_mail_player`作成。
- inventory: `quantity`列を`amount`へリビルド（新テーブル→データコピー→DROP→RENAME）。
- 互換ビュー: 完全移行後に`mail_canonical_view`/`inventory_amount_view`はDROP。

---

## DAO API（実装済み最小セット）

- Mail DAO（`UMailDAO`）
  - `bool ListMails(const FString& PlayerId, TArray<FMailRow>& OutMails)`
  - `bool SendMail(const FString& PlayerId, const FString& Subject, const FString& Body, const FString& AttachmentsJson, int64 ExpireAtSec)`
  - `int32 ClaimAll(const FString& PlayerId)`
  - `int32 SweepExpired()`
  - 備考: 正準テーブル `mail` を参照。`mail_id` を主キーとしてCRUD。`ClaimAll` は添付JSON（items/currencies/bank/トップレベル数値）を解析し、Inventory 追加とマルチ通貨の銀行入金＋`bank_tx`記録を単一SQLiteトランザクションで原子的に実行。既定通貨は`Gold`。パース失敗やDML失敗時は全体ロールバック。`ULocalOpsSubsystem::SweepExpiredMails()` から DB掃除→既存 `UMailboxComponent` 掃除の順で呼び出し。

- Inventory DAO（`UInventoryDAO`）
  - `bool ListItems(const FString& PlayerId, TArray<FInventoryRow>& OutItems)`
  - `bool AddItem(const FString& PlayerId, const FString& ItemId, int64 Amount, const FString& MetaJson)`
  - `int32 RemoveItem(const FString& PlayerId, const FString& ItemId, int64 Amount)`
  - 備考: 正準 `amount` 列を参照（DML/SELECTとも）。外部の構造体名は`Quantity`を維持しており、SELECT時は `amount AS quantity` でマッピング。

- Bank Account DAO（`UBankDAO` 口座/取引履歴）
  - `bool GetAccountBalance(const FString& PlayerId, const FString& CurrencyId, int64& OutBalance)`
  - `bool DepositToAccount(const FString& PlayerId, const FString& CurrencyId, int64 Amount, const FString& Reason)`
  - `bool WithdrawFromAccount(const FString& PlayerId, const FString& CurrencyId, int64 Amount, const FString& Reason)`
  - `bool ListTransactions(const FString& PlayerId, const FString& CurrencyId, TArray<FBankTransactionHistory>& OutTx)`
  - 備考: いずれも SQLite トランザクション整合を確保。`Deposit`/`Withdraw` は `bank_tx` へ履歴記録。`Withdraw` は残高検証（`balance >= Amount`）。

- Bank Card DAO（`UBankDAO`）
  - `bool ListCards(const FString& PlayerId, TArray<FPlayerBankCard>& OutCards)`
  - `bool IssueCard(const FString& PlayerId, EPlayerBankCardType CardType, int32 Rank, const FString& Note, int64 ExpiryAtSec, bool bTemporary = false, const FString& EventId = TEXT(""))`
  - `bool SetCardStatus(const FString& PlayerId, const FString& CardNumber, EPlayerBankCardStatus NewStatus)`
  - `bool SetCardDesign(const FString& PlayerId, const FString& CardNumber, const FString& DesignId, const FString& CustomColor, const FString& IconId)`
  - `bool MarkCardFraudulent(const FString& PlayerId, const FString& CardNumber, bool bFraudulent)`
  - `bool RecordCardUsage(const FString& PlayerId, const FString& CardNumber, int64 Amount, const FString& UsageType, const FString& Description, const FString& TargetId, bool bSuccess, const FString& FailReason)`
  - `bool ListCardUsageByCard(const FString& CardNumber, TArray<FCardUsageHistory>& OutUsage)`
  - `int32 ExpireOutdatedCards(const FString& PlayerId)`

---

1. EnsureSchema 実装
   - `USQLiteSubsystem::EnsureSchema()` は正準スキーマ（`mail`, `inventory(amount)`）を作成し、既存DBに対してはトランザクション内で自動移行（新テーブル→COPY→RENAME 等）を実施。移行完了後に互換ビューは削除。
2. Exec/Query ログ強化
  - 失敗時に SQL と `sqlite3_errmsg` を JSONL 出力
  - コンソール `sqlite.SelfTest` で DDL/CRUD を最小確認（加えて `interest.batch` 件数を情報ログで出力）
3. Bank DAO
  - 口座行 UPSERT（`INSERT ... ON CONFLICT(player_id,currency) DO UPDATE`）
  - Tx 履歴 Insert
  - `RunBankInterestBatch()` 改修（DB経由）
    - 現状: `ULocalOpsSubsystem::RunBankInterestBatch()` は `UBankDAO` を用いて利息を付与し、`reason='interest.batch'` で `bank_tx` に記録（マルチ通貨、`Gold` フォールバック対応）
    - 追加: 手動実行用コンソールコマンド `bank.InterestBatchNow` を実装し、サーバー相当ワールドで即時実行可能
4. Mail DAO / Inventory DAO
  - 必要最小の CRUD を段階的に

## UI 実装タイミング（ゲームUI作成の指針）
 - Bank: Bank DAO 最小APIとコンソールコマンドが通った後（`sqlite.SelfTest` と手動検証完了）に、`BankWidgetBase` へ入出金UI／取引ポップアップ／サウンドを段階追加。
 - Mail: Mailbox 添付受領のRPC導線は実装済み（`UMailboxComponent`）
   - 使用API: `ClaimAllAttachmentsForCurrentPlayer()`, `Client_OnClaimAllCompleted(int32)`, `OnMailUpdated`, `OnMailClaimAllCompleted`, `SetPlayerIdOverride(const FString&)`
   - UIバインド: UIボタン→`ClaimAllAttachmentsForCurrentPlayer()`。完了時は`OnMailClaimAllCompleted`で件数トースト→メール一覧の再取得/再描画（`OnMailUpdated`）
   - レプリケーション: 所有アクターの`bReplicates`必須。`UMailboxComponent`は`SetIsReplicatedByDefault(true)`。`BeginPlay`で未設定時に警告ログを出力
   - スモーク: PIE 2クライアント/1サーバで起動→クライアントからボタン実行→サーバで`UMailDAO::ClaimAll`が反映。必要に応じてコンソール`mail.ClaimAll <PlayerId>`で確認
    - __期限連携__: `SweepExpired()` 実行後に `ClaimAll` が期限切れメールを対象にしないこと
  - BankDAO（マルチ通貨/履歴整合）
    - __マルチ通貨__: `DepositToAccount`/`WithdrawFromAccount` が通貨ごとに独立に残高管理し、`updated_at`が更新される
    - __履歴__: `bank_tx` に delta/理由/通貨/時刻が記録され、同一時刻の順序は安定（`ORDER BY ts DESC`で期待と一致）
    - __不足額__: Withdrawで残高不足はfalse/ロールバック、`bank_tx`に記録されない
  - sqlite.SelfTest の補強
    - inventory スキーマ検証（実装済）: `inventory` テーブル存在、必須列（player_id,item_id,amount,meta_json,updated_at）、複合PK(player_id,item_id)、レガシー列`quantity`/ビュー`inventory_amount_view`の不在を INFO ログで出力
    - 既存のテーブル/索引確認に加え、最小CRUD検証（INSERT→SELECT→DELETE）が通ることを1行で確認
    - 利息バッチのDAO化後、`bank_tx` における `reason='interest.batch'` の総件数を情報ログとして出力（現状）／将来は直近実行の存在確認やバランス整合チェックも追加予定
  - コンソール・スモーク
    - `bank.Deposit`/`bank.Withdraw`/`mail.ClaimAll` の一連シナリオがエラー無く通り、残高/履歴が期待通りであること

  ---

{{ ... }}
  - KPI ハートビートは任意機能（未初期化でも最小行を一定間隔で出力）。必要時に別チケット化。
   - `ULocalOpsSubsystem` でサーバー権威ワールド時に初期化・タイマー登録（KPI、メール期限スイープ、銀行利息バッチ、SQLiteバックアップ/セルフテスト導線）を実装済。
