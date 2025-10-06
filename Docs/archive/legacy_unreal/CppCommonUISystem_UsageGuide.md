# C++汎用UIシステム 利用ガイド

## 概要
C++のみで実装された汎用UIシステムは、Blueprintから呼び出し可能な再利用可能なUIコンポーネントを提供します。SQLite DAOと直接連携し、Bank/Mail/Inventory機能を統合的に管理します。

## システム構成

### 1. 汎用UIベースクラス
**ファイル**: `Source/MyTEST/Public/UI/Common/CommonUIWidgetBase.h`

#### 基本機能
- **表示制御**: `Show()`, `Hide()`, `IsWidgetVisible()`
- **ライフサイクル管理**: `InitializeWidget()`, `CleanupWidget()`
- **データ更新**: `RefreshData()`
- **イベント通知**: `OnWidgetShown`, `OnDataRefreshed`

#### ユーティリティ関数
- `FormatCurrency(int64 Amount, FString CurrencyCode)` - 通貨フォーマット
- `FormatDateTime(FDateTime DateTime)` - 日時フォーマット
- `PlayUISound(FString SoundPath)` - サウンド再生

### 2. 既存UIクラスの統合
既存のUIウィジェットはすべて`UCommonUIWidgetBase`を継承するように拡張済み：
- `UBankWidgetBase` → `UCommonUIWidgetBase`継承
- `UInventoryWidget` → `UCommonUIWidgetBase`継承
- `UMailboxBaseWidget` → `UCommonUIWidgetBase`継承

### 3. DAO連携
既存のDAOクラスを直接Blueprintから使用：
- **Bank**: `UBankDAO`
- **Mail**: `UMailDAO`
- **Inventory**: `UInventoryDAO`

### 4. 実装済みUIモジュール
以下のUIモジュールが `UCommonUIWidgetBase` または `UUIOptionWindowBase` を継承して実装済みです。

- **`UUIOptionWindowBase`**: 入力モード管理機能を持つ、オプションウィンドウ用の新しい基底クラス。
- **`UStatusWidget`**: プレイヤーのHP/MPなどを表示するHUD。
- **`UCraftingWidget`**: アイテム製作ウィンドウ。
- **`UBuildingWidget`**: 建築ウィンドウ。
- **`UCalendarWidgetBase`**: カレンダー機能の基底クラス。
- **`UPlayerEventLogWidget`**: ゲーム内イベントログ。
- **`UMainMenuWidget`**: ゲームのメインメニュー。
- **`UCoupleMarriageWidget`**: 結婚システムUI。

## Blueprint/C++での使用方法

### 1. ウィジェットの表示 (推奨: UIManagerSubsystem経由)

`UUIManagerSubsystem` を使用することで、UIの生成、表示、Zオーダー、重複防止をグローバルに管理できます。

#### C++での表示
```cpp
#include "UIManagerSubsystem.h"

void AMyPlayerController::ShowBankUI()
{
    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UUIManagerSubsystem* UIManager = GameInstance->GetSubsystem<UUIManagerSubsystem>())
        {
            // UBankWidgetBaseをZOrder=100で表示
            UBankWidgetBase* BankWidget = Cast<UBankWidgetBase>(UIManager->OpenWindow(UBankWidgetBase::StaticClass(), 100));
            if (BankWidget)
            {
                BankWidget->LoadAccountData(GetPlayerId());
            }
        }
    }
}
```

#### Blueprintでの表示

`GameInstance` から `UIManagerSubsystem` を取得し、`OpenWindow` 関数を呼び出します。

1. `Get Game Instance` -> `Get Subsystem` (Class: `UIManagerSubsystem`)
2. `Open Window` (Widget Class: `BankWidgetBase`, ZOrder: 100)
3. 戻り値を `BankWidgetBase` にキャストし、必要なデータをロードします。

### 2. (旧) 直接作成する方法

サブシステムを使わず、従来通り `CreateWidget` で生成することも可能ですが、管理が一元化されないため非推奨です。


#### Blueprintでの作成
1. **ウィジェットブループリント**を作成
2. **親クラス**として`BankWidgetBase`を選択
3. **イベントグラフ**で以下のノードを使用：
   - `Create Widget` → `BankWidgetBase`
   - `Initialize Widget`
   - `Show`
   - `Load Account Data`

### 2. DAO関数の使用

#### Bank機能
```cpp
// 残高取得
int64 Balance;
UBankDAO::GetAccountBalance(PlayerId, "Gold", Balance);

// 入金
UBankDAO::DepositToAccount(PlayerId, "Gold", 1000, "Quest Reward");

// 出金
UBankDAO::WithdrawFromAccount(PlayerId, "Gold", 500, "Shop Purchase");

// 取引履歴取得
TArray<FBankTransactionHistory> Transactions;
UBankDAO::ListTransactions(PlayerId, "Gold", Transactions);
```

#### Mail機能
```cpp
// メール一覧取得
TArray<FMailRow> Mails;
UMailDAO::ListMails(PlayerId, Mails);

// メール一括受領
int32 ClaimedCount = UMailDAO::ClaimAll(PlayerId);

// メール送信
UMailDAO::SendMail(PlayerId, "Subject", "Body", "{\"items\": [{\"id\": \"sword\", \"amount\": 1}]}", ExpireTime);
```

#### Inventory機能
```cpp
// アイテム一覧取得
TArray<FInventoryRow> Items;
UInventoryDAO::ListItems(PlayerId, Items);

// アイテム追加
UInventoryDAO::AddItem(PlayerId, "health_potion", 5, "{\"quality\": \"rare\"}");

// アイテム削除
UInventoryDAO::RemoveItem(PlayerId, "health_potion", 2);
```

### 3. イベントハンドリング

#### Blueprintでのイベントバインド
```cpp
// OnWidgetShownイベント
Event OnWidgetShown → カスタム関数

// OnDataRefreshedイベント
Event OnDataRefreshed → RefreshDisplay関数
```

#### C++でのイベントハンドリング
```cpp
// PlayerControllerでの例
void AMyPlayerController::SetupBankUI()
{
    if (BankWidget)
    {
        BankWidget->OnWidgetShown.AddDynamic(this, &AMyPlayerController::OnBankWidgetShown);
        BankWidget->OnDataRefreshed.AddDynamic(this, &AMyPlayerController::OnBankDataRefreshed);
    }
}

void AMyPlayerController::OnBankWidgetShown(UCommonUIWidgetBase* Widget, bool bVisible)
{
    if (bVisible)
    {
        // ウィジェット表示時の処理
        RefreshBankData();
    }
}

void AMyPlayerController::OnBankDataRefreshed(UCommonUIWidgetBase* Widget)
{
    // データ更新時の処理
    UpdateUI();
}
```

## 実装パターン

### 1. ウィジェット拡張パターン
```cpp
// 新しいウィジェットクラスの作成
UCLASS(Blueprintable, BlueprintType)
class MYTEST_API UCustomUIWidget : public UCommonUIWidgetBase
{
    GENERATED_BODY()

public:
    virtual void InitializeWidget() override
    {
        Super::InitializeWidget();
        // カスタム初期化処理
    }

    virtual void RefreshData() override
    {
        Super::RefreshData();
        // カスタムデータ更新処理
    }
};
```

### 2. データバインディングパターン
```cpp
// Blueprintで使用するデータ構造
USTRUCT(BlueprintType)
struct FUIData
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly)
    FString Title;

    UPROPERTY(BlueprintReadOnly)
    int64 Value;

    UPROPERTY(BlueprintReadOnly)
    FLinearColor Color;
};
```

## 設定手順

### 1. ビルド設定の確認
- `MyTEST.Build.cs`に以下が含まれていることを確認：
  ```cpp
  PublicDependencyModuleNames.AddRange(new string[] {
      "UMG", "Slate", "SlateCore"
  });
  ```

### 2. ウィジェットブループリントの作成
1. **Content Browser** → **Add New** → **User Interface** → **Widget Blueprint**
2. **Parent Class**として以下を選択：
   - `BankWidgetBase`（銀行UI）
   - `InventoryWidget`（インベントリUI）
   - `MailboxBaseWidget`（メールUI）

### 3. ウィジェットのバインド
各ウィジェットブループリントで：
- **BindWidget**属性を使用してUI要素をバインド
- **Event Graph**でDAO関数を呼び出し
- **デリゲート**を使用してイベントを処理

## トラブルシューティング

### よくある問題

1. **ウィジェットが表示されない**
   - `InitializeWidget()`が呼ばれているか確認
   - `Show()`メソッドが呼ばれているか確認

2. **DAO関数が呼び出せない**
   - プレイヤーIDが正しく設定されているか確認
   - サーバーワールドで実行されているか確認

3. **データが更新されない**
   - `RefreshData()`を手動で呼び出す
   - `OnDataRefreshed`イベントを確認

## ベストプラクティス

### 1. メモリ管理
- ウィジェットは`CleanupWidget()`で適切にクリーンアップ
- 不要になったら`RemoveFromParent()`を呼び出す

### 2. パフォーマンス
- 大量のデータ更新は`RefreshData()`でバッチ処理
- 非同期処理は適切に管理

### 3. エラーハンドリング
- DAO関数の戻り値を常に確認
- ユーザーへのフィードバックを提供

## まとめ

このC++汎用UIシステムにより：
- **ゼロからのUI実装が不要**
- **既存DAOとの直接連携**
- **Blueprintでの簡単なカスタマイズ**
- **メモリ効率的な実装**

すべての機能は既に実装済みで、即座に使用可能です。
