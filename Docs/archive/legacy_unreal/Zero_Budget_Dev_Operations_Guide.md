# 個人開発・予算ほぼゼロ向け 運用手順ガイド（開発フェーズ）

更新日: 2025-09-03
対象プロジェクト: `g:/Unreal Projects/MyTEST`
関連ドキュメント: `Docs/Cloud_MMO_Architecture_and_Pricing.md`

---

## 目的と前提
- 目的: ベータ前までクラウド費用を発生させずに、開発〜小規模テストを成立させる具体手順を示す。
- 対象: 個人開発者 / 予算ゼロ〜極小 / 初めてのオンライン開発。
- 重要方針: クラウド導入は段階的（DB→CDN→Game サーバ）。有料化のゲートを明確化。

---

## フェーズ0: ローカル完結構成（ゼロコスト）

### 1. データ永続化（SQLite）
- 既定: `Saved/` 配下に SQLite ファイルを配置（例: `Saved/Database/MyTEST.sqlite3`）。
- 推奨スキーマ: 将来の PostgreSQL 互換を意識した型/制約（`TEXT`/`INTEGER`/`NUMERIC`、外部キー、インデックス）。
- バックアップ: 起動/終了時にローテーション（`*.bak` 3世代）。

例: インベントリ/メールの最小スキーマ（参考）
```sql
-- Inventory
CREATE TABLE IF NOT EXISTS inventory (
  player_id TEXT NOT NULL,
  item_id   TEXT NOT NULL,
  amount    INTEGER NOT NULL CHECK (amount >= 0),
  meta_json TEXT,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (player_id, item_id)
);
CREATE INDEX IF NOT EXISTS idx_inventory_updated ON inventory(updated_at);

-- Mail (inbox)
CREATE TABLE IF NOT EXISTS mail (
  mail_id    TEXT PRIMARY KEY,
  player_id  TEXT NOT NULL,
  subject    TEXT NOT NULL,
  body       TEXT NOT NULL,
  attachments_json TEXT NOT NULL,
  expire_at  INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  claimed    INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_mail_player ON mail(player_id);
```

#### Editor コンソール最小運用コマンド例（ローカル検証）
- 実行場所: UE エディタの Output Log または PIE のチルトキー（~）コンソール
- 目的: スキーマ適用、バックアップ、メール/インベントリの動作確認を最小コマンドで実施

```
# スキーマ/バックアップ/セルフテスト
sqlite.EnsureSchema
sqlite.BackupNow
sqlite.SelfTest

# Mail（例: PlayerId=p01）
mail.Send p01 "Test Subject" "Hello Body" 604800
mail.List p01
mail.ClaimAll p01
mail.SweepNow

# Inventory（例: PlayerId=p01）
inv.Add p01 wood 10 {}
inv.List p01
inv.Remove p01 wood 5

# Bank（口座残高の確認のみ・参考）
bank.ShowBalance p01 Gold
```

> 補足: `mail.Send` の末尾 `604800` は失効までの秒数（7日）。`inv.Add` の第5引数 `{}` は任意のメタ情報（JSON）。

---

### 2. サーバ起動（ローカル Dedicated）
- Windows/Linux ローカルで Dedicated 実行。
- ログを構造化（JSON Lines）で出力、1日ローテーション。

    例: 起動パラメータ（参考・環境に合わせて調整）
    ```bash
    # Windows PowerShell 例（実行は各自の環境で）
    UnrealEditor-Cmd.exe MyTEST -server -log -PORT=7777 -UNATTENDED -NOSTEAM -logCmds="global off, category=Net verbosity=Log" \
      -MyJsonLog=Saved/Logs/server_%Y%m%d.jsonl -MyLogRotate=1d
    ```

    #### エディタ併用テスト（専用サーバーを動かしながら検証）
    - __方法A: エディタから「専用サーバーで再生」__
      1. UE5エディタ右上の「Play」▼ → 「Advanced Settings…」
      2. Multiplayer Options:
         - Number of Players: 任意（1でも可）
         - Net Mode: Play as Client
         - Run Dedicated Server: チェック
      3. 「Play」を押すと、専用サーバープロセスとPIEクライアントが起動

    - __方法B: 外部専用サーバープロセス + エディタから接続__
      1. サーバ起動（例）
         - `MyTESTServer.exe <マップ名>?listen -log -PORT=7777 -UNATTENDED -NOSTEAM`
         - または `UnrealEditor-Cmd.exe MyTEST <マップ名>?listen -server -log -PORT=7777 -UNATTENDED -NOSTEAM`
      2. エディタ側: Play設定で Net Mode=Play as Client を選択
      3. PIE/エディタコンソールで `open 127.0.0.1:7777` で接続

    - __注意/トラブルシューティング__
      - 同一ビルド・同一マップでないと接続不可（バージョン不一致エラーに注意）
      - Windowsファイアウォールで UDP 7777 を許可
      - 開発中は `-NOSTEAM` を付与し、EOS/Steamの重複ログインを避ける
      - 負荷検証はPIE複数より外部クライアント実行が実態に近い
      - ログ: サーバは `-log` コンソール、クライアントはエディタ `Output Log` を確認

### 3. 認証/フレンド
- 開発中は EOS Dev（無料）を利用、外部公開は行わない。
- 代替としてゲストID（ローカル擬似アカウント）も可。

### 4. 観測性（ローカルのみ）
- JSON Lines で構造化。例: `{"ts": 1690000000, "lvl": "INFO", "cat": "trade", "msg": "order created", "player": "p01"}`
- ローテーション: 1日、サイズ上限 100MB 目安。古いログは 7日で削除。
- 最低限のメトリクス: 1分粒度で CSV 追記（`tick_rate`, `conn`, `ram_mb`, `cpu_pct`）。
 - HUD はサーバの実動作（メール受領/Inventory 増減/Party イベント）を可視化する開発用UI。特別な Ops 変更は不要（JSONL/KPI と補完）。

#### メールボックスUI（おすすめ実装タイミング：ローカル検証）
- 前提: `UMailboxComponent` の一括受領RPC導線が実装済（`Server_ClaimAllAttachments` → `UMailDAO::ClaimAll` → `Client_OnClaimAllCompleted`）。`BeginPlay` でレプリ未設定の警告ログあり
- バインド: 受領ボタン → `ClaimAllAttachmentsForCurrentPlayer()`
- 通知/更新: `OnMailClaimAllCompleted`（受領件数トースト）/ `OnMailUpdated`（一覧再取得・再描画）
- レプリ: Owning Actor の `bReplicates=true` 必須。`UMailboxComponent` は既定で Replicate
- スモーク: PIE（2C1S or Dedicated）で実行 → 受領ボタン押下 → サーバログで `ClaimAll` → クライアントでトースト/一覧更新。必要に応じ `mail.Send/ClaimAll` コンソールで比較

### 5. バックグラウンド処理
- Unreal のタイマー/タスクで代替。キュー/ワーカー（SQS/Lambda 等）は導入しない。
- 例: 1分おきにメール失効チェック、5分おきに銀行利息計算をバッチ実行。

---

## フェーズ1: 公開ミニテスト（月 $5 前後）

### 1. 最安VPSの用意
- 推奨: Hetzner CX11 / Contabo 最小 / 代替: Oracle Cloud Always Free（在庫運）。
- 想定: CCU < 10–20、単一障害点を許容。

### 2. セキュリティ初期設定
- 新規ユーザ作成、SSH 公開鍵ログイン、UFW/Windows Firewall、不要ポート遮断。
- ゲームポートのみ開放（例: UDP 7777）。

### 3. PostgreSQL（同居 or Docker）
- 同一VPSに Postgres を導入し、毎日自動バックアップ。
- 例: Docker Compose（参考）
```yaml
version: "3.8"
services:
  db:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: mytest
      POSTGRES_PASSWORD: change_me
      POSTGRES_DB: mytest
    volumes:
      - ./pgdata:/var/lib/postgresql/data
      - ./backup:/backup
    ports:
      - "5432:5432"
```

バックアップ例（cron想定）
```bash
# 毎日3:30にバックアップ（例）
pg_dump -U mytest -d mytest -F c -f /backup/pg_$(date +%Y%m%d).dump
find /backup -type f -name 'pg_*.dump' -mtime +7 -delete
```

### 4. Unreal Dedicated を同居実行
- 1プロセス運用から開始。メモリ/CPU/帯域を監視。
- 障害時は自動再起動（systemd など）を設定。

### 5. CDN/静的配信（任意）
- Cloudflare Free を前段に置き、静的コンテンツだけ配信。
- 大容量配信を避け、最小限のパッチ/画像に限定。

---

## 有料化のゲート（導入判断の詳細）
- CCU > 30 が連日観測、または外部テスターの常設化 → 初めてマネージド導入を検討。
- 導入順序:
  1) DB を小型クラウドへ（例: Supabase/Neon 最小 or マネージド小プラン）
  2) CDN / 画像ストレージ（Cloudflare R2 + CDN）
  3) Game サーバ（GameLift/PlayFab/Agones など）

---

## KPIと運用メトリクス
- Cost/CCU（月）: 目標 $0.40–$0.70。
- サーバ: CPU/メモリ/帯域、セッション数、TickRate。
- DB: QPS/TPS、スロークエリ、ロック待ち、ストレージ使用量。
- ネットワーク: egress/リクエスト数（CDN移行前後の差）。
- 障害: 平均復旧時間（MTTR）、失敗率。

---

## リスクと回避策
- 単一障害点: 受容し、バックアップと自動再起動で緩和。
- データ破損: 毎日バックアップ + 復元テスト。
- 無料枠の罠: スリープ/帯域制限でテストが中断する可能性。必要時のみ少額課金へ。
- ベンダーロック: 将来移行を想定し、DBスキーマ/ネット処理は抽象化層で隠蔽。

---

## チェックリスト（実施順）
- [ ] SQLite スキーマ作成・バックアップ 3世代
- [ ] ローカル Dedicated 起動/停止スクリプト整備
- [ ] 構造化ログ（JSONL）と1日ローテ設定
- [ ] KPI 収集（1分粒度CSV）
- [ ] 最安VPS 手配（必要時）
- [ ] Postgres 導入 + 毎日バックアップ
- [ ] 自動再起動（systemd 等）
- [ ] CDN（任意）
- [ ] 有料化ゲートの数値を定義（CCU、障害頻度 等）

---

## 付録: 参考コマンド（環境に応じて調整）
```bash
# Unreal Dedicated（例）
UnrealEditor-Cmd.exe MyTEST -server -log -PORT=7777 -UNATTENDED -NOSTEAM \
  -logCmds="global off, category=Net verbosity=Log"

# Linux systemd サービス例（参考）
[Unit]
Description=MyTEST Dedicated Server
After=network.target

[Service]
Type=simple
ExecStart=/opt/mytest/MyTESTServer.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

## フェーズ2以降: AWS GameLift + EOS + Aurora(PostgreSQL) + Redis への移行手順
本章は、ゼロコスト構成から本番志向のマネージド構成へ段階移行するための実務ステップを示します。

### 0) 前提/準備
- AWS アカウント作成、リージョン選定（候補: ap-northeast-1）。
- ドメイン/DNS（Cloudflare or Route53）。
- VPC 最小構成: Public(ELB/CDN用)・Private(Game/DB/Redis) サブネット。SGは最小許可。
- ビルド: Unreal Linux Dedicated を作成（LinuxServer ビルド）。
- 機密情報: `AWS Secrets Manager` にDB/Redis/EOSキー等を格納。

### 1) DB移行: SQLite → PostgreSQL → Aurora
- スキーマ整備: 既存SQLiteをPostgreSQL互換に合わせる（主キー/外部キー/INDEX/UNIQUE制約）。
- データ抽出: テーブルごとにCSV出力 or `sqlite3 .dump` → 変換。
- ロード先（段階案）:
  1. 一時: ローコストPostgreSQL（VPS内 or Supabase/Neon最小）で検証。
  2. 本番: Amazon Aurora PostgreSQL（最小クラス/単一AZで開始→後にMulti-AZ）。
- 検証: 参照系から切替→書込系をカナリア（1%→10%→100%）。
- 注意: タイムゾーンはUTC固定、ID生成は衝突回避（UUID推奨）、金額はDECIMALで扱う。

### 2) Game サーバ: GameLift 導入
- ビルド登録: Linux Dedicated を GameLift へアップロード。
- フリート作成: On-Demand と Spot の2種を作成、`Queue` に束ねる。
- ランタイム設定: 1インスタンスあたりのプロセス数、ヘルスチェック/ログパス、`-log` 抑制等。
- スケールガード: 稼働率>75%で拡張、<35%で縮小。時間帯ごとの Min/Max を設定。
- ネットワーク: 必要ポートのみ開放（UDP 7777 等）。
- マッチメイク: 必要に応じ FlexMatch（任意）。

### 3) キャッシュ: ElastiCache for Redis
- 段階導入: 開発=単一ノード→本番=プライマリ+レプリカ（小型）。
- 用途: セッション/レート制御/一時インベントリ。重要データはRDBが一次記録。
- 運用: TTL必須、キー設計（名前空間/バージョン付与）、バックアップ不要（失って良い設計）。

### 4) 配信: S3 + CloudFront
- S3 バケットを作成し静的アセットを配置、オリジンアクセスと署名URLを利用。
- CloudFront でキャッシュ/圧縮/帯域削減。大容量は差分配信を基本に。

### 5) 観測性: CloudWatch + OpenSearch + X-Ray（段階）
- 最小: CloudWatch Logs にサーバログを出力、基本メトリクス/アラームを設定。
- 次段階: OpenSearch で全文検索、X-Rayで遅延分析。
- 基本アラーム（例）: CPU>80% 5分継続、メモリ/ディスク高水位、プロセス死活監視、DB接続失敗率、egress急増。

### 6) バックグラウンド: SQS + Lambda/ECS Fargate
- キュー化: メール失効、銀行利息計算、バッチ通知などをSQSへ。
- ワーカー: Lambda（小処理）/Fargate（重処理）。冪等性（idempotency key）とリトライ/デッドレター設定。

### 7) セキュリティ/権限
- IAM最小権限、環境別ロール分離（Dev/Stg/Prod）。
- Secrets Manager/SSM Parameter Store を使用。VPC内通信を原則とする。

### 8) 切替（ローリング）計画
1. フリーズ宣言 → フルバックアップ（DB/バイナリ）。
2. カナリア: 小規模テスト（1%）→ エラー/コスト/メトリクス監視。
3. 段階拡大: 10%→50%→100%。
4. ロールバック: 失敗時は直前スナップショット/旧環境に即戻す手順を事前整備。

### 9) コストとガードレール（初期設定）
- 目標: Cost/CCU = $0.40–$0.70/月。
- 予約/Spot: On-Demand:Spot ≈ 40:60 を目安（Queue優先度で制御）。
- スケジュール: 夜間/閑散帯の Min 台数を 0〜1 に制限。
- 予算アラーム: 日/週/月の多段アラート、超過時は自動措置（非必須バッチ停止・スケール上限）。

### 10) IaC TODO（最低限）
- VPC/サブネット/SG
- Aurora(PostgreSQL) 最小構成
- ElastiCache Redis（開発→本番）
- S3 + CloudFront（署名URL）
- GameLift フリート/キュー/スケーリングポリシー
- CloudWatch ダッシュボード + 基本アラーム
- SQS + Lambda（サンプル関数）

#### チェックリスト（移行）
- [ ] スキーマ/データ移行（SQLite→PostgreSQL→Aurora）とリハーサル完了
- [ ] GameLift フリート: On-Demand/Spot + Queue + Min/Max 時間帯設定
- [ ] Redis キー設計/TTL/監視
- [ ] S3/CloudFront 配信テスト（署名URL/キャッシュ検証）
- [ ] CloudWatch ログ出力/基本アラーム
- [ ] SQS/Lambda バッチ冪等性テスト
- [ ] 予算アラート・自動措置の検証
- [ ] ロールバック手順の検証（演習）
