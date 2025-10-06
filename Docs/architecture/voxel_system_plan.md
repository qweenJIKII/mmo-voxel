# Godot Adaptive Voxel System 設計計画

更新日: 2025-10-06
担当: TODO
参照: `Docs/archive/legacy_unreal/NewDocs/AdaptiveVoxel_System_TaskPlan.md`

## 1. 目的
- Unreal 時代の動的ボクセル解像度システム計画を Godot 4.x 環境へ移植し、MMO 探索向けのボクセル基盤を構築する。
- オープンワールド探索と経済システムの中心となる資源採掘/環境シミュレーションを支えるテクノロジーを提供する。

## 2. Godot 版アーキテクチャ
- **データ層**: GDExtension で実装する `AdaptiveVoxelTree`（リニア Octree + スラブアロケータ）。チャンク毎に固定サイズ `32x32x32` を基本とし、必要領域のみ細分化。
- **制御層**: `res://scripts/voxel/AdaptiveVoxelSubsystem.gd` がワールド毎にツリー管理、Refine/Derefine 判定、興味領域集約を担当。
- **シミュレーション層**: GDExtension モジュール `AdaptiveVoxelSolver` が流体/温度/穢れを Staggered Octree Poisson 離散化で計算。CPU 実装から着手し、GPU (Compute Shader) へ拡張。
- **レンダリング層**: `VoxelMeshStreamer` が Godot の `MultiMeshInstance3D` を用いて可変LODメッシュを生成。Greedy Meshing + Marching Cubes のハイブリッド構成を検討。
- **同期層**: `res://scripts/network/VoxelReplication.gd` が差分レプリケーションを行い、ENet ベースでチャンク更新を配信。MVCC/OCC モデルを Godot RPC へ適用。
- **UIレイヤ**: `res://ui/debug/VoxelDebugOverlay.tscn` で解像度/属性ヒートマップを可視化し、開発支援とゲーム内 HUD 表示を共通化。

## 2.1 現状実装 (2025-10-06)
- **AdaptiveVoxelTree.gd**: `refine_region()` / `derefine_region()` / `query_nodes()` / `get_nodes()` を含む GDScript スタブを実装。Octree ノード生成・削除と AABB クエリ、ボクセル値の保持を簡易ロジックで提供中。
- **AdaptiveVoxelSubsystem.gd**: プレイヤー興味領域を算出し `AdaptiveVoxelTree` に `refine_region()` / `prune_outside()` を指示する処理を実装。`get_debug_nodes()` / `get_debug_nodes_with_meta()` でデバッグ出力を提供。
- **VoxelDebugDrawer.gd**: `get_debug_nodes()` から取得した `AABB` を `ImmediateMesh` でライン描画し、Octree ノードの可視化をサポート。
- **VoxelMeshStreamer.gd**: `get_debug_nodes_with_meta()` を用いて `MultiMeshInstance3D` にノード境界を可視化。LOD メッシュ生成は未実装だがデバッグプレビューとして動作。
- **シーン構成**: `res://scenes/voxel_debug_scene.tscn` で `AdaptiveVoxelSubsystem`, `VoxelDebugDrawer`, `VoxelMeshStreamer` を組み合わせ、`players` グループのノード移動に追従してノード生成を確認できる PoC を構築。

## 3. 実装フェーズ

### Phase A: 基盤 PoC（4 週間）
- **タスクA1**: `AdaptiveVoxelTree` GDExtension のスケルトン実装（ノード確保/解放、AABB クエリ）。 _[進捗: GDScript スタブ実装済み。GDExtension 未着手]_ 
- **タスクA2**: `AdaptiveVoxelSubsystem.gd` の雛形作成。プレイヤー興味領域を八分木座標へマッピング。 _[進捗: GDScript 実装済み]_ 
- **タスクA3**: デバッグ描画（`res://scripts/debug/VoxelDebugDrawer.gd`）で Octree ノードをライン表示。PIE モードで状態確認。 _[進捗: GDScript 実装済み]_ 
- **補足 (2025-10-06)**:
  - `AdaptiveVoxelTree.gd` に簡易 Octree ノード生成・問合せを実装済み（GDExtension 差し替え前のスタブ）。
  - `res://scenes/voxel_debug_scene.tscn` で `AdaptiveVoxelSubsystem` + `VoxelDebugDrawer` + `VoxelMeshStreamer` をセットアップ。プレイヤー (`players` グループ) を移動してノード生成を可視化。
  - `VoxelMeshStreamer.gd` は Phase B の `VoxelMeshStreamer` 実装に向けた MultiMesh ベースの足場。現在は `AdaptiveVoxelTree.query_nodes()` の結果をスケール表示。
- **成果物**: Godot エディタ上で Octree を生成・視覚化できる PoC。ボクセル編集インターフェース（`set_voxel`, `clear_voxel`）。
### Phase B: レンダリング & ストリーミング（5 週間）
- **タスクB1**: `VoxelMeshStreamer` 実装。チャンク単位でメッシュを生成し、距離に応じて LOD を切り替え。 _[進捗: GDScript デバッグ表示実装済み。LOD メッシュ生成・差分更新は未着手]_ 
- **タスクB2**: `architecture/world-streaming.md`（新規）に従い、プレイヤー周囲チャンクの Prefetch/Unload を制御。 _[進捗: 未着手]_ 
- **タスクB3**: `AdaptiveVoxelSubsystem` に動的 Refine/Derefine ロジックを導入。プレイヤー行動/イベントで解像度を変更。 _[進捗: GDScript 内でプレイヤー周辺の refine/prune を実装、イベント連携は未着手]_ 
- **タスクB4**: プレイヤーモデルの可視化。`TestPlayer` に暫定メッシュを割り当て、将来的なキャラクタースキン/アニメーション導入の土台とする。 _[進捗: 未着手]_ 
- **成果物**: シームレスなチャンク読み込みと LOD メッシュ表示。GPU/CPU パフォーマンス計測レポート。

### Phase C: 属性シミュレーション（6 週間）
- **タスクC1**: `AdaptiveVoxelSolver` で温度/穢れ/マナの属性格納フォーマットを実装。CPU ベースの時間積分ループを構築。 _[進捗: 未着手]_ 
- **タスクC2**: 属性更新／クエリ API (`get_attribute_field`, `apply_attribute_impulse`) を `AdaptiveVoxelSubsystem` へ追加。 _[進捗: 未着手]_ 
- **タスクC3**: `res://scripts/ai/VoxelSense.gd` で AI から属性フィールドを参照。イベント（爆発、魔法）入力を `AdaptiveVoxelEventRouter.gd` で処理。 _[進捗: 未着手]_ 
- **成果物**: 属性ヒートマップの HUD 表示、属性更新ログ、自動テスト（属性維持/減衰）。

### Phase D: ネットワーク & 経済連携（6 週間）
- **タスクD1**: `VoxelReplication.gd` を実装し、チャンク差分をサーバ→クライアントへストリーミング。ENet 信頼/不信頼チャンネルを切り分け。
- **タスクD2**: サーバ側 `AdaptiveVoxelServer.gd`（GDExtension）でトランザクション管理（MVCC/OCC）を実装。競合時のリトライとログ収集。
- **タスクD3**: 採掘イベントと経済システムを接続。`mining_tool.gd` → `AdaptiveVoxelEventRouter` → `inventory`/`bank_tx` 更新を単一トランザクションで処理。
- **成果物**: 複数プレイヤーで同一チャンクを編集しても整合性を維持。採掘結果が `SQLite` に記録され、UI に反映。

### Phase E: 運用・ツール（継続）
- **タスクE1**: `tools/voxel_builder.gd` を用意し、初期ワールド生成やイテレーションを自動化。
- **タスクE2**: `operations/scripts/voxel_load_test.gd` で負荷試験を実施、Grafana で `voxel_stream_ms` 等を可視化。
- **タスクE3**: QA シナリオ（再現用リプレイ）と障害対応 Runbook を `operations/README.md` と連携して整備。

## 4. 依存関係
- `Phase 0-2`（Project Implementation Plan）で構築するネットワーク基盤・UI モックが完成していること。
- `operations/README.md` の CI/CD パイプラインにボクセル系テストを組み込む。
- `gameplay/README.md` のオープンワールド設計に従い、ランドマーク/資源帯の配置データフォーマットを確定。

## 5. リスクと対策
- **性能リスク**: GDExtension 実装の最適化不足 → 早期にプロファイリング、並列化検討、Compute Shader への移植計画。
- **整合性リスク**: 分散トランザクションの競合 → チャンク粒度のロックと OCC から開始し、必要に応じMVCCへ拡張。
- **開発コスト**: 高度なアルゴリズム開発 → 研究期間の確保、外部 OSS（OpenVDB 等）の調査。

## 6. マイルストーン
| マイルストーン | 完了条件 |
|----------------|----------|
| M1: Octree PoC | `godot --headless --script res://tests/voxel_octree.tscn` でOctree生成・可視化テストが成功 |
| M2: LOD Streaming | プレイヤー移動に合わせたチャンク読み込みとメッシュ表示が 60 FPS を維持 |
| M3: 属性シミュレーション | 温度/穢れフィールドが更新され、UI ヒートマップで確認できる |
| M4: サーバ同期 | 複数クライアント間で採掘結果が整合し、DB に記録される |
| M5: 運用ツール | 負荷試験・ログ・Runbook が整備され、CI で自動実行 |

## 7. 参考ドキュメント
- `Docs/Project_Implementation_Plan.md`: Phase 2-3 のタスクに統合。
- `Docs/gameplay/README.md`: オープンワールド探索・採掘仕様の参照。
- `Docs/ui/README.md`: VoxelDebugOverlay 等 UI 連携の仕様。
- `Docs/operations/README.md`: モニタリング、負荷試験、運用ルールと整合。
