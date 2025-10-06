# MMO向けクラウド構成と概算料金ガイド（プロジェクト方針反映）

更新日: 2025-08-23
対象プロジェクト: `g:/Unreal Projects/MyTEST`

---

## 前提と要件（本プロジェクトから抽出）
- サーバ権威: トレード/パーティ/メール等をサーバ側で厳密処理（`TradeServerManager.cpp` ほか）
- レプリケーション最適化: ReplicationGraph 導入を計画（`Docs/Optimization_Priorities.md`）
- セーブ→DB移行 PoC: `GameData/*.csv` をRDBへ移行
- クロスプレイ/フレンド/パーティ: EOS 連携前提が望ましい
- 観測性/CI/CD: ログ/メトリクス/アラート、オートスケール、Blue/Green

---

## 個人開発・予算ほぼゼロ向けの運用方針（開発フェーズ）
- __クラウドは使わない__: ベータまで原則ローカル/無料枠のみ。GameLift/DB/Redis/CDNは導入を先送り
- __ローカル構成__: 
  - 永続化: SQLite（シングルファイル）→ 必要時にPostgreSQL Docker（ローカルのみ）
  - キャッシュ: ゲームサーバ内メモリ（TMap等）。Redisは不要
  - 認証/フレンド: EOSの開発利用（無料）またはローカル仮ID
  - 配信/静的ファイル: GitHub Releases/Pagesやローカル共有。CDNは不要
  - 観測性: ローカルログのみ（構造化/ローテーション）。OpenSearch等は不要
  - バックグラウンド処理: Unreal タイマー/ゲームスレッドで代替（SQS/Lambdaは不要）
- __テスト運用__: 
  - まずはローカル専用 or LAN/フレンド数人。CCU<10 まで自宅マシン/一時VPS（$5–10/月）で十分
- __有料化のゲート（導入判断基準）__:
  - CCU>30 めど、外部テスター常設、障害対応の必要性→初めてマネージド導入を検討
  - 先にDBだけをクラウド化（小型PostgreSQL）→ 次にCDN→ 最後にGameLiftの順で段階導入
- __費用ゼロでの品質担保__: リグレッションは自動テスト/リプレイを最優先。ログは1日ローテーション
- __参考__: 詳細手順は `Docs/Zero_Budget_Dev_Operations_Guide.md` を参照

---

## 推奨アーキテクチャ（優先度順）

### 第1候補: AWS GameLift + EOS + Aurora(PostgreSQL) + Redis
- 用途
  - Game サーバ: AWS GameLift（Linux Dedicated 推奨）
  - 認証/フレンド/パーティ: Epic Online Services（EOS）
  - 永続化: Amazon Aurora PostgreSQL（取引・メール・銀行等の整合性）
  - キャッシュ: ElastiCache for Redis（在庫/セッション/レート制御）
  - 観測性: CloudWatch + OpenSearch + X-Ray
  - 配信: S3 + CloudFront
  - バックグラウンド: SQS + Lambda/ECS Fargate（メール添付消化、利息計算 等）
- 適合理由
  - サーバ権威のトランザクション処理にRDBが適合
  - ReplicationGraph と GameLift のスケール特性が噛み合う
  - 多リージョン展開/フェイルオーバが容易

### 第2候補: GCP GKE + Agones + EOS + Cloud SQL + Redis
- 用途
  - Game サーバ: GKE + Agones（OSSベースのDedicated運用）
  - 認証/フレンド/パーティ: EOS
  - 永続化: Cloud SQL for PostgreSQL
  - キャッシュ: Memorystore for Redis
  - 観測性: Cloud Logging/Monitoring + OpenTelemetry（Grafana/Loki可）
  - 配信: Cloud Storage + Cloud CDN
- 適合理由
  - ポータビリティが高く、マルチクラウド志向/インフラ自律運用に向く

### 第3候補: Azure PlayFab Multiplayer Servers +（必要に応じEOS/自鯖）
- 用途
  - Game サーバ: PlayFab Multiplayer Servers
  - アカウント/経済/分析: PlayFab 統合機能
  - DB/Cache: Azure SQL or Cosmos DB + Azure Cache for Redis
- 適合理由
  - TTV（立ち上げ速度）重視、管理コンソールが充実

---

## 概算料金の考え方（最新料金は公式ページをご確認ください）
料金は地域/インスタンスタイプ/トラフィック/稼働率により大きく変動します。ここでは「算出式」と「確認リンク」を提示します。

- Game サーバ（AWS GameLift / GKE+Agones / PlayFab）
  - 目安式: サーバ台数 × インスタンス時間単価 × 稼働時間 × 月日数 × 余裕係数
  - 参考: 同時接続数, 1インスタンスあたりのゲームプロセス数/セッション人数
- データベース（Aurora / Cloud SQL / Azure SQL）
  - 目安式: インスタンスタイプ単価 × 稼働時間 + ストレージ容量 × 単価 + I/O 従量
- キャッシュ（Redis）
  - 目安式: ノードサイズ単価 × 稼働時間（レプリカ数考慮）
- ネットワーク/配信（CDN, egress）
  - 目安式: 転送量(GB) × 地域別単価 + リクエスト数 × 単価
- 観測性（ログ/メトリクス/トレース）
  - 目安式: 取り込み量(GB) × 単価 + 保管期間 × 追加費用

> 注: スポット/予約（AWS）や Committed Use（GCP）で削減可。Linux Dedicated ビルドは密度/コスト面で有利。

---

## 公式料金ページ・計算ツール（ブックマーク）

### AWS
- GameLift 概算計算ガイド: https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-calculator.html
- EC2/インスタンスの料金: https://aws.amazon.com/ec2/pricing/
- Amazon Aurora（PostgreSQL）: https://aws.amazon.com/rds/aurora/pricing/
- ElastiCache for Redis: https://aws.amazon.com/elasticache/pricing/
- CloudFront（CDN）: https://aws.amazon.com/cloudfront/pricing/
- S3 料金: https://aws.amazon.com/s3/pricing/

### GCP
- GKE 料金: https://cloud.google.com/kubernetes-engine/pricing
- Agones（OSS, 自体は無料。基盤はGKE/Compute課金）: https://agones.dev/
- Cloud SQL（PostgreSQL）: https://cloud.google.com/sql/pricing
- Memorystore for Redis: https://cloud.google.com/memorystore/pricing
- Cloud CDN: https://cloud.google.com/cdn/pricing

### Azure/PlayFab
- PlayFab 料金: https://playfab.com/pricing/
- Azure VM/SQL/Redis 料金: https://azure.microsoft.com/pricing/

### EOS（Epic Online Services）
- 概要/料金: https://dev.epicgames.com/docs/epic-online-services
- 備考: EOSは基本無料（特定機能は条件あり）。商用利用可。詳細は公式ドキュメント参照。

---

## サンプル見積（入力テンプレ）
以下のパラメータを埋めて各クラウドの電卓で算出してください。

- 想定同時接続（CCU）: 例) 2,000
- 1ゲームサーバの同時収容: 例) 60プレイヤー / 1プロセス
- 1インスタンスあたりプロセス数: 例) 6
- 平均稼働率: 例) 60%
- ピーク時間帯: 例) 19:00–24:00（JST）
- インスタンスタイプ候補: 例) CPU最適 or 汎用（Linux）
- DB要求: 書込みTPS/読み込みQPS/データ容量/監査保持期間
- キャッシュ: 在庫/セッションキー件数、TTL、無停止要件（レプリカ/クラスタ）
- CDN: 月間配信GB、リクエスト数
- ログ: 月間取込GB、保持期間（7/30/90日）

## サンプル料金表（試算例・CCU=2,000）
前提（簡略）: 1サーバ収容60人/プロセス, 1インスタンス6プロセス, 平均稼働率60%, ピーク時6インスタンス規模。
通貨: USD（括弧内は概算JPY, 1 USD=¥150 換算）。正確な料金は各クラウドの電卓で再確認してください。

### AWS（GameLift + Aurora PostgreSQL + ElastiCache + CloudFront + CloudWatch）
| サービス | 概算根拠 | 月額 (USD) | 月額 (JPY) |
|---|---|---:|---:|
| Game サーバ | 6台×24h×30日×60%×$0.077（c6a.large相当, EC2+管理係数込み） | $220 | ¥33,000 |
| Aurora (Multi-AZ) | 2台×$0.29/h×24h×30日 + 100GB Storage/I/O概算 | $480 | ¥72,000 |
| Redis (ElastiCache) | 2ノード 小型クラス×$0.034/h×720h | $50 | ¥7,500 |
| CDN/転送 (CloudFront) | egress 2TB + リクエスト概算 | $175 | ¥26,250 |
| ログ/可観測性 | CloudWatch/OS 取り込み/保持/可視化 | $200 | ¥30,000 |
| 合計 |  | __$1,125__ | __¥168,750__ |

### GCP（GKE+Agones + Cloud SQL + Memorystore + Cloud CDN + Cloud Logging）
| サービス | 概算根拠 | 月額 (USD) | 月額 (JPY) |
|---|---|---:|---:|
| Game サーバ | 同等性能ノード/ポッド密度で算出（管理オーバーヘッド含む） | $230 | ¥34,500 |
| Cloud SQL (HA) | 2台×相当クラス + 100GB + I/O概算 | $470 | ¥70,500 |
| Redis (Memorystore) | 2ノード 小型 | $55 | ¥8,250 |
| CDN/転送 (Cloud CDN) | egress 2TB + リクエスト概算 | $180 | ¥27,000 |
| ログ/可観測性 | Cloud Logging/Monitoring/OTel | $190 | ¥28,500 |
| 合計 |  | __$1,125__ | __¥168,750__ |

### Azure/PlayFab（Multiplayer Servers + Azure SQL + Azure Cache + CDN + Monitor）
| サービス | 概算根拠 | 月額 (USD) | 月額 (JPY) |
|---|---|---:|---:|
| Game サーバ | 同等収容/密度。PlayFab管理加味 | $250 | ¥37,500 |
| Azure SQL (HA) | 2台×相当クラス + 100GB + I/O概算 | $500 | ¥75,000 |
| Redis (Azure Cache) | 2ノード 小型 | $60 | ¥9,000 |
| CDN/転送 | egress 2TB + リクエスト概算 | $190 | ¥28,500 |
| ログ/可観測性 | Monitor/Log Analytics | $200 | ¥30,000 |
| 合計 |  | __$1,200__ | __¥180,000__ |

> 免責: 上記は本プロジェクトの「サンプル見積」前提に基づくラフな試算です。地域/インスタンス/ディスカウント/トラフィックにより大きく変動します。

## 運用料金ポリシー（破産しないための設計）
- __単位経済の可視化__: Cost/CCU・Cost/Session・Cost/1,000 req を常時計測し、ARPU×粗利率×安全係数(0.7) 以下を目標
- __容量ミックス__: ベース=On-Demand/予約(40–60%)、変動=Spot/Preemptible(40–60%) をQueue優先度で制御
- __スケールガード__: 稼働率>75%で拡張、<35%で縮小。時間帯ごとに Min/Max 台数を強制
- __ネットワーク/配信__: CDN経由を強制、egress 閾値超で段階的画質制限と圧縮/差分配信
- __DB/Redis 方針__: 整合性=RDB、セッション/在庫はRedis先行。監査は別テーブルでローテーション
- __ログ/可観測性__: 構造化ログ+サンプリング(1–5%)、30日ホット→90日ウォーム→以降コールド/Glacier
- __金額ガードレール__: 予算アラート（日/週/月）で自動措置（非必須バッチ停止・Spot比率増・スケール上限）
- __リージョン/冗長__: ProdはMulti-AZ、DRはRTO/RPOに応じ最小限（初期はコールドスタンバイ）
- __FinOps 運用__: 週次差分レビュー→改善チケット化→2週間以内反映。タグでチーム/機能/環境別に可視化
- __開始時ターゲット__: Cost/CCU=$0.40–$0.70/月、On-Demand:Spot=40:60、ログ取込≤0.2 GB/CCU/月

## スケーリング計画（キャパシティと自動化）
- __Game サーバ__
  - GameLift Queue で複数フリート（On-Demand + Spot）を併用、目標稼働率60%を維持
  - 1台あたりプロセス密度のチューニング: `-NOSTEAM` `-log` 抑制と `ReplicationGraph` 設計でCPU/帯域を節約
- __DB/Redis__
  - Aurora: 最小2インスタンス（Multi-AZ）。読み取りレプリカでレポート系を分離
  - Redis: 重要キー（セッション/レート制御/インベントリ一時キャッシュ）はクラスタ化でスケール
- __CDN/配信__
  - アセット配信は常に CDN 経由。署名付URLを利用
- __バックグラウンド__
  - メール添付の失効処理、銀行利息計算は SQS キュー化し Lambda/ECS バッチで平滑化

## セキュリティと権限
- __IAM/権限の最小化__: ビルド/デプロイ/運用のロール分離。S3, RDS, ElastiCache, GameLift のアクセスは原則VPC内
- __ネットワーク__: VPC/サブネット分離（Public: ALB/CDN, Private: Game/DB/Redis）。Security Group は最小許可
- __秘密情報__: `AWS Secrets Manager` または `SSM Parameter Store` で管理。平文をリポジトリに置かない
- __監査/改ざん検出__: 重要トランザクションは監査ログへ二重書込。CloudTrail 有効化

## 環境構成（Dev/Staging/Prod）
- __Dev__: 最小構成。DBは単一AZ/小型、Redisは開発用1ノード、GameLiftローカル/最小フリート
- __Staging__: 本番同等のネットワーク分離/メトリクス/アラート閾値で負荷試験
- __Prod__: マルチAZ/冗長、Blue/Green または canary リリース
- __共通__: IaC（Terraform/CloudFormation）で定義し、差分を可視化

## コスト最適化の具体策
 - __インスタンス最適化__: CPU/メモリ/帯域の利用率を週次でレビューし、型を見直し
 - __予約/コミット__: 安定負荷分は RI/Committed Use、変動分は Spot/プリエンプティブ
 - __ログ/監査の寿命__: 30/90日ローテーション、OpenSearchはウォーム/コールド階層を活用
 - __キャッシュヒット率__: ヒット率<90%ならキー設計/TTL/サイズを見直す
 - __ビルドのLinux化__: Windowsよりコスト/密度で有利（既方針と一致）

## 本プロジェクトへの具体的紐づけ
 - __サーバ権威系（銀行/トレード/メール）__: Auroraのトランザクション/監査で一貫性を担保
 - __インベントリUIの予測/確定__: サーバ確認フロー後のVM再構築はサーバメトリクスとセットで監視
 - __ReplicationGraph__: 帯域削減の主軸。遠距離アクタ/非戦闘時の更新抑制ポリシーを別紙で定義

## 次アクション（実務）
 1. 料金試算: 本ドキュメントの「サンプル見積」パラメータで AWS/GCP/Azure 各電卓に入力し比較表を作成
 2. IaC 初期雛形の作成: VPC/サブネット/SG + Aurora/Redis + GameLift の最小スタック
 3. データ移行 PoC: `GameData/*.csv` の items/inventory をステージングへロードし、API 1本を DB 切替
 4. 監視雛形: CloudWatch ダッシュボードと 5 つの基本アラームを作成
 5. セキュリティ点検: Secrets 管理と最小権限ロールの棚卸し

---

## まとめ
- 第一候補: __AWS GameLift + EOS + Aurora(PostgreSQL) + Redis__
- 第二候補: __GKE + Agones + EOS + Cloud SQL__
- 第三候補: __Azure PlayFab__（TTV重視）

最新料金は上記リンクの計算ツールで都度確認してください。必要に応じ、当プロジェクトの想定同時接続/収容/TPS を用いた見積シートを追加します。

## リスクと注意
- Overlayの二重起動（Steam/EOS）は避ける
- RDBのロック競合/スロークエリ監視（監査テーブルはアーカイブ設計）
- インスタンス/リージョン障害時のQueue/スケール方針
- コスト監視: 予算/アラート/タグ整備
