# Gothic UI Style DataAsset Guide

## Overview
Gothic UI の各 C++ ウィジェットは、スタイル情報を `UGothic*StyleData` 系 DataAsset から読み込んで見た目を統一できます。本書では DataAsset の作成手順、推奨設定例、検証ポイントをまとめます。

---

## 1. DataAsset 作成フロー
1. **Content Browser で作成**
   1. `Content/UI/Styles/` など任意のフォルダを右クリック → `Miscellaneous` → `Data Asset`。
   2. クラス選択で目的の `UGothic*StyleData` を選ぶ（例: `UGothicActionSlotStyleData`）。
   3. ファイル名を入力（推奨: `DA_用途_テーマ` 形式。例: `DA_GothicActionSlot_Default`）。
2. **プロパティ編集**
   1. 作成した DataAsset を開く。
   2. テクスチャや色 (`FLinearColor`) を設定。ボタンでは `NormalPadding` / `PressedPadding`、インベントリでは `bAlwaysShowQuantity` など挙動系プロパティも調整。
3. **ウィジェットへの割り当て**
   1. 対象の WBP（親クラスが `UGothic*`）を開く。
   2. `Details` パネルで `AutoStyleAsset` に作成済み DataAsset を割り当て、`bAutoApplyStyleAsset` を `true` のままにする。
   3. ランタイムで差し替える場合は Blueprint / C++ から `ApplyStyleAsset()` を呼び出す。
4. **検証**
   1. Enabled/Disabled や Percent 更新など、ウィジェット特有の状態変化でスタイルが反映されるか確認。
   2. 必要に応じて `ApplyStyleAsset()` を再呼び出し、テクスチャ差し替えが即時反映されるかテスト。

---

## 2. 推奨 DataAsset と設定例
### 2.1 一覧

#### 2.1.1 `DA_GothicButton_Default` (`UGothicButtonStyleData`)
- **状態別テクスチャ**
  - `Normal`: `T_Button_medium`
  - `Hovered`: `T_button_on_2`
  - `Pressed`: `T_Button_long_4`
  - `Disabled`: `T_Button_medium`（グレイ化済テクスチャ）
- **余白**
  - `NormalPadding`: `8,4,8,4`
  - `PressedPadding`: `6,3,6,3`
- **色設定**
  - `IconTint`: `FLinearColor::White`
  - `TextColor`: `FLinearColor::White`

#### 2.1.2 `DA_GothicProgress_HP` (`UGothicProgressBarStyleData`)
- **テクスチャ**
  - `Background`: `T_HPbar_empty`
  - `Fill`: `T_HPbar_filled`
- **色設定**
  - `FillTint`: `RGBA(0.95,0.2,0.2,1)`

#### 2.1.3 `DA_GothicActionSlot_Default` (`UGothicActionSlotStyleData`)
- **ベース**
  - `BaseTexture`: `T_Icon_button_01`
  - `BaseTint`: `FLinearColor::White`
- **色設定**
  - `IconTint`: `FLinearColor::White`
  - `DisabledTint`: `RGBA(0.3,0.3,0.3,1)`
  - `KeyTextColor`: `FLinearColor::White`
  - `CooldownTextColor`: `RGBA(0.95,0.70,0.36,1)`
  - `CooldownMaskColor`: `RGBA(0,0,0,0.75)`

#### 2.1.4 `DA_GothicInventorySlot_Default` (`UGothicInventorySlotStyleData`)
- **ベース**
  - `BackgroundTexture`: `T_Inventory_icon_b_1`
  - `BackgroundTint`: `FLinearColor::White`
- **アイコン/数量**
  - `IconTint`: `FLinearColor::White`
  - `QuantityTextColor`: `FLinearColor::White`
  - `QuantityShadowColor`: `RGBA(0,0,0,0.6)`
- **表示設定**
  - `bAlwaysShowQuantity`: `false`

#### 2.1.5 `DA_GothicNineSlice_Window` (`UGothicNineSliceFrameStyleData`)
- **テクスチャ**
  - `Texture`: `T_NineSlice_Frame_01`
- **レイアウト**
  - `SliceMargin`: `12,12,12,12`
- **色設定**
  - `Tint`: `FLinearColor::White`

#### 2.1.6 `DA_GothicProgress_Stamina` (`UGothicProgressBarStyleData`)
- **テクスチャ**
  - `Background`: `T_HPbar_empty`（汎用背景）
  - `Fill`: `T_HPbar_filled`
- **色設定**
  - `FillTint`: `RGBA(0.25,0.85,0.45,1)`（スタミナ向けの緑）
- **備考**
  - `MMOAttributeIds::Stamina` / `MMOAttributeIds::MaxStamina` と連動。`UHUDPresenterComponent` が `UAttributeComponent` から現在値/最大値を読み取り HUD バーを更新。

#### 2.1.7 `DA_GothicProgress_Mana` (`UGothicProgressBarStyleData`)
- **テクスチャ**
  - `Background`: `T_HPbar_empty`
  - `Fill`: `T_MP_Line_blue`
- **色設定**
  - `FillTint`: `RGBA(0.2,0.35,0.95,1)`（マナ向けの青）
- **備考**
  - `MMOAttributeIds::Mana` と `MMOAttributeIds::Health` を区別するため色分け。HUD の `CurrencySelector` と同様に `UHUDPresenterComponent` が `OnAttributeChanged` 経由で更新。

#### 2.1.8 `DA_GothicProgress_Attack` (`UGothicProgressBarStyleData`)
- **テクスチャ**
  - `Background`: `T_HPbar_empty`
  - `Fill`: `T_XPbarLong_filled`
- **色設定**
  - `FillTint`: `RGBA(0.85,0.55,0.20,1)`（攻撃力可視化用）
- **備考**
  - `GothicPlayerStatusListWidget` 側で `MMOAttributeIds::AttackPower` をリスト表示する際、棒グラフ風のビジュアルに活用可能。

#### 2.1.9 `DA_GothicTextEntry_Default` (`UGothicTextEntryStyleData`)
- **外観**
  - `Background`: `T_Input_bg_dark`
  - `HoveredBackground`: `T_Input_bg_highlight`
- **テキスト**
  - `Font`: `GothicCaption` Size 16
  - `TextColor`: `RGBA(0.92,0.90,0.84,1)`
  - `PlaceholderColor`: `RGBA(0.72,0.72,0.72,0.65)`
- **カーソル/選択**
  - `CaretColor`: `RGBA(0.95,0.90,0.70,1)`
  - `SelectionColor`: `RGBA(0.95,0.80,0.35,0.35)`

#### 2.1.10 `DA_GothicComboBox_Default` (`UGothicComboBoxStyleData`)
- **ボタン**
  - `ButtonStyle`: `DA_GothicButton_Default`
- **リスト項目**
  - `ItemTextColor`: `RGBA(0.92,0.90,0.84,1)`
  - `HoveredItemBackground`: `RGBA(0.30,0.28,0.20,0.85)`
- **アイコン**
  - `ArrowTexture`: `T_ComboArrow_gold`

#### 2.1.11 `DA_GothicTextBlock_Primary` (`UGothicTextBlockStyleData`)
- **フォント**
  - `Font`: `GothicCaption` Bold Size 20
- **色設定**
  - `Color`: `RGBA(0.95,0.90,0.78,1)`
  - `ShadowColor`: `RGBA(0,0,0,0.6)`
  - `ShadowOffset`: `FVector2D(1,1)`
- **用途**
  - タイトル/見出し、通貨表示、スキルバーインジケータ

#### 2.1.12 `DA_GothicListItem_Default` (`UGothicListItemStyleData`)
- **背景**
  - `BackgroundEven`: `RGBA(0.12,0.12,0.16,1)`
  - `BackgroundOdd`: `RGBA(0.16,0.16,0.20,1)`
- **状態色**
  - `SelectedTint`: `RGBA(0.85,0.70,0.30,0.45)`
  - `HoveredTint`: `RGBA(0.65,0.55,0.28,0.35)`
- **テキスト**
  - `PrimaryTextColor`: `RGBA(0.90,0.88,0.80,1)`

#### 2.1.13 `DA_GothicEdgeNotification_Default` (`UGothicEdgeNotificationStyleData`)
- **フレーム**
  - `BackgroundTexture`: `T_Notification_panel`
  - `FrameTint`: `RGBA(0.20,0.16,0.10,0.92)`
- **アクセント**
  - `HighlightTexture`: `T_Edge_glow`
  - `HighlightColor`: `RGBA(0.95,0.80,0.35,0.55)`
- **テキスト**
  - `HeaderColor`: `RGBA(0.95,0.90,0.78,1)`
  - `BodyColor`: `RGBA(0.88,0.85,0.78,1)`

#### 2.1.14 `DA_GothicDebugConsole_Default` (`UGothicDebugConsoleStyleData`)
- **コンテナ**
  - `FrameTexture`: `T_PopUp_window_3`
  - `FrameTint`: `RGBA(0.08,0.08,0.12,0.92)`
- **タブ**
  - `TabButtonStyle`: `DA_GothicButton_Default`
  - `ActiveTabTint`: `RGBA(0.85,0.70,0.30,0.45)`
- **入力/ログ**
  - `TextEntryStyle`: `DA_GothicTextEntry_Default`
  - `ListItemStyle`: `DA_GothicListItem_Default`
- **備考**
  - Debug Console 全体の統一テーマとして利用。`UGothicDebugConsole` の `AutoStyleAsset` に割り当てる。

### 2.2 `WBP_DebugConsole` 推奨スタイル
- **フレーム (`UGothicNineSliceFrameStyleData`)**
  - `Texture`: `T_PopUp_window_3`
  - `SliceMargin`: `32,32,32,32`
  - `Tint`: `RGBA(0.08,0.08,0.12,0.92)`
- **タブボタン (`UGothicButtonStyleData`)**
  - `Normal`: `T_Button_medium_3`
  - `Hovered`: `T_button_on_2`
  - `Pressed`: `T_Button_long_4`
  - `Disabled`: `T_Button_medium`
  - `TextColor`: `RGBA(0.94,0.90,0.78,1)`
- **プリセット/ログ行 (`UGothicListItemStyleData`)**
  - `BackgroundEven`: `RGBA(0.12,0.12,0.16,1)`
  - `BackgroundOdd`: `RGBA(0.16,0.16,0.20,1)`
  - `SelectedTint`: `RGBA(0.85,0.70,0.30,0.45)`
- **アクションボタン (`UGothicIconButton`)**
  - `IconTexture`: `T_Button_plus_yellow`
  - `BackgroundTint`: `RGBA(0.25,0.22,0.12,0.95)`
  - `HoveredTint`: `RGBA(0.40,0.35,0.18,0.95)`
- **入力フィールド (`UGothicTextEntryStyleData`)**
  - `Background`: `T_Input_bg_dark`
  - `CaretColor`: `RGBA(0.95,0.90,0.70,1)`
  - `SelectionColor`: `RGBA(0.95,0.80,0.35,0.35)`
- **運用メモ**
  - `UGothicDebugConsole` の `AutoStyleAsset` に本 DataAsset を指定し、タブ切替・ログ行描画で統一感を持たせる。
  - Verbosity バッジは `GothicCaption` フォント（Size 14）、背景に `T_Shadow_Line_Dark` を薄く敷くと見やすい。

### 2.3 バリエーション例
- **職業別テーマ**: `DA_GothicActionSlot_Mage`, `DA_GothicActionSlot_Warrior` などを用意し、`ApplyStyleAsset()` で切り替える。
- **シーズンイベント**: `DA_GothicInventorySlot_Halloween` など季節限定の DataAsset を作り、イベント期間中に `AutoStyleAsset` を差し替える。

---

## 3. 検証チェックリスト
- **ボタン/アクションスロット**: Enabled/Disabled 切り替えで `DisabledTint` が反映されるか。
- **プログレスバー**: `SetPercent()` 実行後にフィル幅と `FillTint` が更新されるか。
- **インベントリスロット**: `SetSlotData()` による数量変更、`bAlwaysShowQuantity` の効果が確認できるか。
- **Nine-Slice フレーム**: `SliceMargin` を変更した際に枠が崩れず、`Tint` が全体に適用されるか。

---

## 4. 運用のコツ
- **共通テーマの活用**: 複数の WBP で同じ DataAsset を使うと、テーマ変更時のメンテナンスコストを抑えられる。
- **ランタイム更新**: DataAsset の値を変更した直後に `ApplyStyleAsset()` を再呼び出せば、再ロード無しで見た目を即座に更新できる。
- **命名規約**: `DA_カテゴリ_テーマ` 形式にすることで、目的の DataAsset を素早く検索可能。
- **バージョン管理**: `.uasset` をリポジトリに追加し、変更内容が UI 全体に及ぶ場合はチーム内で共有・レビューする。

---

## 5. MCP 経由での UI 自動構築フロー

- **対象 MCP サーバー**: `unrealMCP`
- **前提条件**
  - Unreal Editor で `MyMMO` プロジェクトを開いておく。
  - 追加対象の Widget Blueprint パスと親クラス（例: `UGothicIconButton`）を決定。
  - 使用するスタイル DataAsset (`UGothic*StyleData`) を作成済み、またはロード可能なパスを把握。

### 5.1 主要コマンド一覧
- `mcp8_create_umg_widget_blueprint`
  - UMG Widget Blueprint を新規作成。
  - パラメータ例: `widget_name="WBP_GothicHUD"`, `parent_class="UserWidget"`, `path="/Game/UI"`
- `mcp8_add_button_to_widget`
  - ボタンウィジェットを追加。位置・サイズ・テキスト・色を指定可能。
- `mcp8_add_text_block_to_widget`
  - テキストブロックを追加。フォントや色を指定。
- `mcp8_add_component_to_blueprint`
  - 既存 Blueprint にコンポーネントを追加（Nine-Slice 等のカスタムウィジェットを想定）。
- `mcp8_bind_widget_event`
  - 追加したボタンの `OnClicked` などを関数へバインド。
- `mcp8_compile_blueprint`
  - 生成した Blueprint をコンパイル。

### 5.2 実行シーケンス例
1. `mcp8_create_umg_widget_blueprint` でベース Widget を作成。
2. キャンバスに必要な要素を `mcp8_add_button_to_widget` / `mcp8_add_text_block_to_widget` 等で追加。
3. スタイル DataAsset を参照させるため、`UGothicIconButton` など `AutoStyleAsset` 対応クラスに適切なデフォルト値を設定。
4. `mcp8_bind_widget_event` でインタラクションを組み込む。
5. `mcp8_compile_blueprint` を実行し、Editor 上でプレビュー。

---

## 6. Next Actions（MCP 実行準備）
- **[要素整理]** UI に必要な部品（ボタン、プログレスバー、リスト等）と割り当てる `UGothic*StyleData` を一覧化。
- **[コマンド準備]** 各部品追加に対応する MCP コマンドを決定し、パラメータ（`position`, `size`, `text`, `color` 等）を事前に定義。
- **[実行]** Unreal Editor 起動中に MCP コマンドを順次実行し、Widget Blueprint を構築。
- **[検証]** 生成された Blueprint を Editor で開き、スタイル適用と動作を確認。必要があれば `ApplyStyleAsset()` を呼び出して最終調整。

### 6.1 UI 要素とスタイル DataAsset 対応表

| UI ウィジェット | 主な用途 | 割り当てる DataAsset | 主要スタイル項目 | 推奨 MCP 操作 |
| --- | --- | --- | --- | --- |
| `UGothicIconButton` | アイコン付きボタン | `UGothicButtonStyleData` | `Normal/Hovered/Pressed/Disabled`、`NormalPadding`、`IconTint`、`TextColor` | `mcp8_add_button_to_widget` → 配置後に `AutoStyleAsset` を設定 |
| `UGothicProgressBar` | HP/MP/スタミナバー | `UGothicProgressBarStyleData` | `Background`、`Fill`、`FillTint` | `mcp8_add_component_to_blueprint`（自作ラッパー）またはカスタム Widget を `Slot` に追加 |
| `UGothicActionSlot` | スキルスロット | `UGothicActionSlotStyleData` | `BaseTexture`、`BaseTint`、`CooldownMaskColor`、`KeyTextColor` | `mcp8_add_component_to_blueprint` で子ウィジェットとして追加 |
| `UGothicInventorySlotWidget` | インベントリスロット | `UGothicInventorySlotStyleData` | `BackgroundTexture`、`IconTint`、`QuantityTextColor`、`bAlwaysShowQuantity` | グリッドに複数追加する場合は `mcp8_add_component_to_blueprint` で `UniformGridPanel` 等と併用 |
| `UGothicNineSliceFrame` | ウィンドウ枠 | `UGothicNineSliceFrameStyleData` | `Texture`、`SliceMargin`、`Tint` | `mcp8_add_component_to_blueprint` でキャンバスに配置 |
| `UGothicTextEntryStyleData` を用いる `UGothicTextEntry` 系 | テキスト入力欄 | `UGothicTextEntryStyleData` | `Background`、`HoveredBackground`、`Font`、`TextColor`、`CaretColor` | `mcp8_add_component_to_blueprint` で `UGothicTextEntry` を追加、`AutoStyleAsset` 設定 |
| `UGothicComboBoxStyleData` を用いる `UGothicCurrencySelector` 等 | ドロップダウン選択 | `UGothicComboBoxStyleData` | `ButtonStyle`、`ItemTextColor`、`HoveredItemBackground`、`ArrowTexture` | `mcp8_add_component_to_blueprint` でコンボボックスを配置し、Style DataAsset を割り当て |
| `UGothicTextBlock` 系 | 見出し・ラベル | `UGothicTextBlockStyleData` | `Font`、`Color`、`ShadowColor`、`ShadowOffset` | `mcp8_add_text_block_to_widget` で追加後、Style 適用処理を追加 |
| `UGothicListItem` 系（`UGothicPlayerStatusListWidget` など） | リスト行 | `UGothicListItemStyleData` | `BackgroundEven/Odd`、`SelectedTint`、`HoveredTint`、`PrimaryTextColor` | `mcp8_add_component_to_blueprint` で `ListView` / `ScrollBox` と組み合わせ |
| `UGothicEdgeNotification` | 画面端トースト | `UGothicEdgeNotificationStyleData` | `BackgroundTexture`、`FrameTint`、`HighlightTexture`、`HeaderColor` | `mcp8_add_component_to_blueprint` で通知ウィジェットを追加 |
| `UGothicDebugConsole` | デバッグコンソール | `UGothicDebugConsoleStyleData` | `FrameTexture`、`TabButtonStyle`、`TextEntryStyle`、`ListItemStyle` | `mcp8_add_component_to_blueprint` で HUD に追加し、`AutoStyleAsset` を設定 |

> **メモ**: MCP からスタイルを割り当てる際は、ウィジェットに `AutoStyleAsset` または `ApplyStyleAsset()` を呼び出すノードを配置する。必要に応じて `mcp8_add_blueprint_function_node` で `ApplyStyleAsset` 呼び出しをイベントグラフへ追加する。

### 6.2 UI 要素別パラメータ（サンプル）

| UI ウィジェット | `position` (X,Y) | `size` (W,H) | 表示テキスト/備考 | `AutoStyleAsset` 引用パス |
| --- | --- | --- | --- | --- |
| `UGothicIconButton` (メインアクション) | (160, 520) | (220, 64) | テキスト: "Act"、アイコンは `T_Button_plus_yellow` | `/Game/UI/Styles/DA_GothicButton_Default.DA_GothicButton_Default` |
| `UGothicProgressBar` (HPバー) | (80, 640) | (420, 32) | `Percent` 初期値 1.0 | `/Game/UI/Styles/DA_GothicProgress_HP.DA_GothicProgress_HP` |
| `UGothicProgressBar` (MPバー) | (80, 684) | (420, 32) | `Percent` 初期値 0.75 | `/Game/UI/Styles/DA_GothicProgress_Mana.DA_GothicProgress_Mana` |
| `UGothicActionSlot` (スロット1) | (620, 640) | (64, 64) | `KeyText`: "1" | `/Game/UI/Styles/DA_GothicActionSlot_Default.DA_GothicActionSlot_Default` |
| `UGothicInventorySlotWidget` (インベントリ見出し) | (820, 360) | (64, 64) | `QuantityText`: "15" | `/Game/UI/Styles/DA_GothicInventorySlot_Default.DA_GothicInventorySlot_Default` |
| `UGothicNineSliceFrame` (ステータス枠) | (40, 600) | (520, 140) | `Tint`: 既定 | `/Game/UI/Styles/DA_GothicNineSlice_Window.DA_GothicNineSlice_Window` |
| `UGothicTextEntry` (チャット入力) | (60, 760) | (520, 56) | `HintText`: "Say..." | `/Game/UI/Styles/DA_GothicTextEntry_Default.DA_GothicTextEntry_Default` |
| `UGothicCurrencySelector` | (640, 480) | (240, 48) | `DefaultLabel`: "Gold" | `/Game/UI/Styles/DA_GothicComboBox_Default.DA_GothicComboBox_Default` |
| `UGothicTextBlock` (画面タイトル) | (40, 40) | Auto | テキスト: "Gothic HUD" | `/Game/UI/Styles/DA_GothicTextBlock_Primary.DA_GothicTextBlock_Primary` |
| `UGothicPlayerStatusListWidget` | (840, 440) | (280, 220) | 属性リストを動的生成 | `/Game/UI/Styles/DA_GothicListItem_Default.DA_GothicListItem_Default` |
| `UGothicEdgeNotification` | (1560, 140) | (320, 160) | `Header`: "Quest" | `/Game/UI/Styles/DA_GothicEdgeNotification_Default.DA_GothicEdgeNotification_Default` |
| `UGothicDebugConsole` | (1120, 560) | (640, 320) | `bIsVisible` 初期値 false | `/Game/UI/Styles/DA_GothicDebugConsole_Default.DA_GothicDebugConsole_Default` |

> **補足**: 実際のレイアウトに合わせて座標・サイズは調整してください。`position` は Canvas Panel を基準とした値を想定しています。

### 6.3 MCP コマンド例

```json
{
  "widget_name": "WBP_GothicHUD",
  "path": "/Game/UI",
  "parent_class": "UserWidget"
}
```

- **新規作成**
  - `mcp8_create_umg_widget_blueprint` を上記パラメータで呼び出す。
- **ボタン追加**
  ```json
  {
    "widget_name": "WBP_GothicHUD",
    "button_name": "MainActionButton",
    "text": "Act",
    "position": [160, 520],
    "size": [220, 64],
    "font_size": 20,
    "color": [0.95, 0.90, 0.78, 1.0],
    "background_color": [0.25, 0.22, 0.12, 0.95]
  }
  ```
  - 実行後、`AutoStyleAsset` を設定するため `mcp8_add_blueprint_function_node` で `ApplyStyleAsset` を呼び出すノードを `Event PreConstruct` に追加。
- **テキスト追加**
  ```json
  {
    "widget_name": "WBP_GothicHUD",
    "text_block_name": "TitleText",
    "text": "Gothic HUD",
    "position": [40, 40],
    "size": [400, 60],
    "font_size": 32,
    "color": [0.95, 0.90, 0.78, 1.0]
  }
  ```
- **スタイル適用ノード追加**
  ```json
  {
    "blueprint_name": "WBP_GothicHUD",
    "target": "MainActionButton",
    "function_name": "ApplyStyleAsset",
    "params": "{}"
  }
  ```
- **コンポーネント追加例 (`UGothicProgressBar`)**
  ```json
  {
    "blueprint_name": "WBP_GothicHUD",
    "component_type": "Widget",
    "component_name": "HPBar",
    "location": [80, 640, 0],
    "component_properties": {
      "WidgetClass": "/Game/UI/Widgets/WBP_GothicProgressBar.WBP_GothicProgressBar"
    }
  }
  ```

> **注意**: MCP コマンドの JSON 例は概念的なものです。実際の実行時には `Cascade` の MCP 実行 UI に応じた入力形式に合わせてください。必要に応じて `mcp8_bind_widget_event` でイベントハンドラを追加し、`mcp8_compile_blueprint` で Blueprint をコンパイルします。
*** End of File
