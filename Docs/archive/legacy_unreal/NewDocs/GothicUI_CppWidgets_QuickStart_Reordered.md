# GothicUI C++ Widgets QuickStart *(Phase 0〜Phase 1)*

本書は `Source/MyMMO/Public/UI/Gothic/` に追加したカスタム C++ ウィジェット群を導入するためのクイックスタートです。`UI_Recommended_Composition_GothicUI.md` との対応やフェーズ順を明示しており、段階的にUIを組み上げられます。

- 依存関係: `UMG`, `Slate`, `SlateCore`
- 親クラス: WBP 作成時に `UGothic*` クラスを指定
- BindWidget: 子ウィジェット名を C++ と一致させる
- 素材: `Content/GothicUI/UIelements/`, `Content/GothicUI/UIicons/`

---

## Phase 0: 基盤 UI / ツール

### スタイル DataAsset 運用ガイド（共通） *(Phase 0)*
- **作成手順**
  1. `Content/UI/Styles/` などに `UGothicWidgetStyles` 系 DataAsset を作成。
  2. `Normal/Hovered/Pressed/Disabled` テクスチャや `Tint` を設定。
  3. `UGothicInventorySlotStyleData` などでは `bAlwaysShowQuantity` 等も調整。
- **ウィジェット側設定**
  - `UGothicIconButton` / `UGothicProgressBar` / `UGothicActionSlot` / `UGothicInventorySlotWidget` / `UGothicNineSliceFrame` は `AutoStyleAsset` 対応済み。
  - DataAsset を割り当てると `NativePreConstruct()` などで自動適用。
  - ランタイム変更は `ApplyStyleAsset()` を呼ぶ。
- **チェックリスト**
  - `DisabledTint` が想定通りに反映されるか。
  - `SetPercent()` の後にプログレスのフィルが更新されるか。
  - Inventory数表示や Nine-Slice のレイアウト崩れが無いか。
- **Tips**: テクスチャ差し替え後の `ApplyStyleAsset()` 再呼び出し、命名規則など。

#### ワイヤーフレーム
```text
ボタンStyle: 「ーーNormalーー」/「ーーHoverーー」/「ーーPressーー」
プログレスStyle:
  背景 「ーーーーーーーーーー」
  充填 「ーーーーーー」
```

#### DataAsset 階層
```text
UGothicButtonStyleData
├─ Normal / Hovered / Pressed / Disabled (UTexture2D)
├─ ContentPadding: FMargin
├─ IconTint: FLinearColor
└─ TextColor: FLinearColor

UGothicProgressBarStyleData
├─ Background: UTexture2D
├─ Fill: UTexture2D
└─ FillTint: FLinearColor
```

---

### GothicChatWidgetBase（最小チャット） *(Phase 0)*
- クラス: `UGothicChatWidgetBase`
- BindWidget: `LogScroll`, `LogText`, `InputBox`, `SendButton`
- API: `AppendSystem`, `AppendSay`, `ClearLog`, `FocusInput`, `OnSubmit`
- Screen設定: Custom（例: 560x320）
- スタイル連携: `UGothicTextEntryStyleData`（入力欄）, `UGothicButtonStyleData`（送信ボタン）

```text
「ーーーーーーーーーーーーーーーーーーーーーーーーーー」 ← LogScroll
 I [System] ...                                        I
 I [Say] ....                                          I
「ーーーーーーーーーーーーーーーーーーーーーーーーーー」
「ーーーーーーーーーーーーーー」I「ーー送信ーー」
         入力(InputBox)          I   ボタン
```

```text
UGothicChatWidgetBase
├─ LogScroll: UScrollBox
│  └─ LogText: URichTextBlock
├─ InputRow: (任意コンテナ)
│  ├─ InputBox
│  └─ SendButton
└─ (OnSubmit)
```

---

### GothicMailWidgetBase（最小メール） *(Phase 0)*
- クラス: `UGothicMailWidgetBase` / `UGothicMailListEntry`
- BindWidget: `MailList`, `DetailText`, `ReceiveButton`, `DeleteButton`
- Screen設定: Custom（例: 920x520）
- スタイル連携: `UGothicNineSliceFrameStyleData`（ウィンドウ枠）, `UGothicButtonStyleData`（操作ボタン）

```text
「ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー」
 I  「ーー一覧(Scroll)ーー」  I  「ーー詳細(Text)ーーーーーーーー」 I
 I  [メール項目...]          I  件名/本文...                 I
「ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー」
「ーー受領ーー」 I 「ーー削除ーー」
```

```text
UGothicMailWidgetBase
├─ MailList: UScrollBox
│  └─ UGothicMailListEntry[xN]
├─ DetailText: UTextBlock
├─ ReceiveButton / DeleteButton: UButton
```

---

## Phase 0.5: 基本ウィジェット & 装備連携

### 1. GothicIconButton（アイコン+テキストボタン） *(Phase 0.5)*
- クラス: `UGothicIconButton`
- BindWidget: `Button`, `Icon`, `Label`
- API: `SetText`, `SetIcon`, `SetBackgroundTextures`, `OnClicked`
- Screen設定: Desired on Screen
- スタイル連携: `UGothicButtonStyleData`

```text
「ーーIconーー」Iーーー Label ーーーI
```

```text
UGothicIconButton
└─ Button
   ├─ Icon
   └─ Label
```

---

### 2. GothicProgressBar（背景/フィルバー） *(Phase 0.5)*
- クラス: `UGothicProgressBar`
- BindWidget: `Background`, `FillSizeBox`, `Fill`
- Screen設定: Desired on Screen（例: HP 420x32）
- スタイル連携: `UGothicProgressBarStyleData`

```text
「ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー」 背景
「ーーーーーーーーーーーーーー」 フィル
```

```text
UGothicProgressBar
├─ Background: UImage
├─ FillSizeBox -> Fill
└─ （コードで Percent 適用）
```

---

### 3. GothicInventorySlotWidget（インベントリスロット） *(Phase 0.5)*
- クラス: `UGothicInventorySlotWidget`
- BindWidget: `BgImage`, `IconImage`, `QuantityText`, `ClickCatcher`
- Screen設定: Desired on Screen（64x64）
- スタイル連携: `UGothicInventorySlotStyleData`

```text
┌──┬──┬──┬──┬──┬──┬──┬──┐
│  │  │  │  │  │  │  │  │
├──┼──┼──┼──┼──┼──┼──┼──┤
│  │  │  │  │  │  │  │  │
├──┼──┼──┼──┼──┼──┼──┼──┤
│  │  │  │  │  │  │  │  │
├──┼──┼──┼──┼──┼──┼──┼──┤
│  │  │  │  │  │  │  │  │
├──┼──┼──┼──┼──┼──┼──┼──┤
│  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┘
```

```text
UGothicInventorySlotWidget
├─ BgImage
├─ IconImage
├─ QuantityText
└─ ClickCatcher (optional)
```

---

### 4. GothicActionSlot（アイコン+クールダウン） *(Phase 0.5)*
- クラス: `UGothicActionSlot`
- BindWidget: `Base`, `Icon`, `CooldownMask`, `KeyText`
- Screen設定: Desired on Screen（64x64）
- スタイル連携: `UGothicActionSlotStyleData`

```text
「ーーーーーー」
 I  Icon   I
「ーーーーーー」
 Key: 1 / Cooldown 99%
```

```text
UGothicActionSlot
├─ Base
├─ Icon
├─ CooldownMask
└─ KeyText
```

---

### 5. GothicCircularCooldownOverlay（円形クールダウン） *(Phase 0.5)*
- クラス: `UGothicCircularCooldownOverlay`
- BindWidget: `Overlay`
- Screen設定: Desired on Screen（親スロットと同サイズ）
- スタイル連携: 円形マテリアル (`T_*/M_GothicCircularCooldown`) ※専用 DataAsset 未定義

```text
「ーーー」
  ／ ←Progressに応じた扇形
「ーーー」
```

```text
UGothicCircularCooldownOverlay
└─ Overlay: UImage (円形マテリアル)
```

---

### 6. GothicNineSliceFrame（Nine-Slice枠） *(Phase 0.5)*
- クラス: `UGothicNineSliceFrame`
- BindWidget: `FrameImage`
- Screen設定: Custom / Desired on Screen
- スタイル連携: `UGothicNineSliceFrameStyleData`

```text
「ーーーーーーーーーーーーーー"
 I         content          I
「ーーーーーーーーーーーーーー"
```

```text
UGothicNineSliceFrame
└─ FrameImage (DrawAs=Box)
```

---

### 7. NotificationManagerComponent（トースト通知） *(Phase 0.5)*
- クラス: `UNotificationManagerComponent`
- API: `PushNotification`, `UpdateNotification`, `ClearNotification`, `ClearByCategory`
- Screen設定: HUDサイドパネルなど
- スタイル連携: UI側 `UGothicEdgeNotificationStyleData`（要作成）

---

### 8. DBQueryManagerComponent（SQLite デバッグ） *(Phase 0.5)*
- クラス: `UDBQueryManagerComponent`
- API: `ExecutePreset`, `ExecuteQueryString`
- 用途: DB 管理ツール、`Task-DBLog-02` と連携
- スタイル連携: コンソール UI は `UGothicDebugConsoleStyleData` を参照

---

### 9. LogCaptureComponent（ログ収集&フィルタ） *(Phase 0.5)*
- クラス: `ULogCaptureComponent`
- API: `StartCapture`, `StopCapture`, `SetVerbosityFilter`, `SetCategoryEnabled`
- スタイル連携: `UGothicDebugConsoleStyleData`（ログリスト/フィルタ UI）

---

### 10. GothicDebugConsole（デバッグUIベース） *(Phase 0.5)*
- クラス: `UGothicDebugConsole`
- 概要: `UDBQueryManagerComponent`/`ULogCaptureComponent` を自動バインド
- Blueprintイベント: `OnDebugComponentsBound`, `OnLogEntriesUpdated` など
- スタイル連携: `UGothicDebugConsoleStyleData`（フレーム/タブ/入力域）

---

### 11. GothicCurrencySelector（通貨選択 + 残高表示） *(Phase 0.5)*
- クラス: `UGothicCurrencySelector`
- BindWidget: `CurrencyCombo`, `BalanceText`
- 用途: 通貨システムサポート
- スタイル連携: `UGothicComboBoxStyleData`（要追加）, `UGothicTextBlockStyleData`（要追加）

---

### 12. GothicPlayerStatusListWidget（属性一覧） *(Phase 0.5)*
- クラス: `UGothicPlayerStatusListWidget`
- API: `SetAttributeComponent`
- スタイル連携: リスト項目用 `UGothicListItemStyleData`（推奨）

---

### 13. GothicPlayerInfoWidget（プレイヤー情報） *(Phase 0.5)*
- クラス: `UGothicPlayerInfoWidget`
- API: `SetPlayerDisplayName`, `BindAttributeComponent`
- スタイル連携: 子 `UGothicPlayerStatusListWidget` と同じく `UGothicListItemStyleData`、タイトルは `UGothicTextBlockStyleData`（要追加）

---

## Phase 1: 垂直スライス要素

### 6. MinimapComponent（SceneCaptureミニマップ） *(Phase 1)*
- クラス: `UMinimapComponent`
- API: `SetFocusActor`, `RegisterMarker`, `CycleZoom`, `GetMinimapRenderTarget`

---

### 7. GothicSkillBarRPG（ページングスキルバー） *(Phase 1)*
- クラス: `UGothicSkillBarRPG`
- API: `SetGridSize`, `SetPages`, `NextPage`, `PrevPage`
- スタイル連携: スロットに `UGothicActionSlotStyleData`、インジケータ用 `UGothicTextBlockStyleData`（要追加）

---

### 8. GothicWidgetStyles（DataAsset で共通スタイル） *(Phase 0)*
-（Phase 0 で説明済みのため省略）

---

### 9. GothicChatWidgetBase（最小チャット） *(Phase 0)*
-（Phase 0 で説明済みのため省略）

---

### 10. GothicMailWidgetBase（最小メール） *(Phase 0)*
-（Phase 0 で説明済みのため省略）

---

### 13. サンプル: スキルバーのページデータ作成（C++） *(Phase 1)*
```cpp
TArray<FActionPage> Pages;
Pages.SetNum(2);
for (int32 p = 0; p < Pages.Num(); ++p)
{
    Pages[p].Slots.SetNum(10);
    for (int32 i = 0; i < 10; ++i)
    {
        FActionSlotData Data;
        Data.Icon = LoadObject<UTexture2D>(nullptr, TEXT("/Game/GothicUI/UIicons/T_Spell_Fireball.T_Spell_Fireball"));
        Data.KeyText = FText::FromString(FString::Printf(TEXT("%d"), i+1));
        Data.bEnabled = true;
        Data.CooldownDuration = 10.f;
        Data.CooldownRemaining = (p == 0 && i <*>
