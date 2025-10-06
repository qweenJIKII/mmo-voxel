# Git 運用前提の環境構築手順

更新日: 2025-10-06（最新安定版利用を前提に随時更新）
担当: TODO

## 1. リポジトリ初期化
- リモート: `git@github.com:qweenJIKII/mmo-voxel.git`。クローン時は SSH を推奨。
- クローン:
  ```powershell
  git clone git@github.com:qweenJIKII/mmo-voxel.git
  Set-Location mmo-voxel
  git submodule update --init --recursive
  ```
- ブランチ戦略: `main`（安定） + `develop`（最新） + `feature/*`。Pull Request ベースで運用。

## 2. Godot ソースビルド
_GDExtension を利用するため公式バイナリではなくソースビルドを使用する。_

1. Godot ソース取得（最新安定版タグを使用）
   ```powershell
   git clone https://github.com/godotengine/godot.git godot-source
   Set-Location godot-source
   git fetch --tags
   $env:GODOT_TAG = "4.5-stable"     # 例: 最新安定版タグ。新リリース時は更新
   git checkout $env:GODOT_TAG
   ```
2. 依存関係インストール（Windows 例）
   - Visual Studio 2022 + Desktop development with C++
   - Python 3.11, SCons 4.6 (`pip install scons==4.6.0`)
3. エディタビルド
   ```powershell
   scons p=windows target=editor vsproj=yes
   ```
   完了後、`./bin/godot.windows.editor.x86_64.exe` を配置。
4. エクスポートテンプレート
   ```powershell
   scons p=windows target=template_release
   scons p=windows target=template_debug
   ```
   生成物を `bin/` → プロジェクト `tools/godot/bin/` へコピー。

## 3. GDExtension 開発セットアップ
- `godot-cpp` サブモジュールを追加（未追加の場合）
  ```powershell
  git submodule add https://github.com/godotengine/godot-cpp.git extern/godot-cpp
  Set-Location extern/godot-cpp
  git fetch --tags
  $env:GODOTCPP_TAG = $env:GODOT_TAG    # Godot 本体と同じタグに合わせる（例: 4.5-stable）
  git checkout $env:GODOTCPP_TAG
  scons platform=windows target=release
  scons platform=windows target=debug
  ```
- `extern/` 配下にビルド生成物を配置し、`build/` は `.gitignore` 済みか確認。

## 4. プロジェクト初期設定
1. `project.godot` を `tools/godot/bin/godot.windows.editor.x86_64.exe` で開く。
2. AutoLoad 設定（`Project -> Project Settings -> AutoLoad`）で `res://autoload/GameState.gd` 等を登録。
3. Git に含めないファイル
   - `build/`、`bin/`、`user://` 相当は `.gitignore` で除外。
   - `*.scons_cache`, `*.import/` は必要に応じてクリーン対象に追加。

## 5. CI/CD 連携
- GitHub Actions（例: `.github/workflows/build.yml`）で以下を実行
  - Godot ソース取得 & キャッシュ
  - `extern/godot-cpp` ビルド
  - プロジェクトの GDExtension ライブラリビルド
  - Godot CLI によるエクスポート
- 成果物を `actions/upload-artifact` で保存し、チーム全体が利用可能にする。

## 6. 運用ルール
- コミット: Conventional Commits (`feat:`, `fix:`, `docs:`)。
- レビュー: 最低 1 名のレビュー承認が必要。CI をパスした状態でマージ。
- バージョニング: タグ `v0.x.y` を付与し、Godot テンプレートビルドと一致させる。
- バイナリの共有: Git LFS は使用しない。ビルド成果物はアーカイブにまとめ、内部パッケージレジストリorリリースページで管理。

## 7. トラブルシューティング
- **scons ビルド失敗**: Visual Studio コマンドプロンプトを使用し、`vcvars64.bat` を事前に呼び出す。
- **godot-cpp の ABI 不一致**: Godot ソースと同一タグ (4.3) でビルドし直す。
- **サブモジュール更新漏れ**: `git submodule update --remote --merge` を定期実行。
