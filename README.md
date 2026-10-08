# yukicoder (Rust)

`../atcoder/` と同じく、Rust 1.89.0 / Edition 2024、cargo-compete、cargo-equip を使います。
ビルド先はルートの `target/` にまとめ、rust-analyzer は個別問題用の `problems` と作業中のコンテストだけを読み込みます。

## 準備

この環境には必要なツールがインストール済みです。別の環境では次を実行してください。

```bash
rustup toolchain install 1.89.0 --component rust-src --component rust-analyzer --component rustfmt
cargo +stable install cargo-compete --locked
cargo +stable install cargo-equip --locked
rustup toolchain install nightly
cargo +stable install cargo-udeps --locked
```

補助スクリプトには Bash、クリップボード用スクリプトには Python 3 も必要です。以下の例はプロジェクトのルートから始めます。
AtCoder 側の `compnew` と混同しないよう、`./scripts/compnew` を指定します。

## コンテスト

URL が `https://yukicoder.me/contests/296` なら ID は `296` です。

```bash
./scripts/compnew 296
cd contest296
# src/bin/ 以下の生成された解答を編集
cargo compete test <エイリアス>
cargo compete submit <エイリアス>
```

エイリアスと問題 URL は生成先の `Cargo.toml` の
`package.metadata.cargo-compete.bin` で確認できます。
`compnew` には `--open` や `--problems` などの cargo-compete のオプションも渡せます。
既存ディレクトリは上書きしません。

過去のコンテストに戻る場合は、ルートで次を実行します。

```bash
./scripts/compuse contest296
cd contest296
```

`compuse` はルートの `Cargo.toml` を生成し直します。常に `problems` と選択したコンテストが
ワークスペースの対象になり、それ以外のコンテストのファイルは残ります。
個別問題だけを対象に戻すには `./scripts/compuse problems` を使います。

## 個別問題

```bash
cd problems
cargo compete add 9001
# src/bin/9001.rs を編集
cargo compete test 9001
cargo run --release --bin 9001
cargo compete submit 9001
```

`add` には URL の `/problems/no/9001` にある公開問題番号を指定します。
ソースは `problems/src/bin/<番号>.rs`、サンプルは `problems/testcases/<番号>.yml` に保存されます。
別の問題も同じディレクトリで `cargo compete add <番号>` により追加できます。

## 提出用コードの生成

`cargo compete submit` はサンプルテスト後、cargo-equip で `cp_library` などを展開して
言語 ID `rust` で提出します。提出には yukicoder の API キーが必要です。
認証情報は cargo-compete の案内に従って設定してください。

Web 画面から提出する場合は、問題のパッケージ内で次を実行します。

```bash
../scripts/cargo-equip-clip.sh 9001
# ファイルに保存する場合
cargo equip --bin 9001 --exclude proconio num itertools ac-library-rs --remove docs --minify libs --mine github.com/itto4869 > ../submission.rs
```

コンテストでは `9001` の代わりに `Cargo.toml` のバイナリ名を指定します。
クリップボード用スクリプトは `src/bin/<名前>.rs` の名前からもバイナリ名を解決できます。
SSH では OSC 52、WSL では `clip.exe`、その他では `pbcopy` / `wl-copy` / `xclip` / `xsel` を使用します。

## ライブラリと設定

- 初期依存は `proconio`、`itertools`、`num`、`ac-library-rs`、`cp_library` です。バージョンは AtCoder 側に合わせています。
- 追加のクレートは使用するパッケージの `Cargo.toml` に追加してください。
  今後のコンテストにも使うものは `compete.toml` の `template.new.dependencies` にも追加します。
- `./scripts/cp-library-update-clean.sh` で `cp_library` を更新してビルドキャッシュを消去できます。
- [公式実行環境](https://yukicoder.me/help/environments)にある `proconio`、`num`、`itertools`、`ac-library-rs` は展開から除外し、その他の依存ライブラリを展開します。
  AtCoder の `--exclude-atcoder-crates` は使用しません。
  クレートによっては cargo-equip が展開できないため、追加した場合は提出前にコード生成を確認してください。
- ローカルは AtCoder と同じ Rust 1.89.0 に固定しています。
  2026-10-09 に確認した [yukicoder の言語 API](https://yukicoder.me/api/v1/languages) は
  Rust 1.97.1、言語 ID `rust` を返しました。

参考: [cargo-compete](https://github.com/qryxip/cargo-compete)、[cargo-equip](https://github.com/qryxip/cargo-equip)
