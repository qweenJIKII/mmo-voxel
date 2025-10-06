# AAA ミニマップ & 通知マネージャ設計メモ

## 1. ミニマップシステム概要
- **目的**: シーンキャプチャによるトップダウン描画と、動的なマーカー表示を組み合わせた AAA グレードのミニマップ基盤を提供する。
- **主要クラス**
  - `UMinimapComponent` (ActorComponent)
    - `ASceneCapture2D` をスポーンし、`UTextureRenderTarget2D` へ描画。
    - 複数ズームレベル (`TArray<float> ZoomLevels`) とベース OrthoWidth を保持。
    - `RegisterTrackedActor()` / `UnregisterTrackedActor()` / `GetMarkerStates()` を公開。
    - `OnMinimapMarkersUpdated` (Dynamic Multicast) で UI 側へ通知。
  - `FMinimapMarker` / `FMinimapMarkerState`
    - アイコン、色、回転追従、エッジ固定など、UI 表現に必要な情報を保持。
    - `FMinimapMarkerState` はワールド距離・残存時間・ミッションフラグを含む。
- **描画パイプライン**
  - `RetainerBox` 経由で 0.1–0.2s 間隔の再描画。
  - Capture Actor の高さ・向きは `CaptureHeight` と `bRotateWithFocus` で制御。
  - ズーム切替は `CycleZoom(bool)` / `SetZoomIndex(int32)`。
- **拡張ポイント**
  - フォグオブウォー時の `UMaterialInstanceDynamic` 利用。
  - イベント連携: `BroadcastMinimapEvent` で通知 → UI がエフェクト再生。

## 2. 通知マネージャ概要
- **目的**: トースト通知を優先度付きキューで管理し、UI にスタック更新を配信する。
- **主要クラス**
  - `UNotificationManagerComponent` (ActorComponent)
    - `PushNotification(FNotificationPayload)` で通知登録し `FNotificationHandle` を返却。
    - `UpdateNotification()` / `PinNotification()` / `ClearNotification()`、カテゴリ別クリア。
    - `TickComponent` で有効期限管理、`OnNotificationStackChanged` (Dynamic Multicast) 発火。
  - `FNotificationPayload`
    - タイトル、本文、カテゴリ (`ENotificationCategory`)、優先度 (`ENotificationPriority`)、継続時間、アイコン、サウンド、マージ可否など。
  - `FNotificationEntry`
    - スタック済み通知のビュー表現。残り時間、スタック回数、ピン留め状態を格納。
- **仕様メモ**
  - 最大同時表示数 (`MaxActiveNotifications`) を超えた場合、優先度 + 経過時間で除外。
  - `bAllowMerging` が有効な通知は同種メッセージとスタックし `StackCount` が増加。
  - 重要度 `Urgent` はピン留め初期値 true + 解除まで持続。
  - フック: HUD プレゼンター、ミニマップイベント、外部サブシステムから利用。

## 3. 連携と BP 受け渡し
- `UMinimapComponent` の `GetMinimapRenderTarget()` を HUD Widget の Brush にバインド。
- `UNotificationManagerComponent::OnNotificationStackChanged` を `WBP_Notifications` のイベントグラフへ接続。
- 両コンポーネントは `HUDPresenterComponent` から解決される `UUIOpenComponent` により UI を開閉。

## 4. 実装タスク概要
1. `Public/UI/Minimap/` に型定義と `UMinimapComponent` を追加。
2. `Public/UI/Notifications/` に通知用列挙・構造体・`UNotificationManagerComponent` を追加。
3. `Private/...` に対応 cpp を実装し、ズーム/タイマー/イベントを処理。
4. HUD Presenter または将来の UI で利用できるよう、BlueprintCallable API を公開。
5. 最終的に `Docs/NewDocs/` のガイドへ使用方法を追記。
