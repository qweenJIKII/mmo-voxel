# ユーザー体験系システム Godot 移植計画

更新: 2025-10-06
対象: `g:/Unreal Projects/MyTEST` → `res://` (Godot MMO Voxel)

---

## サマリ
- Godot 移植ロードマップ（`Docs/Project_Implementation_Plan.md` と整合）
  - **Phase 2 (オープンワールド基礎)**: HUD/探索系の最小 UI、ギャザリング基盤のセットアップ
  - **Phase 3 (ゲームプレイ & 経済)**: インベントリ、クエスト、銀行、メール、パーティ、チャット、能力システム、ギャザリング、P2P トレードの PoC
  - **Phase 4 (運用拡張)**: マーケット/オークション、銀行ポイント特典、ギルド機能拡張、監査・ログの強化
- 2025-10-06 時点の Godot 実装は Phase 0（基盤整備）のみ進行中。下記機能はすべて **未着手** であり、Unreal 実装を参照しつつ段階的に移植する。
- 移植は「**UI/UX**→**サーバ権威/DB 連携**→**リッチ機能**」の順に段階化し、各フェーズでプレイヤー体験に寄与する機能が揃うようにする

## Godot 移植ロードマップ（機能別）
| 機能 | Godot 移植フェーズ | Godot 現状 (2025-10-06) | 依存 | メモ |
|------|--------------------|-------------------------|------|------|
| インベントリ/装備 | Phase 3 前半 | 未着手 | ネットワーク同期、SQLite | Godot UI (`ui/inventory/`) とボクセル採掘報酬の連携 |
| クエスト | Phase 3 中盤 | 未着手 | Inventory、NetworkClient | `QuestJournal` を Godot UI で再構築 |
| ガチャ | Phase 3 後半 | 未着手 | Inventory、銀行 | `RandomLootService` を GDScript/GDExtension 化 |
| 銀行 | Phase 3 後半 / Phase 4 前半 | 未着手 | SQLite、Logger、UI | ポイント還元・演出を Phase 4 で補完 |
| トレード (P2P) | Phase 3 後半 | 未着手 | Inventory、NetworkClient | Phase 4 でマーケットへ発展 |
| マーケット/オークション | Phase 4 | 未着手 | トレード、銀行 | Godot UI + サーバ authoritative 決済 |
| メール | Phase 3 前半 | 未着手 | Inventory、Logger | 個別受領と HUD 連携を Godot で完結 |
| パーティ | Phase 3 中盤 | 未着手 | NetworkClient、HUD | 招待/リーダー交代 RPC を ENet で再設計 |
| チャット | Phase 3 前半 | 未着手 | NetworkClient | Godot UI とログ保存を統合 |
| ギルド | Phase 4 | 未着手 | NetworkClient、DB | 先に要件洗い出し、倉庫/イベント優先 |
| 能力システム (GAS) | Phase 3 中盤 | 未着手 | PlayerStats、HUD | `AdaptiveVoxelSolver` と連携するステータス更新 |
| ギャザリング/採集 | Phase 2 後半 / Phase 3 前半 | 未着手 | VoxelSubsystem | 採掘ループで検証 |
| プレイヤー HUD | Phase 2 後半 | 未着手 | Inventory、Ability | Godot UI でコンパス/トースト追加 |

---

## 詳細（機能別）

### 1) インベントリ/装備
- 実装根拠:
  - `Source/MyTEST/Public/InventoryComponent.h`
  - `Source/MyTEST/Private/InventoryComponent.cpp`
  - `Source/MyTEST/Public/InventoryWidget.h` 他 UMG 一式
- 所見: 主要操作/UMGは実装済み。TODOの顕著な欠落なし。
- Unreal ステータス: 実装済み
- Godot 現状: 未着手（Phase 3 前半で移植予定）
- Godot 移植計画: Phase 3 前半で GDScript 製 `InventoryService` と `ui/inventory/InventoryPanel.tscn` を実装し、`AdaptiveVoxelSubsystem` からのドロップを永続化。

### 2) クエスト
- 実装根拠:
  - `Source/MyTEST/Public/QuestComponent.h`
  - `Source/MyTEST/Private/QuestComponent.cpp`
  - `Source/MyTEST/Public/QuestJournalWidget.h`
- 所見: `QuestComponent` と UI が揃っており、未実装TODOの顕著な検出なし。
- Unreal ステータス: 実装済み
- Godot 現状: 未着手（Phase 3 中盤で移植予定）
- Godot 移植計画: Phase 3 中盤で `QuestSubsystem` (autoload) を追加。SQLite `quests` テーブルを用意し、HUD 通知を `ui/hud/QuestToast.tscn` で行う。

### 3) ガチャ
- 実装根拠:
  - `Source/MyTEST/Public/GachaSystem.h`
  - `Source/MyTEST/Private/GachaSystem.cpp`
  - `Source/MyTEST/Public/GachaRewardManager.h`
- 所見: 実装/生成物が存在。未実装TODOの顕著な検出なし。
- Unreal ステータス: 実装済み
- Godot 現状: 未着手（Phase 3 後半で移植予定）
- Godot 移植計画: Phase 3 後半。`RandomLootService` を GDExtension で実装し、`ui/gacha/GachaPanel.tscn` を開発。銀行 API と連携してリソース消費/付与を管理。

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
- Unreal ステータス: 部分実装（基幹は可、特典/演出が未完）
- Godot 現状: 未着手（Phase 3 後半〜Phase 4 前半で移植予定）
- Godot 移植計画: Phase 3 で基幹（入出金、履歴、バックアップ）を移植。ポイント還元・演出は Phase 4 で `ui/bank/` に実装し、`Logger` へ監査出力を追加。

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
- Unreal ステータス: 部分実装（クライアント側の流れは概形、サーバ権威・整合性が未完）
- Godot 現状: 未着手（Phase 3 後半で PoC、Phase 4 でマーケット拡張予定）
- Godot 移植計画: Phase 3 後半で P2P トレード RPC を ENet ベースで PoC。Phase 4 でオークションロジックを `TradeServer.gd` に集約し、整合性/監査を強化。

### 6) メール（添付/受領）
- 実装根拠:
  - `Source/MyTEST/Public/MailboxComponent.h`, `Private/MailboxComponent.cpp`
- 現状/要対応:
  - 一括受領のサーバ権威RPC導線: 実装済（`Server_ClaimAllAttachments` → `UMailDAO::ClaimAll` → `Client_OnClaimAllCompleted`）。UI通知: `OnMailUpdated`/`OnMailClaimAllCompleted`
  - 個別ID受領: 未実装（次フェーズで `Server_ClaimAttachmentById` + DAO 単体Claimを設計）
  - UI/HUD連携: 未接続（受領ボタンを `ClaimAllAttachmentsForCurrentPlayer()` にバインド、完了トースト表示）
  - レプリケーション注意: Owning Actor の `bReplicates=true` 必須。`UMailboxComponent` は既定で Replicate。`BeginPlay` で未設定時は警告ログ
- Unreal ステータス: 部分実装（サーバ権威の一括受領とUI通知導線は実装済、UI/HUD接続は未着手）
- Godot 現状: 未着手（Phase 3 前半で移植予定）
- Godot 移植計画: Phase 3 前半で `MailService` (autoload) を作成し、個別添付受領と HUD トーストを追加。`InventoryService` と整合させる。

### 7) パーティ
- 実装根拠:
  - `Source/MyTEST/Public/PartyComponent.h`, `Private/PartyComponent.cpp`
- 未実装/要対応:
  - サーバー権威の招待/脱退/キック/リーダー交代: `ServerInviteToParty_Implementation` など一連が `// TODO`
  - 初期データロード: `LoadDefaultPartyData`: `// TODO`
- Unreal ステータス: 部分実装（RPCの中身未実装）
- Godot 現状: 未着手（Phase 3 中盤で移植予定）
- Godot 移植計画: Phase 3 中盤。`PartyService` を ENet RPC で実装し、`AdaptiveVoxelSubsystem` の興味領域共有に活用。HUD でメンバーリストを表示。

### 8) チャット
- 実装根拠:
  - `Source/MyTEST/Public/ChatComponent.h`
- 所見: 具体的な TODO は検出されず。詳細動作は別途確認が必要。
- Unreal ステータス: 実装済み（仮）
- Godot 現状: 未着手（Phase 3 前半で移植予定）
- Godot 移植計画: Phase 3 前半。`ChatService` を WebSocket/ENet RPC で構築し、`ui/chat/ChatPanel.tscn` を追加。ログは `Logger` へ JSONL で保存。

### 9) ギルド
- 実装根拠:
  - `Source/MyTEST/Public/GuildEventManager.h`, `GuildEventTypes.h`, `GuildWarehouse.h`
- 所見: `Guild*.cpp` に顕著な TODO は検出されず。操作系（倉庫入出庫、役職、イベント処理）の有無は未確認。
- Unreal ステータス: 要確認（未実装の可能性あり）
- Godot 現状: 未着手（Phase 4 で要件定義から開始）
- Godot 移植計画: Phase 4 で要件定義→実装。優先度は倉庫入出庫とイベント管理。SDL の `GuildWarehouse` ロジックを GDScript に順次移植。

### 10) 能力システム（GAS拡張）
- 実装根拠:
  - `Source/MyTEST/Public/MMOAbilitySystemComponent.h`, `Private/MMOAbilitySystemComponent.cpp`
- 未実装/要対応:
  - 既定アビリティのロード: `LoadDefaultAbilities`: `// TODO`
- Unreal ステータス: 部分実装
- Godot 現状: 未着手（Phase 3 中盤で移植予定）
- Godot 移植計画: Phase 3 中盤。`AbilitySystem` (GDExtension) を `AdaptiveVoxelSolver` と連携し、プレイヤー/ギルドバフを HUD に反映。既定アビリティロード処理を優先。

### 11) ギャザリング/採集
- 実装根拠:
  - `Source/MyTEST/Public/GatherComponent.h`
  - `Source/MyTEST/Private/GatherComponent.cpp`
  - `Source/MyTEST/Public/IAutoGatherable.h`
- 所見: 主要機能は実装済み。該当ファイルに顕著な TODO は検出されず。
- Unreal ステータス: 実装済み
- Godot 現状: 未着手（Phase 2 後半で統合予定）
- Godot 移植計画: Phase 2 後半でボクセル採掘ループと統合し、Phase 3 で報酬テーブルを `InventoryService` に接続。

### 12) プレイヤーステータス/HUD
- 実装根拠:
  - （新規UI。HUD系 Blueprint/Widget を追加予定）
- 所見: 基本HUDは未記載。GAS/Party/Inventory の整合に依存。
- 依存: Inventory/Equipment のレプリ/デリゲート、`MMOAbilitySystemComponent::LoadDefaultAbilities`（最小）、`mail.ClaimAll` による Gold の `inventory.amount` 反映
- Unreal ステータス: 未実装（基本/拡張）
- Godot 現状: 未着手（Phase 2 後半でモック構築予定）
- Godot 移植計画: Phase 2 後半で HUD モック (`ui/hud/MainHUD.tscn`) を構築し、Phase 3 でクエスト/メール通知と統合。

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
