# 開発・運用ガイドアウトライン

## 1. 環境構成
- ローカル開発: Windows 11 / Ubuntu 24.04 をサポート対象とし、Godot 4.6 安定版を標準化。`project.godot` の差分設定は `.godot/` 以下で管理。
- 依存ツール: `Python 3.11`（ツールスクリプト用）、`Node.js 20`（Web ダッシュボード用）等のバージョンを `operations/requirements.md` に明記する予定。
- コンテナ検証: `docker compose -f ops/docker-compose.server.yml up` で専用サーバ（headless Godot + SQLite）を起動できるよう設計。Podman 互換も確認。

## 2. ビルドとデプロイ
- ローカルビルド: `godot --headless --export-release "Windows Desktop" build/windows/mmo_voxel.exe` を標準コマンドとし、`export_presets.cfg` をリポジトリ管理。
- CI/CD: GitHub Actions ワークフローで `setup-godot` アクションを利用し、静的解析（GDScriptLint）、ユニットテスト、エクスポートを自動化。成果物は GitHub Releases へアップロード。
- デプロイ: 専用サーバ版は `build/server/mmo_voxel_server.x86_64` を Docker イメージに格納し、`registry.example.com/mmo-voxel/server` へ push。

## 3. データベース運用
- SQLite: `user://database/` 配下に配置し、`BackupService.gd` が 00:00/12:00 に自動バックアップ。`operations/scripts/db_migrate.gd` で手動マイグレーション可能。
- 健康診断: 週次で `godot --headless --script res://tools/db_healthcheck.gd` を実行し、インデックス欠如・テーブル破損を検知。
- PostgreSQL 移行: 将来は `pgvector` を利用したボクセル AI 検索も視野に入れ、`architecture/persistence.md` のロードマップに沿って段階的移行。

## 4. モニタリングとアラート
- メトリクス収集: `operations/scripts/metrics_collector.gd` が 60 秒間隔で JSONL に追記。指標は `tick_rate`, `active_sessions`, `db_latency_ms`, `voxel_stream_fail` など。
- ダッシュボード: 初期は Grafana + Loki を想定し、`docker-compose.monitoring.yml` に構築手順を記載予定。
- アラート閾値: `tick_rate < 20`（3分）、`db_latency_ms > 50`（5分）、`voxel_stream_fail > 10`（5分）で Discord Webhook 通知。

## 5. セキュリティ・リスク管理
- 権限管理: GitHub では必ず 2FA、Protected Branch + CODEOWNERS。サーバ鍵は `operations/secrets/` で SOPS 管理。
- インシデント対応: PagerDuty（候補）または Discord でオンコール連絡。インシデント記録は `operations/incidents/2025-xx-xx.md` へテンプレート化。
- 攻撃対策: DDoS は Cloudflare Spectrum（検討中）、チート検知は `analytics/anti_cheat.jsonl` にサーバ照合ログを出力し、異常行動を検知。

## 6. 継続タスク
- レガシー移植: `archive/legacy_unreal/Zero_Budget_Dev_Operations_Guide.md` のローカルテスト手順を Godot 向けにリライトし、`operations/local_testing.md` としてまとめる。
- Runbook 作成: 障害発生時の再起動手順、DB ロールバック、ボクセルチャンク修復マニュアルを順次追加。
- 品質指標: MTTR/MTBF を定義し、四半期ごとに改善状況をレビュー。
