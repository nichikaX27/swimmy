module Swimmy
  module Command
    class Homework < Swimmy::Command::Base

      command "homework" do |client, data, match|
        # 本日の日付を取得
        date = Time.now.strftime("2026年04月13日")
        # Rust CLIのディレクトリに移動してコマンド実行
        cli_dir = ENV['RASk_CLI_LOCATION']
        cli_path = "#{cli_dir}/target/debug/rask-cli"
          result = Dir.chdir(cli_dir) do
            `#{cli_path} search-documents --date "#{date}" 2>&1`
          end
          require 'json'
        names = []
        begin
          json = JSON.parse(result)
          json.each do |doc|
            desc = doc["description"]
            next unless desc
            # \u003eを>に変換
            desc = desc.gsub(/\\u003e/, ">")
            # -->(...) まで全体を抽出（前に空白や改行があってもOK）
            desc.scan(/--\s*>\s*(\([^\)]*\))/).each do |m|
              names << m[0]
            end
          end
        rescue JSON::ParserError
          # JSONでなければ全体から-->(...)を抽出
          text = result.gsub(/\\u003e/, ">")
          names = text.scan(/--\s*>\s*(\([^\)]*\))/).flatten
        end
        if names.empty?
          client.say(channel: data.channel, text: "宿題はありません．")
        else
          client.say(channel: data.channel, text: "宿題担当: #{names.uniq.join(", ")}")
        end
      end
      help do
        title "homework"
        desc "宿題の有無を表示します．"
        long_desc "homework\n" +
                  "会議の議事録に記載された宿題を表示します．"  
      end


    end # class Homework
  end # module Command
end # module Swimmy

