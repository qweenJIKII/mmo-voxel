# ユーザー体験系システム 実装状況と未実装機能（現状調査）

更新: 2025-08-25
対象: `g:/Unreal Projects/MyTEST`

---

## サマリ
- 実装済み（概ね動作）: インベントリ/装備、クエスト、ガチャ、銀行（基幹）、チャット、メール、パーティ（基礎）、能力システム（GAS 拡張基礎）、ギャザリング/採集
- 部分実装（機能穴あり）: トレード（P2P）、オークション/マーケット、銀行ポイント/特典、メールUI連携/HUD同期、パーティのサーバ権威処理、GASの初期アビリティロード
- 未確認/未実装の可能性: ギルドの機能詳細（イベント・倉庫の操作系）、レプリケーション最適化（体験改善に直結する可視化は別ドキュメント参照）

---

## 詳細（機能別）

### 1) インベントリ/装備
- 実装根拠:
  - `Source/MyTEST/Public/InventoryComponent.h`
  - `Source/MyTEST/Private/InventoryComponent.cpp`
  - `Source/MyTEST/Public/InventoryWidget.h` 他 UMG 一式
- 所見: 主要操作/UMGは実装済み。TODOの顕著な欠落なし。
- ステータス: 実装済み

### 2) クエスト
- 実装根拠:
  - `Source/MyTEST/Public/QuestComponent.h`
  - `Source/MyTEST/Private/QuestComponent.cpp`
  - `Source/MyTEST/Public/QuestJournalWidget.h`
- 所見: `QuestComponent` と UI が揃っており、未実装TODOの顕著な検出なし。
- ステータス: 実装済み

### 3) ガチャ
- 実装根拠:
  - `Source/MyTEST/Public/GachaSystem.h`
  - `Source/MyTEST/Private/GachaSystem.cpp`
  - `Source/MyTEST/Public/GachaRewardManager.h`
- 所見: 実装/生成物が存在。未実装TODOの顕著な検出なし。
- ステータス: 実装済み

### 4) 銀行（口座/取引履歴/UI）
- 実装根拠:
  - `Source/MyTEST/Public/BankSubsystem.h`, `Source/MyTEST/Private/BankSubsystem.cpp`
  - `Source/MyTEST/Public/BankWidgetBase.h`, `Source/MyTEST/Private/BankWidgetBase.cpp`
  - 各種履歴/カード UI クラス（`BankTransactionHistoryWidget.h` など）
  - SQLite DAO: `Source/MyTEST/Public/BankDAO.h`, `Source/MyTEST/Private/BankDAO.cpp`
  - DB スキーマ: `SQLiteSubsystem.cpp::EnsureSchema()` に `bank_cards` / `card_usage_history` 追加済
  - 運用導線: `Source/MyTEST/Private/LocalOpsSubsystem.cpp` 初期化で EnsureSchema/Backup/KPI/メールスイープ/銀行利息バッチのタイマー登録
- 未実装/要対応:
  - `BankSubsystem.cpp`:
    - ポイント還元の加算先の決定と反映: `// TODO: プレイヤーのポイント残高に加算`
    - 金利補正の実ロジック: `// TODO: 必要に応じて補正を追加`
  - `BankWidgetBase.cpp`:
    - 取引ポップアップ表示/サウンド再生の中身: `// TODO: ... 追加`
- ステータス: 部分実装（基幹は可、特典/演出が未完）

### 5) トレード（P2P）/マーケット（オークション）
- 実装根拠:
  - `Source/MyTEST/Public/TradeManagerComponent.h`, `Private/TradeManagerComponent.cpp`
  - `Source/MyTEST/Public/TradeServerManager.h`, `Private/TradeServerManager.cpp`
  - `TradeTypes.h`, `TradeStateInfo.h`
- 未実装/要対応（抜粋）:
  - `TradeManagerComponent.cpp`:
    - 在庫取得ロジックの実装: `StockCount // TODO`
    - サーバー経由のリクエスト通知/状態同期/オファー同期/承認完了処理/キャンセル通知: `// TODO: サーバー経由 ...`
    - アイテム受け渡し（銀行/手持ち分岐）: `// TODO: アイテムの受け渡し処理`
  - `TradeServerManager.cpp`:
    - 所有/ロック状態検証、アトミック受け渡し、承認同期、ロック解除、購入時の決済検証: `// TODO: ...`
- ステータス: 部分実装（クライアント側の流れは概形、サーバ権威・整合性が未完）

### 6) メール（添付/受領）
- 実装根拠:
  - `Source/MyTEST/Public/MailboxComponent.h`, `Private/MailboxComponent.cpp`
- 現状/要対応:
  - 一括受領のサーバ権威RPC導線: 実装済（`Server_ClaimAllAttachments` → `UMailDAO::ClaimAll` → `Client_OnClaimAllCompleted`）。UI通知: `OnMailUpdated`/`OnMailClaimAllCompleted`
  - 個別ID受領: 未実装（次フェーズで `Server_ClaimAttachmentById` + DAO 単体Claimを設計）
  - UI/HUD連携: 未接続（受領ボタンを `ClaimAllAttachmentsForCurrentPlayer()` にバインド、完了トースト表示）
  - レプリケーション注意: Owning Actor の `bReplicates=true` 必須。`UMailboxComponent` は既定で Replicate。`BeginPlay` で未設定時は警告ログ
- ステータス: 部分実装（サーバ権威の一括受領とUI通知導線は実装済、UI/HUD接続は未着手）

### 7) パーティ
- 実装根拠:
  - `Source/MyTEST/Public/PartyComponent.h`, `Private/PartyComponent.cpp`
- 未実装/要対応:
  - サーバー権威の招待/脱退/キック/リーダー交代: `ServerInviteToParty_Implementation` など一連が `// TODO`
  - 初期データロード: `LoadDefaultPartyData`: `// TODO`
- ステータス: 部分実装（RPCの中身未実装）

### 8) チャット
- 実装根拠:
  - `Source/MyTEST/Public/ChatComponent.h`
- 所見: 具体的な TODO は検出されず。詳細動作は別途確認が必要。
- ステータス: 実装済み（仮）

### 9) ギルド
- 実装根拠:
  - `Source/MyTEST/Public/GuildEventManager.h`, `GuildEventTypes.h`, `GuildWarehouse.h`
- 所見: `Guild*.cpp` に顕著な TODO は検出されず。操作系（倉庫入出庫、役職、イベント処理）の有無は未確認。
- ステータス: 要確認（未実装の可能性あり）

### 10) 能力システム（GAS拡張）
- 実装根拠:
  - `Source/MyTEST/Public/MMOAbilitySystemComponent.h`, `Private/MMOAbilitySystemComponent.cpp`
- 未実装/要対応:
  - 既定アビリティのロード: `LoadDefaultAbilities`: `// TODO`
- ステータス: 部分実装

### 11) ギャザリング/採集
- 実装根拠:
  - `Source/MyTEST/Public/GatherComponent.h`
  - `Source/MyTEST/Private/GatherComponent.cpp`
  - `Source/MyTEST/Public/IAutoGatherable.h`
- 所見: 主要機能は実装済み。該当ファイルに顕著な TODO は検出されず。
- ステータス: 実装済み

### 12) プレイヤーステータス/HUD
- 実装根拠:
  - （新規UI。HUD系 Blueprint/Widget を追加予定）
- 所見: 基本HUDは未記載。GAS/Party/Inventory の整合に依存。
- 依存: Inventory/Equipment のレプリ/デリゲート、`MMOAbilitySystemComponent::LoadDefaultAbilities`（最小）、`mail.ClaimAll` による Gold の `inventory.amount` 反映
- ステータス: 未実装（基本/拡張）

---

## ユーザー体験を伸ばすおすすめ実装（優先度順）
1. トレードのサーバ権威化と整合性（P2P取引の完成度向上）
   - 対象: `TradeManagerComponent.cpp`, `TradeServerManager.cpp`
   - 追加: 所有/数量/ロック検証、アトミック決済、ロールバック、監査ログ
2. メール添付の受領フロー完成
   - 対象: `MailboxComponent.cpp` の受領・サーバ通信・インベントリ反映
3. パーティのサーバサイド実装
   - 対象: `PartyComponent.cpp` の `Server*` 実装、検証・通知・永続化
4. 銀行特典（ポイント還元/金利補正）とUI演出
   - 対象: `BankSubsystem.cpp`、`BankWidgetBase.cpp`
5. GAS初期アビリティの自動ロード
   - 対象: `MMOAbilitySystemComponent::LoadDefaultAbilities`
6. マーケット（オークション）決済検証と購入フロー
   - 対象: `TradeServerManager.cpp` の `BuyAuction` 系
7. ギルド機能の要件確認→不足実装（倉庫入出庫/役職/イベント）

> 補足: フェーズA終盤で HUD（基本）を解放し、Gold/HP/MP/XP とトーストを可視化して体験価値を強化

---

## 参考（検出した TODO 抜粋と所在）
- `Source/MyTEST/Private/TradeManagerComponent.cpp`
  - `ShouldAutoTrade`: 在庫取得ロジック
  - サーバー通知/同期/承認/キャンセル/受け渡し 一連
- `Source/MyTEST/Private/TradeServerManager.cpp`
  - 所有/ロック/承認/決済/ロック解除/購入検証
- `Source/MyTEST/Private/MailboxComponent.cpp`
  - 添付受領の実処理、サーバー通信
- `Source/MyTEST/Private/PartyComponent.cpp`
  - 招待/脱退/キック/リーダー交代、初期データロード
- `Source/MyTEST/Private/BankSubsystem.cpp`
  - ポイント加算、金利補正
- `Source/MyTEST/Private/BankWidgetBase.cpp`
  - 取引ポップアップ、サウンド
- `Source/MyTEST/Private/MMOAbilitySystemComponent.cpp`
  - 既定アビリティのロード

---

## 次アクション提案
- まずは 1〜3 をまとめて「ユーザーが体験で明確に恩恵を感じる」領域として実装（取引成立、メール受領、パーティ運用）。
- 変更は `Source/MyTEST/Docs/Optimization_Priorities.md` と本ドキュメントに履歴追記。
