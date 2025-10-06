# 次期タスク一覧（2025-09-28）

## 概要
- 本ドキュメントは `Docs/NewDocs/` 配下の技術設計書を横断し、直近で着手すべきタスクを整理する。
- タスク完了・進行状況の変化は本ファイルを更新して追跡する。

## 参照ドキュメント
- `Development_Roadmap_Phase0.md` Phase0進捗と追加タスク（特に2.4 AdaptiveVoxel準備項目）。
- `AdaptiveVoxel_System_TaskPlan.md` 動的ボクセル導入計画および装備連携タスク群。
- `AAA_DB_LogUI_Design.md` DB/ログデバッグUIの実装タスク。
- `動的ボクセル解像度と空間属性シミュレーション.md` 技術背景と数値解析要件。

## タスクバックログ
| <span style="color:#d9534f;">ID</span> | <span style="color:#5bc0de;">概要</span> | <span style="color:#f0ad4e;">優先度</span> | <span style="color:#5cb85c;">UI優先度</span> | <span style="color:#e67e22;">フェーズ</span> | <span style="color:#337ab7;">ソース</span> | <span style="color:#9b59b6;">状態</span> | <span style="color:#ff7f0e;">メモ</span> |
|----|------|--------|----------|----------|--------|------|------|
| Task-AV-Equip-02 | `UAdaptiveVoxelEventRouter` PoC（攻撃/採掘イベント→ボクセルリクエスト） | 高 | 高 | Phase 0.5 | `Development_Roadmap_Phase0.md` 2.4 / `AdaptiveVoxel_System_TaskPlan.md` 4.8 | 未着手 | プレイヤー装備イベントとの連携経路を定義。 |
| Task-AV-Equip-03 | `UInventoryComponent` 連携下準備（素材ID、耐久消耗フラグ、UIデバッグ） | 中 | 高 | Phase 0.5 | `Development_Roadmap_Phase0.md` 2.4 | 未着手 | Inventory UIのデバッグボタン整備も含む。 |
| Task-DBLog-02 | `UDBQueryManagerComponent` / `ULogCaptureComponent` 実装 | 高 | 高 | Phase 0.5 | `AAA_DB_LogUI_Design.md` 6 | 未着手 | 非同期クエリ実行とログリングバッファ。 |
| Task-AV-Equip-01 | 装備データモデル拡張（耐久・属性カラム追加、素材ID整理） | 中 | 中 | Phase 0.5 | `Development_Roadmap_Phase0.md` 2.4 | 未着手 | Phase0後半で着手。SQLiteスキーマ改修要。 |
| Task-DBLog-01 | `DBQueryTypes.h` / `LogCaptureTypes.h` の型定義 | 中 | 中 | Phase 0.5 | `AAA_DB_LogUI_Design.md` 6 | 未着手 | UI/コンポーネント共通データ構造を整備。 |
| Task-DBLog-03 | `USQLiteSubsystem` への連携メソッド追加 | 中 | 中 | Phase 0.5 | `AAA_DB_LogUI_Design.md` 6 | 未着手 | プリセット/任意クエリAPIを公開。 |
| Task-AV-Debug-01 | デバッグ可視化コンポーネント実装（ボクセルノード描画） | 高 | 中 | Phase 0.5 | `AdaptiveVoxel_System_TaskPlan.md` 7.次アクション(短期) | 未着手 | `UAdaptiveVoxelSubsystem` の状態を可視化。 |
| Task-AV-SyncTest | インベントリサーバー同期テスト自動化の整備 | 中 | 低 | Phase 0.5 | `Development_Roadmap_Phase0.md` Week5-6 | 未着手 | Automationテストケースを拡充し負荷テストに備える。 |
| Task-AV-Tree-Proto | `FAdaptiveVoxelTree` プロトタイプ作成と性能測定 | 高 | 低 | Phase 1 | `AdaptiveVoxel_System_TaskPlan.md` 7.次アクション(中期) | 未着手 | リニアOctreeベースのPoCをCPUで検証。 |
| Task-DBLog-04 | ドキュメント更新と使用例追記 | 低 | 低 | Phase 0.5 | `AAA_DB_LogUI_Design.md` 6 | 未着手 | 実装完了後に `Docs/NewDocs/` を更新。 |
| Task-AV-Solver-GPU | Staggered Octree PoissonソルバのGPU移植・分散同期統合 | 低 | 低 | Phase 2 | `AdaptiveVoxel_System_TaskPlan.md` 7.次アクション(長期) | 未着手 | Phase1以降の長期タスク。 |

## 運用ルール
- タスク着手/完了時は本ファイルの該当行を更新し、必要に応じて補足メモを追加する。
- 新規タスク発生時は関連ドキュメントへのリンクとIDを付与して追記する。
- 完了したタスクは状態を「完了」とし、日付と成果物の参照先をメモに残す。
- UI優先度は「高/中/低」で表記し、プレイヤー向け画面実装の緊急度を示す（高=直近スプリント必須）。
