module Swimmy
  module Command
    class Homework < Swimmy::Command::Base
      command "homework" do |client, data, match|
        require 'date'
        cli_dir = "/home/abo-n/git/RASK_CLI_TEMPLATE"
        cli_path = "#{cli_dir}/target/debug/rask-cli"
        # 1週間前の日付（0埋めなし/あり両方）
        date_obj = Date.today - 7
        date_no_zero = "#{date_obj.year}年#{date_obj.month}月#{date_obj.day}日"
        date_with_zero = date_obj.strftime("%Y年%m月%d日")

        results = []
        [date_no_zero, date_with_zero].each do |date|
          result = Dir.chdir(cli_dir) do
            `#{cli_path} search-documents --date "#{date}" 2>&1`
          end
          results << result
        end

        require 'json'
        names = []
        results.each do |result|
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
            names += text.scan(/--\s*>\s*(\([^\)]*\))/).flatten
          end
        end
         client.say(channel: data.channel, text: "#{date_no_zero} の議事録を検索")
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

