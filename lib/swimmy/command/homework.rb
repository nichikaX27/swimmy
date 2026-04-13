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
          # # コマンド出力内容をSlackに送信（デバッグ用）
          # client.say(channel: data.channel, text: "コマンド出力: #{result}")
          # client.say(channel: data.channel, text: result) 
        rescue => e
          client.say(channel: data.channel, text: "コマンドの実行中にエラーが発生しました: #{e.message}")
          return
        end

        require 'json'
        names = []
        ai_numbers = []
        doc_ids = []
        begin
          # client.say(channel: data.channel, text: "result: #{result}")
          json = JSON.parse(result)
          json.each do |doc|
            desc = doc["description"]
            doc_id = doc["id"] 
            next unless desc
            # \u003eを>に変換
            desc = desc.gsub(/\\u003e/, ">")
            # -->(...) まで全体を抽出し、doc_idもセット
            desc.scan(/--\s*>\s*\(([^!]+) !:([0-9]+)\)/).each do |name, ai_num|
              names << name.strip
              ai_numbers << ai_num.strip
              doc_ids << doc_id.to_s
            end
          end
        rescue JSON::ParserError
          # JSONでなければ全体から-->(...)を抽出
          text = result.gsub(/\\u003e/, ">")
          names += text.scan(/--\s*>\s*\(([^!]+) !:([0-9]+)\)/).map { |m| m[0].strip }
          ai_numbers += text.scan(/--\s*>\s*\(([^!]+) !:([0-9]+)\)/).map { |m| m[1].strip }
          client.say(channel: data.channel, text: "JSONの解析に失敗しました") if names.any?
        end

        if names.empty?
          message = "文書(#{keywords})中に宿題はありません．"
        else
          # 担当者名・AI番号・doc_idをペアで表示
          message = "文書(#{keywords})中の宿題担当: " + names.zip(ai_numbers, doc_ids).map { |n, a, d| "#{n} (AI#{a})" }.join(", ")
          client.say(channel: data.channel, text: message)
          names.zip(ai_numbers, doc_ids).each do |name, ai_num, doc_id|
            desc_header = "Created+from+[AI#{ai_num}](https://rask.nomlab.org/documents/#{doc_id}?ai=#{ai_num})"
            url = "https://rask.nomlab.org/tasks/new?desc_header=#{desc_header}"
            client.say(channel: data.channel, text: "#{name} のタスク作成: #{url}")
          end
        end
        title "homework"
        desc "宿題の有無を表示します．"
        long_desc "homework\n" +
                  "会議の議事録に記載された宿題を表示します．"
      end
    end # class Homework
  end # module Command
end # module Swimmy

