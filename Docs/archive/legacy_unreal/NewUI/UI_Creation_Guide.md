# MyMMO UI 作成ガイド

更新日: 2025-09-16
対象プロジェクト: `g:/Unreal Projects/MyMMO`

---

## 目的
本ガイドは、MyMMO における HUD および各種 UI（Inventory など）を、統一的な命名・接続ルールで素早く実装するための手順をまとめたものです。

---

## 参照ドキュメント
- `Docs/BindWidgetSpecifications.md`（BindWidget 名の規約、最重要）
- `Docs/NewDocs/Development_Roadmap_Phase0.md`（UI の到達要件と優先順位）
- `Docs/NewDocs/Inventory_Server_Test.md`（自動テストの実行）

---

## 基本方針
- UMG（Widget Blueprint）は C++ の `UUserWidget` 派生クラスを親にして作る
- Blueprint 側のウィジェット名は必ず BindWidget 名規約に従う
- PlayerController が HUD を生成・表示し、ゲーム中の UI 管理を行う
- レプリ値（HP/MP/Level など）は PlayerState → HUD へ通知して表示更新
- 操作系（インベントリ開閉など）は HUD → Controller → Widget の順に連携

---

## 1) HUD（MainHUD）作成手順

1. Blueprint を作成
   - パス: `Content/UI/HUD/`
   - 名前例: `BP_MainHUD`
   - Parent Class: `UMainHUDWidget`（C++）

2. ウィジェットを配置（BindWidget 名規約に一致させる）
   - `HpText`（TextBlock）
   - `MpText`（TextBlock）
   - `LevelText`（TextBlock）
   - `GoldText`（TextBlock）: 現在選択中の通貨の金額を表示（名称は互換のため GoldText を使用）
   - `CurrencySelector`（ComboBoxString）: 通貨選択（円/ドル/金/銀/銅 など）
   - `InventoryButton`（Button）

3. 動作確認
   - `AMMOPlayerController` の `MainHUDClass` に `BP_MainHUD` を割り当て
   - PIE 実行 → HUD が表示され、HP/MP/Level/通貨が更新されることを確認

---

## 2) インベントリ UI 作成手順

1. Blueprint を作成
   - パス: `Content/UI/Inventory/`
   - 名前例: `BP_InventoryWidget`
   - Parent Class: `UUserWidget`（後で `UInventoryWidget` C++ を親に差し替え可）

2. ウィジェットを配置（例）
   - `ItemGridPanel`（UniformGridPanel）
   - `GoldText`（TextBlock）
   - `SearchBox`（EditableTextBox）
   - `ItemScrollBox`（ScrollBox）
   - 詳細: `BindWidgetSpecifications.md` の Inventory セクション参照

3. 表示/開閉
   - HUD の `InventoryButton` → Controller で `InventoryWidget` をトグル表示
   - UI モード切替（必要時）: `SetInputModeUIOnly` / `SetInputModeGameOnly`

---

## 3) 通貨選択（マルチ通貨）

- HUD `CurrencySelector` の選択変更で、表示通貨を切替
- 現状: 表示金額は PlayerController の `CurrentGold` を反映
- 将来拡張（DB 連動）:
  - `currencies(currency_id, display_name, type)`
  - `player_currencies(player_id, currency_id, amount)`
  - `USQLiteSubsystem` に `GetCurrencyBalance/SetCurrencyBalance` を追加して HUD を更新

---

## 4) C++ 側の接続ポイント

- `Source/MyMMO/Public/MainHUDWidget.h` / `Private/MainHUDWidget.cpp`
  - `UpdateStats(HP, MaxHP, MP, MaxMP, Level)`
  - `SetupCurrencies(CurrencyIds, DefaultId)`
  - `UpdateCurrencyAmount(Amount)`
  - イベント: `OnInventoryButtonClicked`, `OnCurrencyChanged`

- `Source/MyMMO/Public/MMOPlayerController.h` / `Private/MMOPlayerController.cpp`
  - `MainHUDClass`, `MainHUD` のプロパティ
  - `BeginPlay()` で HUD を生成/表示、通貨をセットアップ
  - `UpdateHUDFromState()` で HUD の表示を更新
  - HUD イベントハンドラ: `OnHUDInventoryClicked()`, `OnHUDCurrencyChanged(const FString&)`

---

## 5) 命名規約（重要）

- BindWidget 名は `Docs/BindWidgetSpecifications.md` に定義済み
- 名称を変更せず、そのまま Blueprint に配置することで、C++ の `UPROPERTY(meta=(BindWidget))` がバインドされる
- オプション要素は `BindWidgetOptional` を使用（互換性維持）

---

## 6) デバッグ/トラブルシュート

- HUD が表示されない
  - `MainHUDClass` が未設定 → `AMMOPlayerController` のデフォルト/ブループリントで `BP_MainHUD` を割り当て
- BindWidget が `None`
  - Blueprint 内のウィジェット名が規約と一致していない可能性。名前を確認
- 通貨の表示が更新されない
  - `OnCurrencyChanged` のイベントがバインドされているか確認
  - （DB 連動時）`GetCurrencyBalance` の戻り値で `UpdateCurrencyAmount` を呼び出す

---

## 7) チェックリスト

- [ ] `BP_MainHUD` を作成し、BindWidget 名が一致している
- [ ] `MainHUDClass` が `AMMOPlayerController` に設定済み
- [ ] PIE 実行で HP/MP/Level/通貨が表示される
- [ ] `InventoryButton` でインベントリを開閉できる
- [ ] `CurrencySelector` で通貨が切り替わる

---

## 8) 今後の拡張

- InventoryWidget のドラッグ&ドロップ、数量表示、サーバー権威操作
- `player_currencies` と HUD のデータバインド
- HUD からチャットウィジェット起動、トースト/ローディング表示
- オートメーションテスト `MyMMO.UI.HUD.InventorySmoke` の追加

---

## 9) 入力アーキテクチャ（現状）

- 現在は Enhanced Input を停止し、MMO 向けの独自入力（旧 Input の直接バインド）に一本化
  - `AMMOPlayerController.bUseEnhancedInput = false`（デフォルト）
  - キーはクラスデフォルトで変更可能
    - `ToggleInventoryKey`（既定: I）→ `ToggleInventoryUI()`
    - `CloseInventoryKey`（既定: BackSpace）→ `CloseInventoryUI()`
    - `ShowCursorKey`（既定: LeftControl）→ 押下中カーソル表示、離すと状態復帰
- UI/フォーカス方針
  - 起動直後: `GameAndUI` + カーソル表示 + `MainHUD` にフォーカス
  - インベントリ表示: `GameAndUI` + カーソル表示 + `InventoryWidget` にフォーカス
  - インベントリ非表示: `GameAndUI` + カーソル表示 + `MainHUD` にフォーカス
  - Z オーダー: HUD=10、Inventory=5（HUD ボタンを常に押下可能）
  - Visibility: Inventory 可視時は `SelfHitTestInvisible` を使用（非活性領域はクリック貫通）

### 将来、Enhanced Input に戻す場合
- `AMMOPlayerController.bUseEnhancedInput = true` に変更
- プロジェクトで IMC/IA を用意し、どちらかを採用
  - クラスデフォルトに `InventoryIMC` / `IA_Toggle_Inventory` / `IA_Close_Inventory` / `IA_ShowCursor` を割当
  - もしくは BP ノード `BP_EnsureInventoryInput(IMC, IA_Toggle, IA_Close, Priority)` を BeginPlay で呼ぶ（推奨 Priority=100）

---

## 10) トラブルシュート（入力/フォーカス）

- キーが効かない（独自入力モード）
  - Output Log に「`[MMO] SetupInputComponent: Custom input mode enabled ...`」があるか
  - `ToggleInventoryKey/CloseInventoryKey/ShowCursorKey` の設定値を確認
  - デフォルトから変更した場合は、重複している他のショートカットがないか確認

- HUD ボタンが効かない
  - HUD の Z=10、Inventory の Z=5 になっているか
  - Inventory 可視時の Visibility が `SelfHitTestInvisible` になっているか
  - 非表示へ遷移時に `MainHUD` にフォーカスが戻っているか（Controller 側で明示設定）

- 連打で開閉が不安定
  - `ToggleInventoryUI()` に 0.15 秒のデバウンスあり
  - Output Log で「`ToggleInventoryUI: input received`」の回数と `Visible/Collapsed` の整合を確認

- カーソル操作
  - Ctrl 押下中に表示、離すと状態に応じて復帰（Inventory 可視なら表示維持、非表示なら非表示）

---

## 11) 実装リファレンス

- `Source/MyMMO/Public|Private/MainHUDWidget.*`
  - `OnInventoryButtonClicked` を Controller が購読
  - ボタン側では入力モード変更や Remove は行わない（開閉は Controller に集約）

- `Source/MyMMO/Public|Private/MMOPlayerController.*`
  - 独自入力モード切替: `bUseEnhancedInput`（false で旧 Input のみに）
  - キー設定: `ToggleInventoryKey` / `CloseInventoryKey` / `ShowCursorKey`
  - 表示時: `GameAndUI` + `InventoryWidget` フォーカス
  - 非表示時: `GameAndUI` + `MainHUD` フォーカス
  - 起動時: `GameAndUI` + `MainHUD` フォーカス + カーソル表示
  - Inventory の Z=5、HUD の Z=10、Inventory 可視時は `SelfHitTestInvisible`

