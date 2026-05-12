module Swimmy
  module Command
    class Homework < Swimmy::Command::Base
      command "homework" do |client, data, match|
        cli_dir = "/home/abo-n/git/RASK_CLI_TEMPLATE"
        cli_path = "#{cli_dir}/target/debug/rask-cli"
        rask_url = "https://rask.nomlab.org"

        title = match[:expression] || ""

        begin
          result = Dir.chdir(cli_dir) do
            `#{cli_path} get --documents --title "#{title}" 2>&1`
          end
        rescue => e
          client.say(channel: data.channel, text: "コマンドの実行中にエラーが発生しました: #{e.message}")
          return
        end

        require 'json'
        names = []
        ai_numbers = []
        doc_ids = []
        task_urls = []
        begin
          json = JSON.parse(result)
          json.each do |doc|
            desc = doc["description"]
            doc_id = doc["id"] 
            task_url = doc["task_url"]
            next unless desc
            # \u003eを>に変換
            desc = desc.gsub(/\\u003e/, ">")
            desc.scan(/--\s*>\s*\(([^!]+) !:([0-9]+)\)/).each do |name, ai_num|
              names << name.strip
              ai_numbers << ai_num.strip
              doc_ids << doc_id.to_s
              task_urls << (task_url || "#{rask_url}/tasks/new?desc_header=Created+from+[AI#{ai_num.strip}](#{rask_url}/documents/#{doc_id}?ai=#{ai_num.strip})")
            
            end
          end
        rescue JSON::ParserError
          client.say(channel: data.channel, text: "JSONの解析に失敗しました") if names.any?
        end

        if names.empty?
          message = "文書(#{title})中に宿題はありません．"
        else
          # 担当者名・AI番号・doc_idをペアで表示
          message = "文書(#{title})中の宿題担当を表示します．\n 以下のリンクからタスクを作成してください．\n" 
          client.say(channel: data.channel, text: message)
          names.zip(ai_numbers, doc_ids, task_urls).each do |name, ai_num, doc_id, task_url|
            client.say(channel: data.channel, text: "<#{task_url}|#{name}{#{ai_num}}}>")
          end
        end

      help do
        title "homework"
        desc "宿題の有無を表示します．"
        long_desc "homework\n" +
                  "会議の議事録に記載された宿題を表示します．"
      end

      end
    end # class Homework
  end # module Command
end # module Swimmy

