module Swimmy
  module Command
    class Homework < Swimmy::Command::Base

      command "homework" do |client, data, match|
        cli_dir = "/home/abo-n/git/RASK_CLI_TEMPLATE"
        cli_path = "#{cli_dir}/target/debug/rask-cli"

        # Slack入力からキーワードを取得
        keywords = match[:expression] || ""

        begin
          result = Dir.chdir(cli_dir) do
            `#{cli_path} search-documents --keywords "#{keywords}" 2>&1`
          end
        rescue => e
          client.say(channel: data.channel, text: "コマンドの実行中にエラーが発生しました: #{e.message}")
          return
        end

        require 'json'
        names = []
        begin
          json = JSON.parse(result)
          json.each do |doc|
            # デバッグ用: docの中身全体をSlackに送信
            client.say(channel: data.channel, text: "doc: #{doc.inspect}")
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

        if names.empty?
          message = "文書(#{keywords})中に宿題はありません．"
        else
          message = "文書(#{keywords})中の宿題担当: #{names.uniq.join(", ")}"
        end
        client.say(channel: data.channel, text: message)
        title "homework"
        desc "宿題の有無を表示します．"
        long_desc "homework\n" +
                  "会議の議事録に記載された宿題を表示します．"
      end
    end # class Homework
  end # module Command
end # module Swimmy

