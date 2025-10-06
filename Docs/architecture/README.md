# アーキテクチャ概要（Godot MMO Voxel）

## 1. 目的とスコープ
- Godot 4.x ベースの MMO ボクセルプロジェクト全体の技術構成を可視化し、各担当領域の共通認識を形成する。
- 詳細資料（例: `architecture/networking.md`, `architecture/persistence.md`）へ分岐するための案内ページとして機能させる。

## 2. クライアント構成
- シーンルート: `res://scenes/main.tscn` からゲーム起動。`WorldRoot`（ボクセル表示）, `UIRoot`, `NetworkBridge` の3レイヤーを基本とする。
- オートロードシングルトン: `res://autoload/GameState.gd`, `res://autoload/NetworkClient.gd`, `res://autoload/ConfigService.gd` などを `project.godot` の AutoLoad に登録し、シーン間共有を確保。
- 入力処理: `InputMap` によるアクション定義 (`action_move_forward`, `action_interact` 等) を行い、`GameState` で抽象化→ボクセル制御/アビリティへ分派。
- レンダリング最適化: `WorldEnvironment` による GI 設定プリセット、メッシュ LOD 表、ボクセルチャンクの距離フェード、`Viewport` ベースの FSR/FSAA 切り替えポリシーを整理。
- パフォーマンス監視: `Performance.get_monitor()` で得られる指標（`TIME_FPS`, `MEMORY_STATIC` など）を HUD に表示し、GPU/CPU ボトルネックを随時検証。

## 3. サーバ構成
- 実装形態: 第一段階では Godot Multiplayer HLAPI（`ENetMultiplayerPeer`）を用いたホスト/リレー構成、将来的に GDExtension ベースの専用サーババイナリへ移行。
- 権威モデル: ログイン後はサーバ権威（位置・インベントリ・経済）で管理し、クライアントは補間と UI 表示に徹する。`ServerState` がゲームループを統括し、`ReplicationGraph` 相当の領域分割はボクセルチャンク単位で実装。
- メッセージ設計: RPC は `rpc_config()` で信頼性/チャンネルを定義し、`rpc_id` を用いたターゲティングを徹底。信頼性が不要な移動同期は不信頼チャンネル、取引/インベントリは信頼チャンネルで処理。
- フェイルオーバ: 将来的な水平方向スケールを見据え、セッションサーバ（ルームマネージャ）とゲームサーバを分割する設計案を保持。

## 4. データ永続化
- 現状: ローカルは `user://database/mmo_voxel.sqlite3` を Godot SQLite addon（仮）で運用。バックアップは `BackupService.gd` が起動/終了時に `.bak` を3世代管理。
- スキーマ: プレイヤー基礎 (`players`), インベントリ (`inventory`), ボクセルチャンク (`voxel_chunks`), 経済取引 (`bank_tx`) を Phase1 範囲として定義予定。
- 移行計画: CCU 増加時に PostgreSQL へ移行し、`architecture/persistence.md` にマイグレーション手順（Flyway 相当の CLI スクリプト）をまとめる。
- CI 連携: `godot --headless --script res://tools/db_check.gd` を CI ワークフローに組み込み、DDL 破壊を検出。

## 5. 観測性とロギング
- ログ出力: `Logger.gd` を共通化し、`logs/client_%Y%m%d.jsonl` に JSON Lines 形式で書き出す。サーバ側は `logs/server_%Y%m%d.jsonl` へ同形式で保存。
- メトリクス: `metrics/metrics.csv` へ `tick_rate`, `active_players`, `chunk_stream_ms` などを1分間隔で追記し、Grafana 連携時は Prometheus Exporter に変換。
- アラート: `operations/README.md` の基準に従い、`tick_rate < 20` が3分継続した場合に Discord Webhook 通知を行う設計。
- デバッグ: `res://debug/Overlay.tscn` の有効/無効を `ProjectSettings` → `debug/enable_overlay` で切り替え、開発版のみ表示する。

## 6. 今後のドキュメント展開
- `architecture/networking.md`（通信詳細）, `architecture/persistence.md`（DB/キャッシュ）, `architecture/world-streaming.md`（ボクセルストリーミング）の3文書を優先執筆。
- `archive/legacy_unreal/` の関連資料から Godot へ転用する項目をチケット化し、移植進捗を追跡。
- 構成変更時は README 先頭に `更新日` と差分要約を追記し、履歴を Git 管理で追う。
