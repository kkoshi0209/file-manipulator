SCRIPT = "ruby #{File.basename(__FILE__)}"
LOG_FILE = 'history.log'

# サブコマンドの一覧（引数の数チェックとヘルプはここから作られる）
COMMANDS = {
  'reverse' => {
    args: %w[inputpath outputpath],
    description: 'inputpath の内容を逆順にして outputpath に書き出す'
  },
  'copy' => {
    args: %w[inputpath outputpath],
    description: 'inputpath の内容を outputpath にコピーする'
  },
  'duplicate-contents' => {
    args: %w[inputpath n],
    description: 'inputpath の内容を n 回繰り返して上書きする'
  },
  'replace-string' => {
    args: %w[inputpath needle newstring],
    options: %w[--ignore-case],
    description: 'needle をすべて newstring に置き換えて上書きする（--ignore-case で大文字小文字を区別しない）'
  },
  'line-count' => {
    args: %w[path],
    description: 'path の行数を表示する'
  },
  'head' => {
    args: %w[path n],
    description: 'path の先頭 n 行を表示する'
  },
  'help' => {
    args: [],
    description: 'このヘルプを表示する'
  },
}.freeze

# 使い方の間違いやファイルの問題を表す自作の例外
class CommandError < StandardError; end

# === 補助メソッド ===

# 1 つのコマンドの使い方を組み立てる
def usage(name)
  spec = COMMANDS.fetch(name)
  args = spec[:args].map { |arg| "<#{arg}>" }
  options = spec.fetch(:options, []).map { |opt| "[#{opt}]" }
  ([SCRIPT, name] + args + options).join(' ')
end

def print_help
  puts '使い方:'
  COMMANDS.each do |name, spec|
    puts "  #{usage(name)}"
    puts "      #{spec[:description]}"
  end
end

# 1 以上の整数に変換する（変換できなければ CommandError）
def parse_count(value, label)
  n = Integer(value, 10)
  raise CommandError, "#{label} には 1 以上の整数を指定してください: #{value}" if n < 1

  n
rescue ArgumentError
  raise CommandError, "#{label} には整数を指定してください: #{value}"
end

def read_file(path)
  File.read(path)
rescue Errno::ENOENT
  raise CommandError, "ファイルが見つかりません: #{path}"
rescue Errno::EISDIR
  raise CommandError, "ディレクトリは指定できません: #{path}"
rescue Errno::EACCES
  raise CommandError, "ファイルを読み込む権限がありません: #{path}"
end

def write_file(path, contents)
  File.write(path, contents)
rescue SystemCallError => e
  raise CommandError, "書き込みに失敗しました: #{path}（#{e.message}）"
end

# 実行内容と日時を history.log に追記する
def write_log(status)
  time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  File.open(LOG_FILE, 'a') do |file|
    file.puts "#{time} [#{status}] #{ARGV.join(' ')}"
  end
rescue SystemCallError => e
  warn "ログを書き込めませんでした: #{e.message}"
end

# === サブコマンド ===

def do_reverse(input_path, output_path)
  write_file(output_path, read_file(input_path).reverse)
  puts "#{output_path} に逆順の内容を書き出しました"
end

def do_copy(input_path, output_path)
  write_file(output_path, read_file(input_path))
  puts "#{input_path} を #{output_path} にコピーしました"
end

def do_duplicate_contents(input_path, n)
  write_file(input_path, read_file(input_path) * n)
  puts "#{input_path} の内容を #{n} 回繰り返しました"
end

def do_replace_string(input_path, needle, new_string, ignore_case: false)
  contents = read_file(input_path)

  # --ignore-case のときは、大文字小文字を区別しない正規表現で探す
  pattern =
    if ignore_case
      Regexp.new(Regexp.escape(needle), Regexp::IGNORECASE)
    else
      needle
    end

  count = contents.scan(pattern).length
  write_file(input_path, contents.gsub(pattern) { new_string })
  puts "#{count} か所を置き換えました"
end

def do_line_count(path)
  puts read_file(path).lines.count
end

def do_head(path, n)
  puts read_file(path).lines.first(n)
end

# === コマンドの振り分け ===

def run(command, args)
  if command.nil?
    raise CommandError, "コマンドを指定してください。#{SCRIPT} help で使い方を確認できます"
  end

  spec = COMMANDS[command]
  if spec.nil?
    raise CommandError, "不明なコマンドです: #{command}。#{SCRIPT} help で使い方を確認できます"
  end

  # -- で始まる引数をオプション、それ以外を通常の引数に分ける
  options, params = args.partition { |arg| arg.start_with?('--') }

  unknown = options - spec.fetch(:options, [])
  unless unknown.empty?
    raise CommandError, "不明なオプションです: #{unknown.join(' ')}\n使い方: #{usage(command)}"
  end

  unless params.length == spec[:args].length
    raise CommandError, "引数の数が正しくありません\n使い方: #{usage(command)}"
  end

  case command
  when 'reverse'            then do_reverse(*params)
  when 'copy'               then do_copy(*params)
  when 'duplicate-contents' then do_duplicate_contents(params[0], parse_count(params[1], 'n'))
  when 'replace-string'     then do_replace_string(*params, ignore_case: options.include?('--ignore-case'))
  when 'line-count'         then do_line_count(*params)
  when 'head'               then do_head(params[0], parse_count(params[1], 'n'))
  when 'help'               then print_help
  end
end

def main
  args = ARGV.dup
  command = args.shift
  run(command, args)
  write_log('OK')
rescue CommandError => e
  warn "エラー: #{e.message}"
  write_log("ERROR: #{e.message.lines.first.chomp}")
  exit 1
end

main if __FILE__ == $PROGRAM_NAME
