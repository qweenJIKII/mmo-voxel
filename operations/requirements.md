# 必須ツール要件 (2025-10-06)

| ツール | 推奨バージョン | 用途 | インストールメモ |
|--------|----------------|------|------------------|
| Godot Engine | 4.6.stable | ゲーム本体のビルド・実行 | https://godotengine.org/download からエディタとテンプレートを取得し、パスを通す |
| Git | 2.44+ | バージョン管理 | https://git-scm.com/downloads |
| Python | 3.11.x | ツールスクリプト・自動化 | `pyenv` または Microsoft Store 版を利用可 |
| Node.js | 20.x LTS | Web ダッシュボード/ツール | https://nodejs.org/ |
| PowerShell | 7.4+ | ローカルビルドスクリプト | Windows 11 では既定で 7.x。`winget install Microsoft.PowerShell` |
| Docker | 27.x | サーバ/モニタリング環境のコンテナ化 | `docker compose` v2 が利用できること |

## 初期セットアップ手順
1. Godot 4.6 をインストールし、`godot` コマンドをパスに追加。
2. リポジトリを `git clone` したら、`pwsh ./tools/scripts/setup-project.ps1` を実行してローカル設定を初期化。
3. Godot エディタでプロジェクトを開き、`export_presets.cfg` に `Windows Desktop` / `Dedicated Server` プリセットを追加し、出力先を `build/windows` / `build/server` に設定（初回のみ）。
4. `pwsh ./operations/scripts/build.ps1 -Target windows` を実行してエクスポートが成功することを確認。
5. `docker --version` と `docker compose version` で動作確認。

## 参考
- CI 上では GitHub Actions の `ubuntu-latest` ランナーを利用し、`chickensoft-games/setup-godot@v1` で Godot 4.6 を取得。
- ツールバージョンの更新は本ファイルと `Docs/operations/README.md` を同時に改訂する。
