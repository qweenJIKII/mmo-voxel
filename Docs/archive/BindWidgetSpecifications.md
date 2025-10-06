# BindWidget名仕様書

## 概要
各ウィジェットで使用する`BindWidget`属性の名前を統一的に定義します。これにより、Blueprintでのバインディングが簡単になります。

## 命名規則
- **キャメルケース**を使用
- **機能を表す名前**を使用
- **冗長な接尾辞は避ける**

## 銀行ウィジェット (BankWidgetBase)

### ヘッダーエリア
```cpp
UPROPERTY(meta = (BindWidget))
UTextBlock* PlayerNameText;

UPROPERTY(meta = (BindWidget))
UComboBoxString* CurrencySelector;

UPROPERTY(meta = (BindWidget))
UButton* CloseButton;
```

### メインエリア
```cpp
UPROPERTY(meta = (BindWidget))
UTextBlock* BalanceText;

UPROPERTY(meta = (BindWidget))
UTextBlock* CurrencyText;

UPROPERTY(meta = (BindWidget))
UEditableTextBox* AmountInput;

UPROPERTY(meta = (BindWidget))
UButton* DepositButton;

UPROPERTY(meta = (BindWidget))
UButton* WithdrawButton;

UPROPERTY(meta = (BindWidget))
UButton* RefreshButton;
```

### 取引履歴エリア
```cpp
UPROPERTY(meta = (BindWidget))
UTabBar* TransactionTabBar;

UPROPERTY(meta = (BindWidget))
UButton* AllTabButton;

UPROPERTY(meta = (BindWidget))
UButton* DepositTabButton;

UPROPERTY(meta = (BindWidget))
UButton* WithdrawTabButton;

UPROPERTY(meta = (BindWidget))
UListView* TransactionListView;
```

## インベントリウィジェット (InventoryWidget)

### ヘッダーエリア
```cpp
UPROPERTY(meta = (BindWidget))
UEditableTextBox* SearchBox;

UPROPERTY(meta = (BindWidget))
UComboBoxString* FilterComboBox;

UPROPERTY(meta = (BindWidget))
UComboBoxString* SortComboBox;
```

### メインエリア
```cpp
UPROPERTY(meta = (BindWidget))
UUniformGridPanel* ItemGridPanel;

UPROPERTY(meta = (BindWidget))
UScrollBox* ItemScrollBox;

UPROPERTY(meta = (BindWidget))
UTextBlock* GoldText;

UPROPERTY(meta = (BindWidget))
UTextBlock* WeightText;
```

### 詳細パネル
```cpp
UPROPERTY(meta = (BindWidgetOptional))
UImage* ItemIcon;

UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* ItemNameText;

UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* ItemDescriptionText;

UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* ItemStatsText;

UPROPERTY(meta = (BindWidgetOptional))
UButton* UseButton;

UPROPERTY(meta = (BindWidgetOptional))
UButton* DropButton;
```

## メールウィジェット (MailboxBaseWidget)

### ヘッダーエリア
```cpp
UPROPERTY(meta = (BindWidget))
UTextBlock* MailCountText;

UPROPERTY(meta = (BindWidget))
UButton* ClaimAllButton;

UPROPERTY(meta = (BindWidget))
UButton* RefreshButton;

UPROPERTY(meta = (BindWidget))
UButton* CloseButton;
```

### メインエリア
```cpp
UPROPERTY(meta = (BindWidget))
UListView* MailListView;

UPROPERTY(meta = (BindWidget))
UScrollBox* MailDetailScrollBox;
```

### メール詳細
```cpp
UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* SubjectText;

UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* SenderText;

UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* DateText;

UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* BodyText;

UPROPERTY(meta = (BindWidgetOptional))
UListView* AttachmentListView;

UPROPERTY(meta = (BindWidgetOptional))
UButton* ClaimButton;

UPROPERTY(meta = (BindWidgetOptional))
UButton* DeleteButton;
```

## 共通コンポーネント

### トースト通知
```cpp
UPROPERTY(meta = (BindWidgetOptional))
UTextBlock* ToastText;

UPROPERTY(meta = (BindWidgetOptional))
UImage* ToastBackground;
```

### ローディングインジケータ
```cpp
UPROPERTY(meta = (BindWidgetOptional))
UCircularThrobber* LoadingIndicator;
```

## Blueprintでの実装例

### ウィジェットブループリント作成手順

1. **Widget Blueprint**作成 → **Parent Class**選択
2. **Designer**タブで以下を確認：
   - **Hierarchy**パネルでBindWidget名と一致する名前を付ける
   - **Details**パネルで**Is Variable**を有効にする

### 命名例

#### 銀行ウィジェットの場合
```
CanvasPanel
├── HeaderBox
│   ├── PlayerNameText (TextBlock)
│   ├── CurrencySelector (ComboBoxString)
│   └── CloseButton (Button)
├── MainArea
│   ├── BalancePanel
│   │   ├── BalanceText (TextBlock)
│   │   └── CurrencyText (TextBlock)
│   └── ActionPanel
│       ├── AmountInput (EditableTextBox)
│       ├── DepositButton (Button)
│       └── WithdrawButton (Button)
└── TransactionArea
    ├── TabBar
    │   ├── AllTabButton (Button)
    │   ├── DepositTabButton (Button)
    │   └── WithdrawTabButton (Button)
    └── TransactionListView (ListView)
```

### エラーハンドリング

#### BindWidgetが見つからない場合
```cpp
// 代替実装
virtual void NativeConstruct() override
{
    Super::NativeConstruct();
    
    // BindWidgetが見つからない場合のフォールバック
    if (!BalanceText)
    {
        BalanceText = Cast<UTextBlock>(GetWidgetFromName(TEXT("BalanceText")));
    }
}
```

## カスタマイズガイド

### 新しいウィジェット作成時
1. この仕様書の命名規則に従う
2. **BindWidget**属性を忘れない
3. **BlueprintReadOnly**または**BlueprintReadWrite**を追加

### 既存ウィジェットの拡張
1. 既存のBindWidget名を変更しない
2. 新しいコンポーネントは**BindWidgetOptional**を使用
3. 後方互換性を維持

## まとめ

この仕様書により：
- **統一的な命名**が保証される
- **Blueprintでのバインディング**が簡単になる
- **エラーが減少**する
- **メンテナンス**が容易になる

すべてのウィジェットはこれらのBindWidget名に従って実装してください。
