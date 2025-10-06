# Godot MMO Voxel 実装計画（総合ドキュメント）

更新日: 2025-10-06
担当: TODO

## 1. 現状サマリ
- Godot プロジェクト `g:/Godot/mmo-voxel` は Phase 0（基盤整備）を開始済み。`res://scenes/main.tscn`、`ConfigService.gd`、`Logger.gd`、`NetworkClient.gd`、`GameState.gd` を実装し、JSONL ログ生成を確認した。
- ビルド/CI、ネットワーク PoC など Phase 0 中の残タスクは未着手。以降の Phase 1〜4 は計画段階。
- Unreal 時代の設計資料は `Docs/archive/legacy_unreal/` に保管。`Gameplay_Feature_Status.md` を Godot 移植計画へ再編済み。

## 2. 実装フェーズ全体像
| フェーズ | 期間目安 | 目的 | 主な完了判定 |
|----------|----------|------|----------------|
| Phase 0: 基盤整備 | 2-3 週間 | Godot プロジェクトの骨格、開発環境、CI 下地を構築 | オートロード/シーン構成とビルドパイプラインが動作 |
| Phase 1: ネットワーク & データ | 3-4 週間 | マルチプレイ同期、SQLite 永続化、観測性基礎 | ログイン→位置同期→データ保存のサイクルが成立 |
| Phase 2: オープンワールド基礎 | 4-5 週間 | ボクセルワールド生成、チャンクストリーミング、探索導線 | オープンワールドを歩行・採掘できる |
| Phase 3: ゲームプレイ & 経済 | 4-6 週間 | クエスト/経済/取引 UI とサーバロジックを実装 | 採掘→クラフト→取引までのループが成立 |
| Phase 4: 運用拡張 | 継続 | モニタリング、自動テスト、コンテンツ拡張 | KPI 収集と運用 Runbook が整備 |

## 3. フェーズ別タスク詳細

### Phase 0: 基盤整備
- **プロジェクト構成** `architecture/README.md` に基づき、`res://scenes/main.tscn`, AutoLoad シングルトン (`GameState`, `NetworkClient`, `ConfigService`, `Logger`) を実装済み。`MainRoot.gd` で設定適用とログ出力を確認。 _[完了]_ 
- **ビルド環境** `operations/README.md` を参照し、Godot 4.x 環境設定、CLI ビルドスクリプト、GitHub Actions 雛形を作成。 _[未着手]_ 
- **ログ/設定** `Logger.gd`, `ConfigService.gd` を導入し、`user://logs/` への JSONL 出力を検証済み。 _[完了]_ 
- **成果物**: 基礎シーン、オートロード登録、初期ログ基盤、CI/ビルド手順書（作成予定）。

### Phase 1: ネットワーク & データ
- **通信基礎** `architecture/README.md` のサーバ構成に従い `NetworkClient.gd` と `ServerState.gd` のスケルトンを実装。ENet を利用したログイン/位置同期 RPC の PoC を作成。
- **データ永続化** `architecture/README.md` & `operations/README.md` を参照し、`BackupService.gd` と SQLite 接続ラッパーを実装。`players`, `inventory`, `voxel_chunks` テーブルの DDL を用意。
- **観測性** `operations/README.md` のメトリクス収集仕様に基づき、`metrics_collector.gd` を実装。ログ/メトリクスの保存先を決定。
- **成果物**: ログイン→スポーン→位置同期→セーブまでの基本サイクル、DB バックアップ、初期メトリクス出力。

### Phase 2: オープンワールド基礎
- **ワールド生成** `gameplay/README.md` のワールド構成と `architecture/world-streaming.md (予定)` を参照し、`WorldRoot` にチャンク管理マネージャを実装。`32x32x32` チャンクを距離ベースでストリーミング。
- **探索体験** オープンワールド探索仕様に合わせ、ランドマーク/資源帯のプレースホルダ（シグナル通知のみ）を実装。
- **UI/HUD 基礎** `ui/README.md` の方針に従い、HUD にコンパス・ミニマップモックを追加し、探索イベントを通知。
- **ボクセルシステム計画連携** `Docs/architecture/voxel_system_plan.md` の Phase A/B を Phase 2 期間中に実施。`AdaptiveVoxelTree`/`AdaptiveVoxelSubsystem` の PoC 完了後、`VoxelMeshStreamer` とチャンク LOD 制御を同フェーズ内で構築。
- **成果物**: クライアントがシームレスに移動しながらチャンク読み込みが行えること、ランドマーク発見ログの記録。

### Phase 3: ゲームプレイ & 経済
- **採掘/クラフト** `gameplay/README.md` の生活コンテンツ仕様を基に `mining_tool.gd`、`crafting_station.gd` を実装。サーバ側で採掘結果を確定し、インベントリへ反映。
- **クエスト/イベント** 探索型クエストを実装。ランドマーク発見・任意イベントへの参加記録を `analytics/player_activity.jsonl` に出力。
- **経済/取引 UI** `ui/README.md` の主要ウィジェット構成を参照し、マーケット UI (`ui/trade_market.tscn`) と取引 RPC を実装。`Shard`, `Aetherium`, `GuildMark` の CRUD をサーバ側に用意。
- **ボクセルシステム計画連携** `Docs/architecture/voxel_system_plan.md` の Phase C を Phase 3 冒頭で着手し、属性シミュレーション API と `VoxelSense` 連携を完了させた上でゲームプレイ機能と統合。
- **成果物**: 探索→採掘→クラフト→取引までのフローが動作し、経済データがサーバ永続化される。

### Phase 4: 運用拡張
- **モニタリング強化** Grafana/Loki 連携、Discord 通知、アラート閾値設定を実装し運用手順を `operations/local_testing.md` と合わせて整備。
- **自動テスト** Godot Integration Test によるフル E2E（ボクセル破壊、同期、取引）を追加。テスト結果を CI に統合。
- **コンテンツ拡張** バイオーム追加、ペットシステム、季節イベントを段階的に実装し、ドキュメントの更新履歴を管理。
- **ボクセルシステム計画連携** `Docs/architecture/voxel_system_plan.md` の Phase D/E を Phase 4 へ統合し、ネットワーク差分同期と運用ツール群を継続的に整備。

## 4. タスク/ドキュメント連携
- `architecture/README.md`: クライアント/サーバ構成、永続化、観測性 → Phase 0-2 の指針。
- `gameplay/README.md`: オープンワールド探索方針、経済/戦闘仕様 → Phase 2-3 の指針。
- `operations/README.md`: 環境整備、CI/CD、運用 → Phase 0-4 の継続タスク。
- `ui/README.md`: HUD/インベントリ/取引 UI の設計 → Phase 2-3 の実装参照。

## 5. 実装順チェックリスト
1. プロジェクト基盤整備（オートロード、ログ、CI）
2. ネットワーク同期と SQLite 永続化
3. ボクセルチャンク生成とシームレスストリーミング
4. HUD/探索 UI モックとランドマークイベント
5. 採掘・クラフト・インベントリ更新
6. 経済・取引システムと UI 連携
7. モニタリング・アラート・自動テスト強化
8. 追加コンテンツ（バイオーム/イベント/ペット）

## 6. 今後の更新方針
- 各フェーズ完了時に本ドキュメントへ `完了日/所感/課題` を追記し、進捗管理に利用。
- 詳細仕様が固まった項目は専用ドキュメント（例: `architecture/networking.md`）へ切り出し、本書からリンク。
- レガシー資料からの移植状況を追跡するため、`Docs/archive/legacy_unreal/` 内ファイルに `移植済み` ラベルを付与する予定。
