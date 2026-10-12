# File Manipulator

テキストファイルの内容をコマンドラインから操作する Ruby 製のツールです。
逆順・コピー・繰り返し・文字列置換などのサブコマンドを備えています。

## 動作環境

- Ruby 3.0 以上（標準ライブラリのみ使用。追加の gem は不要）

## 使い方

```bash
ruby file_manipulator.rb <サブコマンド> [引数...]
```

使い方の一覧は `help` で表示できます。

```bash
ruby file_manipulator.rb help
```

## サブコマンド

| サブコマンド | 引数 | 説明 |
| ------------ | ---- | ---- |
| `reverse` | `<inputpath> <outputpath>` | inputpath の内容を逆順にして outputpath に書き出す |
| `copy` | `<inputpath> <outputpath>` | inputpath の内容を outputpath にコピーする |
| `duplicate-contents` | `<inputpath> <n>` | inputpath の内容を n 回繰り返して上書きする |
| `replace-string` | `<inputpath> <needle> <newstring> [--ignore-case]` | needle をすべて newstring に置き換えて上書きする |
| `line-count` | `<path>` | path の行数を表示する |
| `head` | `<path> <n>` | path の先頭 n 行を表示する |
| `help` | なし | ヘルプを表示する |

> **注意**：`duplicate-contents` と `replace-string` は、入力ファイルを直接上書きします。必要に応じて事前に `copy` でバックアップを取ってください。

### オプション

- `--ignore-case`（`replace-string` のみ）：大文字小文字を区別せずに置換します。引数のどの位置に書いても認識されます。

## 実行例

```
$ echo 'Hello hello HELLO' > a.txt

$ ruby file_manipulator.rb copy a.txt b.txt
a.txt を b.txt にコピーしました

$ ruby file_manipulator.rb reverse a.txt c.txt
c.txt に逆順の内容を書き出しました

$ ruby file_manipulator.rb replace-string b.txt hello Hi --ignore-case
3 か所を置き換えました

$ cat b.txt
Hi Hi Hi

$ ruby file_manipulator.rb duplicate-contents b.txt 2
b.txt の内容を 2 回繰り返しました

$ ruby file_manipulator.rb line-count b.txt
2

$ ruby file_manipulator.rb head b.txt 1
Hi Hi Hi
```

## エラー処理

次のような場合は、処理を行わずにエラーメッセージを表示します。

- サブコマンドが未指定、または存在しない
- 引数の数が正しくない（そのコマンドの使い方もあわせて表示）
- 存在しないオプションが指定された
- `n` が 1 以上の整数でない
- ファイルが存在しない、ディレクトリが指定された、読み書きの権限がない

```
$ ruby file_manipulator.rb copy a.txt
エラー: 引数の数が正しくありません
使い方: ruby file_manipulator.rb copy <inputpath> <outputpath>

$ ruby file_manipulator.rb copy nothing.txt b.txt
エラー: ファイルが見つかりません: nothing.txt
```

エラーメッセージは標準エラー出力に表示され、終了ステータスは `1` になります。正常終了時は `0` です。

## 実行ログ

実行するたびに、日時・結果・引数が `history.log` に 1 行ずつ追記されます。ファイルがなければ自動で作成されます。

```
2026-10-12 15:00:12 [OK] help
2026-10-12 15:00:30 [ERROR: 引数の数が正しくありません] copy a.txt
2026-10-12 15:01:05 [OK] replace-string b.txt hello Hi --ignore-case
```

## サブコマンドの追加方法

1. `COMMANDS` に、コマンド名・引数・説明を追加する（ヘルプと引数の数チェックに自動で反映されます）
2. 処理を行う `do_xxx` メソッドを定義する
3. `run` メソッドの `case` に `when` を 1 行追加して、作ったメソッドを呼び出す
