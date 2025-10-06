# MyMMO 開発ロードマップ - Phase 0（機能未実装からの出発）

更新日: 2025-09-20（改訂: 現行プロジェクトに合わせてスキーマ/進捗/参照ドキュメントを更新）
対象プロジェクト: `g:/Unreal Projects/MyMMO`
関連ドキュメント: 
- `Docs/Zero_Budget_Dev_Operations_Guide.md`
- `Docs/Gameplay_Feature_Status.md`（実装状況の横断確認）
- `Docs/BindWidgetSpecifications.md`（UIの BindWidget 名規約）

---

## プロジェクト現状と目標

### 現状
- **機能実装状況**: 
  - 基本HUD（イベント駆動・ポーリング停止）
  - ログインフロー（AuthSubsystem + LoginWidget）実装、ログイン後にのみロード実行
  - MainHUD は HUDPresenter が生成/解決（LoginWidget は HUD を生成しない運用に統一）
  - インベントリ可視化UI（InventoryDebugWidget）＋RPC（ServerAddItem/Save/Load/SetFixedPlayerId）
  - UIOpenComponent: 複数UI名管理 + カーソル強制制御フラグ（bAlwaysControlCursorOnShow/Hide）追加済
  - MyUIBlueprintLibrary: UI操作/取得に加え、マウスカーソル表示/非表示/トグルAPIを提供
- **開発環境**: UE5プロジェクトの基本構造 + SQLite/Logging/Auth（GameInstanceSubsystem）/Economy（OnRep）基盤あり
- **予算**: ゼロ予算での開発を前提

### Phase 0 の目標
- ローカル環境でのMMO基盤構築
- 最小限のゲームプレイループの実現
- 将来のスケールアップに向けた基盤整備

---

## Phase 0: ローカル完結構成（ゼロコスト開発）

### ステップ1: 基盤システムの構築

#### 1.1 データ永続化（SQLite）
**優先度: 最高**

**ステータス: 実装済** — `USQLiteSubsystem` が初期化・スキーマ保証・バックアップ機能を提供し、プロジェクト内で稼働中。

```cpp
// 実装対象ファイル
Source/MyMMO/Public/SQLiteSubsystem.h
Source/MyMMO/Private/SQLiteSubsystem.cpp
```

**必要な実装:**
- SQLiteデータベースの初期化
- 基本テーブルスキーマの作成
- バックアップ機能（3世代ローテーション）

**最小スキーマ（Phase 0）:**（現行実装に準拠。インベントリはスロット制、`slot_index` 主キー）
```sql
-- プレイヤー基本情報
CREATE TABLE IF NOT EXISTS players (
  player_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  level INTEGER NOT NULL DEFAULT 1,
  experience INTEGER NOT NULL DEFAULT 0,
  gold INTEGER NOT NULL DEFAULT 100,
  created_at INTEGER NOT NULL,
  last_login INTEGER NOT NULL
);

-- インベントリ
CREATE TABLE IF NOT EXISTS inventory (
  player_id TEXT NOT NULL,
  slot_index INTEGER NOT NULL,
  item_id TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  meta_json TEXT DEFAULT '{}',
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (player_id, slot_index)
);

-- メール（基本機能）
CREATE TABLE IF NOT EXISTS mail (
  mail_id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  attachments_json TEXT NOT NULL DEFAULT '[]',
  expire_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  claimed INTEGER NOT NULL DEFAULT 0
);
```

#### 1.2 ローカル専用サーバー起動
**優先度: 高**

**ステータス: 実装済** — `Config/DefaultEngine.ini` に `MaxPlayers` / `IpNetDriver` 設定済み。`Scripts/Run-MyMMOServer.ps1` ほか起動スクリプトで運用可能。

```cpp
// 実装対象
Config/DefaultEngine.ini の設定調整
起動スクリプトの作成
```

**設定例:**
```ini
[/Script/Engine.GameSession]
MaxPlayers=10

[/Script/OnlineSubsystemUtils.IpNetDriver]
NetConnectionClassName="OnlineSubsystemUtils.IpConnection"
```

**起動コマンド（開発用）:**
```bash
# Windows PowerShell
MyMMOEditor.exe -server -log -PORT=7777 -UNATTENDED -NOSTEAM
```

#### 1.3 基本ログシステム
**優先度: 中**

**ステータス: 実装済** — `ULoggingSubsystem` が構造化ログ出力・メトリクス収集・ローテーション/バックアップを実装済み。

```cpp
// 実装対象
Source/MyMMO/Public/LoggingSubsystem.h
Source/MyMMO/Private/LoggingSubsystem.cpp
```

**機能:**
- 構造化ログ（JSON Lines形式）
- 1日ローテーション
- 基本メトリクス収集

---

### ステップ2: コアゲームプレイ機能

#### 2.1 プレイヤーシステム（更新）
**優先度: 最高**

**ステータス: 実装済** — `UAuthSubsystem`/`AMMOPlayerState`/`UPlayerEconomyComponent` が連携し、ログイン〜属性同期〜UI更新フローが稼働。

```cpp
// 実装対象（現状）
Source/MyMMO/Public/Subsystems/PlayerAuthSubsystem.h
Source/MyMMO/Private/Subsystems/PlayerAuthSubsystem.cpp
Source/MyMMO/Public/MMOPlayerState.h
Source/MyMMO/Private/MMOPlayerState.cpp
Source/MyMMO/Public/Gameplay/PlayerEconomyComponent.h
Source/MyMMO/Private/Gameplay/PlayerEconomyComponent.cpp
```

**実装内容（現状）:**
- 認証は `UAuthSubsystem`（GameInstanceSubsystem）に集約（SQLite/Logging 使用）。`ULoginWidget` から `Login/Logout` を呼び出し
- ログイン成功時に `OnLoggedIn(PlayerId)` → 各システムが購読（例: `UInventoryComponent` が `inventory_Load()` 実行・AutoSave開始）
- `AMMOPlayerState` は `ReplicatedUsing` で OnRep 駆動し `UAttributeComponent` を常設。`MMOAttributeIds` に基づき HP/MP/スタミナ/攻撃力/魔力/防御/耐性/クリティカル系を初期化・同期
- HUD では `UHUDPresenterComponent::UpdateOnce()` が属性コンポーネントを検出して `UGothicPlayerInfoWidget` / `UGothicPlayerStatusListWidget` にバインドし、`OnAttributeChanged` でリアルタイム更新
- `UPlayerEconomyComponent` は Gold を OnRep で HUD に反映し、通貨UI (`UGothicCurrencySelector`) に委譲
- セーブ: 定期オートセーブ（既定120秒）＋変更デバウンス（3秒）＋終了時保存
- ロード: ログイン後のみ実行（起動直後の競合を回避）。開発用の手動ロードはUIに残すが本番では非表示推奨
- プレイヤーコントローラはデフォルト `APlayerController` を使用（PCに初期UI=Loginを集約）

#### 2.2 インベントリシステム
**優先度: 最高**

**ステータス: 一部実装** — `UInventoryComponent` と `UInventoryWidget` は稼働。UI拡張（ドラッグ&ドロップ等）は未着手、デバッグUI中心。

```cpp
// 実装対象
Source/MyMMO/Public/InventoryComponent.h
Source/MyMMO/Private/InventoryComponent.cpp
Source/MyMMO/Public/InventoryWidget.h
Source/MyMMO/Private/InventoryWidget.cpp
```

**実装内容:**
- アイテム追加/削除/移動
- UI表示とインタラクション
- サーバー権威での同期

#### 2.3 基本UI/HUD（更新）
**優先度: 高**

```cpp
// 実装対象（UMG Blueprint + C++）
Content/UI/HUD/BP_MainHUD.uasset  // 親クラス: UMainHUDWidget
Source/MyMMO/Public/MainHUDWidget.h
Source/MyMMO/Private/MainHUDWidget.cpp
Source/MyMMO/Public/UI/HUDPresenterComponent.h
Source/MyMMO/Private/UI/HUDPresenterComponent.cpp
```

**表示要素/仕様（現状）:**
- プレイヤーステータス（HP/MP/Level）は `AMMOPlayerState` のイベント（OnRep/デリゲート）で即時更新（ポーリング停止）
- 通貨（Gold）は `UPlayerEconomyComponent::OnRep_Gold` で HUD に即時反映
- インベントリボタンは `UIOpenComponent` と連携しトグル（名前運用に統一）
- 初期通貨は `InitialCurrencyIds`（例: ["GOLD"]）、`DefaultCurrencyId="GOLD"`
- MainHUD は `UHUDPresenterComponent.HUDClass=BP_MainHUD` で解決/生成（LoginWidgetはHUDを生成しない）

補足（更新）:
- `UUIOpenComponent`: 複数UI（名前管理）+ カーソル強制制御フラグ `bAlwaysControlCursorOnShow/Hide`
- `UHUDPresenterComponent`: `HUDClass` 設定でHUDを解決/生成。`InventoryUIName`/`InitialUIMap` により名前トグル運用
- `UMyUIBlueprintLibrary`: UI取得/操作に加え、`SetMouseCursorVisible/ToggleMouseCursor/IsMouseCursorVisible` を提供

**BindWidget 名（BP_MainHUD 側）:**
- `HpText`, `MpText`, `LevelText`, `GoldText`, `CurrencySelector`, `InventoryButton`

**備考:**
- HUDは `HUDPresenterComponent.HUDClass=BP_MainHUD` から自動探索。見つからない場合は自動生成し `AddToViewport(10)`
- CommonUI 警告は無視可能だが、無効化する場合は `DefaultEngine.ini` の `[SystemSettings]` に `CommonUI.Debug.CheckGameViewportClientValid=0` を追加

#### 2.4 AdaptiveVoxel準備タスク（新規）
**優先度: 中（Phase 0後半で着手）**

**ステータス: 未着手** — 装備データ拡張・イベントルータPoCは今後の着手予定。

関連ドキュメント: `AdaptiveVoxel_System_TaskPlan.md`

**目的:** Phase 1以降の動的ボクセル導入に備え、装備・インベントリ・イベントルータの下地を整える。

- **[Task-AV-Equip-01]** 装備データモデルの整理（剣/つるはし等カテゴリ、耐久/属性）。
- **[Task-AV-Equip-02]** `UAdaptiveVoxelEventRouter` PoC（攻撃/採掘イベント→ボクセルリクエスト）
- **[Task-AV-Equip-03]** `UInventoryComponent` 連携下準備（素材ID定義、耐久消耗フラグ）
- **[成果物]** 装備連動仕様書ドラフト、PoCログ、テストケース概要

チェックリスト:
- [ ] 装備データテーブルに耐久・属性カラムを追加（仮値可）
- [ ] 攻撃ヒットイベントからイベントルータに渡るパイプラインを確認
- [ ] インベントリUIで採集素材を仮取得できるデバッグボタンを用意

---

#### 2.4 プレイヤーキャラクター（移動/カメラ/所持HUD連携）
**ステータス: 不要（UE5標準キャラクターを使用）**

```cpp
// 実装対象
Source/MyMMO/Public/MMOCharacter.h
Source/MyMMO/Private/MMOCharacter.cpp
// 推奨: 3人称テンプレ相当の構成（SpringArm + FollowCamera）
```

備考:
- 本プロジェクトでは UE5 標準の ThirdPersonCharacter を流用するため、独自 `AMMOCharacter` 実装は現時点では不要です。

**チェックリスト（N/A）:**
- [n/a] `BP_MMOCharacter` を作成し、メッシュ/アニメ（仮で可）を設定
- [n/a] `BP_MMOGameMode` の `DefaultPawnClass` を `BP_MMOCharacter` に設定
- [n/a] WASD/マウス/Space で移動・視点・ジャンプが動作
- [n/a] 既存HUD（HP/MP/Level/通貨）が表示され、インベントリ開閉が可能

---

### ステップ3: 通信・社交機能

#### 3.1 チャットシステム
**優先度: 高**

```cpp
// 実装対象
Source/MyMMO/Public/ChatComponent.h
Source/MyMMO/Private/ChatComponent.cpp
Source/MyMMO/Public/ChatWidget.h
Source/MyMMO/Private/ChatWidget.cpp
```

**機能:**
- 全体チャット
- ローカルチャット
- システムメッセージ

#### 3.2 メールシステム（基本）
**優先度: 中**

```cpp
// 実装対象
Source/MyMMO/Public/MailboxComponent.h
Source/MyMMO/Private/MailboxComponent.cpp
Source/MyMMO/Public/MailWidget.h
Source/MyMMO/Private/MailWidget.cpp
```

**機能:**
- メール送受信
- アイテム添付（基本）
- 一括受領

現状（更新）:
- DBスキーマは作成済（`mail` テーブル）。`USQLiteSubsystem` に最小APIを追加済み：
  - `GetMailsRaw(PlayerId, ...)`, `MarkMailClaimed(PlayerId, MailId)`, `CreateMail(...)`
- `MailboxComponent.h` を追加（`FetchMails/ClaimMail/ClaimAll` 宣言）。`MailboxComponent.cpp` は未実装。
- 依存追加: `Json/JsonUtilities`（添付JSONの将来処理を見据え）

---

## 開発手順とチェックリスト

### Week 1-2: 基盤構築
- [x] SQLiteSubsystem実装
- [x] 基本テーブル作成
- [x] ローカルサーバー起動確認
- [x] ログシステム基本実装

### Week 3-4: プレイヤーシステム
- [x] PlayerAuthSubsystem/PlayerState 実装（SQLite/Logging 連携）
- [x] 認証システム（ローカル）
- [x] セーブ機構（定期/イベント/終了時）とロード（認証時）
- [x] 基本HUD実装（イベント駆動・ポーリング停止）
- [n/a] プレイヤーキャラクター（移動/カメラ/所持HUD連携） — UE5標準キャラクターを使用

### Week 5-6: インベントリ
- [x] InventoryComponent実装
- [x] インベントリUI作成（枠・表示は仮実装、ドラッグ&ドロップ/数量UIは未）
- [x] アイテム操作機能（追加/削除/移動の基本機能は実装済、拡張機能は未）
- [ ] サーバー同期テスト（継続的な自動テスト整備が必要）
- [ ] **[Task-AV-Equip-01]** 装備データモデル拡張（耐久/属性フィールド）

---

## 付録A: 入力アーキテクチャ（Phase 0の暫定仕様）

- Enhanced Input は一旦停止。MMO向けの独自入力（旧 Input の直接バインド）に統一。
  - `AMMOPlayerController.bUseEnhancedInput = false`（デフォルト）
  - キー設定（クラスデフォルトで変更可）
    - `ToggleInventoryKey`（既定: I）→ `ToggleInventoryUI()`
    - `CloseInventoryKey`（既定: BackSpace）→ `CloseInventoryUI()`
    - `ShowCursorKey`（既定: LeftControl）→ 押下中カーソル表示、離すと状態復帰
- UI/フォーカス方針
  - 起動直後: `GameAndUI` + カーソル表示 + `MainHUD` フォーカス
  - インベントリ表示: `GameAndUI` + `InventoryWidget` フォーカス
  - インベントリ非表示: `GameAndUI` + `MainHUD` フォーカス
  - Z順: HUD=10、Inventory=5。Inventory 可視時は `SelfHitTestInvisible` を使用（非活性領域はクリック貫通）
  - 名称運用: Iキー/HUDボタンともに `ToggleUIByName("Inventory")` を使用（Defaultエントリ非推奨）

### Week 7-8: 通信機能
- [ ] チャットシステム実装
- [ ] メールシステム基本機能
- [ ] マルチプレイヤーテスト

---

## テスト・検証手順

### ローカルテスト（更新）
1. **単体テスト**
   ```bash
   # エディタコンソールでのテストコマンド例
   sqlite.EnsureSchema
   sqlite.SelfTest
   player.Create TestPlayer01
   inv.Add TestPlayer01 wood 10
   ```

2. **認証/セーブ/ロードの確認**
   - 実運用フロー（UI）
     1) 起動 → `Login` 画面で `PlayerId` 入力 → `Login` or `Create and Login`
     2) ログイン成功 → `HUDPresenter` が MainHUD を解決/生成、`UInventoryComponent` が自動ロード
     3) `InventoryDebugWidget` から `AddItem/Save/Load/SetPlayerId`（開発用）
   - コンソール（開発）
     ```bash
     mmo.DBEnsure
     mmo.Login DevUser01
     mmo.Save
     mmo.Load
     ```

3. **エディタ限定 自動ログイン（任意）**
   - `Config/DefaultEngine.ini`
     ```ini
     [ConsoleVariables]
     mmo.AutoLoginEnable=1
     mmo.AutoLoginName=DevUser01
     ```
   - PIE開始時に自動ログイン。成功時は画面右上にトースト表示

### オートメーション（Editor Automation）
- 在庫永続化の自動テストを追加済み: `MyMMO.Inventory.Server.SaveLoad`
- 実行手順・詳細は `Docs/NewDocs/Inventory_Server_Test.md` の「6) Automation」を参照

2. **マルチプレイヤーテスト**
   - エディタから「専用サーバーで再生」
   - 複数クライアント接続テスト
   - データ同期確認

### パフォーマンステスト
- 同時接続数: 目標5-10人
- メモリ使用量監視
- CPU使用率確認

---

## 運用・監視

### ログ収集
```json
// 構造化ログ例
{
  "timestamp": "2025-09-15T07:17:14Z",
  "level": "INFO",
  "category": "inventory",
  "message": "item added",
  "player_id": "TestPlayer01",
  "item_id": "wood",
  "amount": 10
}
```

### メトリクス
- 接続プレイヤー数
- アイテム操作頻度
- チャットメッセージ数
- エラー発生率

### バックアップ
- SQLiteファイルの自動バックアップ（起動/終了時）
- 3世代ローテーション
- 手動バックアップコマンド提供

---

## 次フェーズへの準備

### Phase 1移行条件
- [ ] 基本機能の安定動作確認
- [ ] 5人以上での継続テスト成功
- [ ] パフォーマンス目標達成
- [ ] ログ・監視システム稼働

### Phase 1予定機能
- VPS導入（月$5程度）
- PostgreSQL移行
- より高度な社交機能
- 経済システム拡張

---

## 付録: Gameplay Feature 取り込み計画（参考: `Docs/Gameplay_Feature_Status.md`）

本プロジェクト（MyMMO）における取り込み方針。MyTEST 由来の機能群を段階的に移植/再実装する。

### A) 即時適用/準用（Phase 0/1）
- インベントリ/装備: 既存 `UInventoryComponent` を拡張して装備スロットを追加（BindWidget命名は `BindWidgetSpecifications.md` 準拠）
  - ステータス: インベントリ=実装済 / 装備=未着手
- チャット（最小）: `ChatComponent` + `ChatWidget` をHUDから起動
  - ステータス: 未着手（Phase 0 内で最小実装）
- メール（基本）: `MailboxComponent` + `MailWidget`（収納・受領・削除）
  - ステータス: 未着手（DBスキーマは作成済）

### B) Phase 1 以降の候補
- クエスト: `QuestComponent` + `QuestJournalWidget`
  - ステータス: 未着手
- 銀行（基幹）: `BankWidgetBase` + 口座操作（Deposit/Withdraw/History）
  - ステータス: 未着手（BindWidget 仕様あり）
- パーティ（基礎）: 招待/参加/離脱のサーバー権威処理
  - ステータス: 未着手
- カップリング/結婚: 相互承認・ペアバフ・共有ホーム（将来拡張）
  - ステータス: 未着手（最小: リクエスト/承認/解消、称号付与）
- GAS（基礎）: 初期アビリティロード、基本アクティブ/パッシブ
  - ステータス: 未着手
- ギャザリング/採集: ノード相互作用、取得テーブル
  - ステータス: 未着手
 - 領地/領域（許可制・関所）: プレイヤー所有エリア、侵入許可リスト、関所（ゲート）での通行制御
   - ステータス: 未着手（最小: 領域定義・オーナー/許可リスト・侵入可否チェック・ログ）
 - 扉/ドアの鍵（ロック・オートロック）: 鍵アイテム/アクセス権、一定時間で自動施錠
  - ステータス: 未着手（最小: ロック状態レプリ、解錠/施錠RPC、オートロックタイマー）
 - 通貨システム拡張（複数通貨）: 円/ドル等の法定通貨と金/銀/銅などのゲーム内通貨を併存、表示通貨の切替
   - ステータス: 未着手（最小: 通貨テーブル、所持残高テーブル、HUDの`CurrencySelector`/`GoldText`切替、SQLite保存）

### C) 後続（部分実装/検討課題）
- トレード（P2P）
- オークション/マーケット
- 銀行ポイント/特典
- メールUI連携/HUD同期（HUD統合の強化）
- パーティのサーバ権威処理の高度化
- レプリケーション最適化（可視化/Profiler連携）

### チェックリスト（追加）
- [ ] 装備スロットのDB/レプリ/UMG連携
- [ ] ChatComponent/ChatWidget（全体/ローカル）
- [ ] MailboxComponent/MailWidget（一覧/詳細/受領）
- [ ] QuestComponent/QuestJournalWidget（受注/完了の最小）
- [ ] BankWidgetBase（入出金/履歴/残高表示）
- [ ] Party（招待/参加/離脱）
- [ ] カップリング/結婚（申請/承認/解消、称号・ペアボーナスの最小）
- [ ] GAS（初期アビリティロード、基本アクション）
- [ ] 採集（ノード→インベントリ反映）
- [ ] レプリ最適化（ネット可視化と検証）
- [ ] 領地/領域（領域定義、許可リスト、関所通行チェック）
- [ ] 扉/ドアの鍵（ロック/解錠、オートロック、アクセス権）
- [ ] 通貨システム拡張（複数通貨・表示切替・SQLite保存）


## リスク管理

### 技術リスク
- **データ破損**: 毎日自動バックアップで対応
- **パフォーマンス**: 早期の負荷テストで検出
- **ネットワーク**: ローカル環境での十分な検証

### 開発リスク
- **スコープクリープ**: Phase 0の機能に厳格に制限
- **技術負債**: コードレビューとリファクタリングの定期実施
- **モチベーション**: 小さな成功を積み重ねる開発サイクル

---

## 参考コマンド

### 開発用コンソールコマンド
```bash
# データベース操作
sqlite.EnsureSchema
sqlite.BackupNow
sqlite.SelfTest

# 認証/セーブ/ロード（GameInstanceSubsystem 経由）
mmo.DBEnsure
mmo.DBStatus
mmo.Login <UserName>
mmo.Logout
mmo.Save
mmo.Load
# Editor only
mmo.AutoLoginNow [UserName]

# インベントリ操作
inv.Add <PlayerID> <ItemID> <Amount>
inv.Remove <PlayerID> <ItemID> <Amount>
inv.List <PlayerID>

# メール操作
mail.Send <PlayerID> <Subject> <Body> <ExpireSeconds>
mail.List <PlayerID>
mail.ClaimAll <PlayerID>
```

### サーバー起動スクリプト例
```bash
# start_server.bat
@echo off
echo Starting MyMMO Local Server...
MyMMOEditor.exe -server -log -PORT=7777 -UNATTENDED -NOSTEAM -logCmds="global off, category=Net verbosity=Log"
pause
```

---

## まとめ

このPhase 0では、最小限のコストで基本的なMMO機能を実装し、将来のスケールアップに向けた基盤を構築します。各ステップを段階的に進めることで、リスクを最小化しながら確実に目標を達成できます。

次回更新予定: Phase 0完了時（予定: 2025-11-15）

---

## GAS × Ninja Input 統合（Phase0・実装順対応）

本セクションでは、既存の Enhanced Input 資産（Input Action / Input Mapping Context）を継続利用しつつ、Ninja Input を導入して入力責務を分離し、GAS へ安全にルーティングします。段階移行で回帰ゼロを優先します。

### 共通準備
- Ninja Input 有効化（Epic Launcher または `Plugins/NinjaInput/` 配置 → `Edit -> Plugins`）
- プレイヤーBP/クラスに `Input Manager` コンポーネント追加
- 既存 `Input Mapping Context` を `Input Manager` から適用（UI/Gameplay の優先度を設定）
- マルチプレイ: `LocalPlayer` ごとにコンテキスト適用。UI時は UI コンテキスト優先でゲーム入力を抑制

> 備考: 現行は「付録A: 入力アーキテクチャ（Phase 0の暫定仕様）」にて旧Inputを暫定採用。Ninja Input への移行は以下の実装順で段階導入し、回帰を避けつつ置き換える。

### 実装順 1. 移動基礎（Move / Jump / Sprint）
- GAS:
  - Move は通常 Ability 不要（CharacterMovement 主導）
  - Sprint: `GA_Sprint`（Tag: `Ability.Movement.Sprint`）で開始/停止を標準化
  - Jump: 既存 `ACharacter::Jump/StopJumping` 維持 or `GA_Jump` へ移行
- Ninja Input:
  - `IA_Move`（Axis2D）/ `IA_Jump` / `IA_Sprint`
  - ハンドラ: Axis（Move）、Pressed/Held（Sprint）、Pressed（Jump）
  - GAS 連携: Sprint を Ability Activate/Cancel に紐付け
- 検証:
  - KB/M・Gamepad 双方で再現、UI 表示時はゲーム入力抑制

### 実装順 2. 回避/ダッシュ（Dodge / Dash）
- GAS: `GA_Dodge`（`Ability.Movement.Dodge`）、`GA_Dash`（`Ability.Movement.Dash`）に CD/Cost 設定
- Ninja Input: `IA_Dodge` / `IA_Dash` → Pressed Handler → `TryActivateAbilityByTag`
- 補足: 後段の「入力バッファ」と連動（アニメ遷移中の取りこぼし防止）

### 実装順 3. インタラクト（Interact / Pickup）
- GAS: `GA_Interact`（`Ability.Interact`）で対象への Gameplay Event/Interface を内包
- Ninja Input: `IA_Interact` → Pressed Handler → Ability 起動 or Gameplay Event 送出
- バリアント: 長押しが必要なら Held Handler に切替

### 実装順 4. 戦闘基礎（Light / Heavy / Ranged）
- GAS:
  - `GA_Attack_Light`（Tag: `Ability.Combat.Attack.Light`）
  - `GA_Attack_Heavy`（Tag: `Ability.Combat.Attack.Heavy`）
  - 遠隔: `GA_Ranged`（Tag: `Ability.Combat.Ranged`）
- Ninja Input:
  - `IA_Attack_Light` / `IA_Attack_Heavy` → Pressed/Repeat Handler
  - Ability 起動。モンタージュに合わせて入力バッファの受付窓を設定
- コンボ: 入力バッファで次入力の受付タイミングを制御

### 実装順 5. ターゲット/ロックオン（必要時）
- GAS: `GA_TargetLock`（Tag: `Ability.Combat.Target.Lock`）
- Ninja Input: `IA_TargetLock` → Toggle Handler → タグ/ステートへ反映
- UI: ロックオンインジケータ（Common UI/UMG）

### 実装順 6. Ability 発火の標準化（タグ駆動）
- GAS: 各 Ability にタグを付与（起動/キャンセル/制御の判定に利用）
- Ninja Input:
  - `TryActivateAbilityByTag` / `CancelAbilitiesWithTag`
  - `Gameplay Event` 使用時は `SendGameplayEventToActor`
- ポリシー: 入力→Ability 対応は「タグ」を唯一の真実に

### 実装順 7. 入力バッファ（アニメーション同期）
- 目的: モンタージュ/Notify Window と同期した受付窓で入力ロスト防止
- Ninja Input: 付属のアニメ連動入力バッファを有効化し、攻撃/回避の「次入力」受付を Window 内に限定
- GAS: タグ/クールダウン/コストの規則と整合

### 実装順 8. キーリマッピング（Common UI 連携）
- Ninja Input:
  - Project Settings でリマッピング有効化
  - 各 `Input Action` に Mappable 情報（表示名/カテゴリ）設定
  - Common UI 設定画面 → ViewModel → 保存/適用へパイプライン接続
- 保存: SaveGame / UserSettings に格納し、起動時適用
- UI 開閉でマッピングコンテキスト切替（UI > Gameplay）

### 実装順 9. ユーザー設定と Input Modifiers（感度・反転）
- Ninja Input:
  - User Settings: `MouseX/Y Sensitivity`, `Invert X/Y`, `Gamepad Sensitivity`
  - 対応 `Input Modifier` を IA に設定して実行時参照
- 反映: 即時 or 次回適用を要件に合わせる

### 実装順 10. マルチプレイ整合
- GAS: 権限/RPC/Replication を設計確認（Client → Server の起動要求の経路）
- Ninja Input: `LocalPlayer` 単位適用、ポゼッション切替時の再適用、UI 時の優先制御

### 検証チェックリスト（入力/GAS/Ninja Input）
- 入力再現性（KB/M・Gamepad）
- コンテキスト優先度（UI > Gameplay）
- GAS レイテンシ/タグ整合
- 入力バッファの受付/拒否が設計通り
- リマッピングの保存/読込/適用
- マルチプレイ各クライアントの独立性

### 注意（既知の整合性リスク）
- `InventoryComponent` の `FInventorySlot` フィールド名不整合（ヘッダ: `ItemId, Amount` / 実装: `ItemID, Quantity`）
  - インベントリ駆動アビリティ（消費/使用）を扱う前に修正推奨
  - 段階対応: 実装側をヘッダに合わせて置換 → 依存先修正 → マイグレーションテスト

---

## 次の作業（提案）

### Phase 0 — UI Quick Wins（優先実装）
- 【高】ProgressBar 数値オーバーレイ（HP/MP/XP）
  - `UGothicProgressBar` に数値テキストを追加（表示ON/OFF API）。Docs: QuickStart 2章に注記済み。
- 【高】ActionSlot クールダウン秒表示 + 無効化視覚化
  - `UGothicActionSlot` に `CooldownText` を追加し、残秒を表示。Disable 時の明示オーバーレイ。Docs: 4/5章に追記予定。
- 【高】ツールチップ標準化
  - `UGothicIconButton`/`UGothicActionSlot`/`UGothicInventorySlotWidget` に `SetToolTipText` 経路を用意。スタイルは DataAsset 連携。
- 【高】トースト通知スタック
  - HUD右上に `WBP_ToastStack`（最大5件/3s）。Docs: UI構成ガイド 7章に追記済み。

### Phase 0 — 体験強化（中規模）
- 【中】インベントリUX: ドラッグ&ドロップ/スタック分割/検索・フィルタ
  - `UGothicInventorySlotWidget` に D&D 実装、分割ダイアログ、検索バー。Docs: QuickStart 3章に操作ガイド追加。
- 【中】スキルバードラッグ入替/ページ名/ホットキー保存
  - `FActionPage` 拡張（`Slots` + `PageName`）。入力は SaveGame に保存。Docs: 7章更新。
- 【中】チャットのタブ化/タイムスタンプ/URLリンク
  - `UGothicChatWidgetBase` 拡張。Docs: 9章に仕様追記。
- 【中】メールの検索/ソート/一括受領
  - `UGothicMailWidgetBase` + `MailboxComponent`。Docs: 10章に追記。

### Phase 0 — 整合性/基盤
- 【高】Inventory スキーマ不整合の解消
  - `FInventorySlot` 実装側の `ItemID/Quantity` を `ItemId/Amount` に統一（Docs/コード整合）。
- 【中】入力/カーソルの統一
  - `ToggleMouseCursor()` のショートカット確定、`UUIOpenComponent` 既定調整。
- 【中】Login運用の一本化
  - HUDPresenter で一元管理。`UAuthSubsystem.OnLoggedIn` 連携を明文化。

### Phase 1 — 拡張候補（先行設計のみ）
- ミニマップ拡張（ズーム/マーカー/Ping）
- 複数通貨対応と残高アニメ
- アクセシビリティ（UIスケール/コントラストテーマ）
