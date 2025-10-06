# 最適化タスク実施順（リファレンス用）

更新: 2025-08-23
対象プロジェクト: `g:/Unreal Projects/MyTEST`

---

## 結論（おすすめ順）
1. B) サーバ権威チェック監査リストを生成
2. C) GameOptimizationPlugin を有効化し、HUDで FPS/CPU/帯域/Replication キューを表示
3. A) ReplicationGraph の最小実装テンプレを追加
4. D) セーブ→DB移行の PoC 設計（データモデル/書き込みキュー/整合性）

---

## 各タスクの目的・理由・アウトプット

### 1) B) サーバ権威チェック監査リスト
- 目的: 経済/取引/ガチャ/能力など不正や抜けが致命傷になりやすい領域を網羅し、検証要件を明確化。
- 理由: 低工数で高リスク箇所を可視化。以降の最適化や設計の前提品質を底上げ。
- アウトプット:
  - サーバ権威で必須検証の API/関数一覧（既実装/未実装）
  - 期待検証・ログ要件（冪等性、境界値、Rate limit、監査ログ）
- 依存関係: なし

### 2) C) GameOptimizationPlugin 有効化 + HUD
- 目的: 観測性の強化。以降の改善効果を測定可能にする。
- 理由: 既存の `URealTimeProfiler` で FPS/CPU/メモリ等が取得可能。HUDに可視化。
- 手順の要点:
  - `Plugins/GameOptimizationPlugin/GameOptimizationPlugin.uplugin` を有効化
  - `Source/MyTEST/MyTEST.Build.cs` に `GameOptimizationPlugin` を追加
  - UMG HUD に以下を表示: FPS/CPU/メモリ/ネット帯域/Replication キュー（段階的に実装）
- アウトプット: 最小HUDと統計ログ。検証用のスクリーンショット/動画。
- 依存関係: なし（エディタからの有効化と Build.cs 追記のみ）

### 3) A) ReplicationGraph 最小実装テンプレ
- 目的: レプリケーションの帯域とCPUを削減。スケール耐性の確保。
- 理由: 効果は大きいが侵襲的。B/C でボトルネックを把握後、段階導入が安全。
- スコープ: 距離ベース + 必要例外のホワイトリスト、段階フラグで無効化可能に。
- アウトプット: `UReplicationGraph` 派生、設定項目、A/B 比較レポート。
- 依存関係: C の可視化で現状値を把握してから調整。

### 4) D) セーブ→DB 移行 PoC 設計
- 目的: データ整合性/スループット/運用性の改善。
- 理由: スコープ広く影響大。A までのネットワーク最適化と要件把握後に進めるのが妥当。
- スコープ: データモデル、非同期書込みキュー、整合性設計（冪等キー/再試行/障害時リカバリ）。
- アウトプット: 設計ドラフト、マイグレーション/ロールバック計画、PoC 実装計画。
- 依存関係: 既存セーブ周りの仕様確認。

---

## 追加メモ
- 将来の Steem/EOS 連携は「非同期アンカー」方針。今は実装せず、拡張ポイントのみ確保。
- 計測/可視化は最優先。C を行うと A/D の効果検証が容易になる。
- 変更点は常に `OptimizationLog.txt` に要約を追記すること。

---

## 参考コード/パス
- プラグイン設定: `Plugins/GameOptimizationPlugin/GameOptimizationPlugin.uplugin`
- ビルド設定: `Source/MyTEST/MyTEST.Build.cs`
- プロファイラ: `Source/MyTEST/Private/RealTimeProfiler.cpp`
- ドキュメント置き場: `Source/MyTEST/Docs/`
