module Swimmy
  module Command
    class Homework < Swimmy::Command::Base
      CLI_DIR = "/home/abo-n/git/RASK_CLI_TEMPLATE"
      CLI_PATH = "#{CLI_DIR}/target/debug/rask-cli"
      RASK_URL = "https://rask.nomlab.org"
      TASK_URL_TEMPLATE = "#{RASK_URL}/tasks/new?desc_header=Created+from+[AI%s](#{RASK_URL}/documents/%s?ai=%s)"

      command "homework" do |client, data, match|
        cli_dir = CLI_DIR
        cli_path = CLI_PATH
        rask_url = RASK_URL

        title = match[:expression] || ""

        if title.empty?
          client.say(channel: data.channel, text: "文書名を指定してください．\n 使用方法 : swimmy homework <文書名>")
          return
        end

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
          
          if json.nil? || json.empty?
            client.say(channel: data.channel, text: "「#{title}」という文書が見つかりませんでした．")
            return
          end
          
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
              task_urls << (task_url || format(TASK_URL_TEMPLATE, ai_num.strip, doc_id, ai_num.strip))
            
            end
          end
        rescue JSON::ParserError
          client.say(channel: data.channel, text: "JSONの解析に失敗しました")
        end

        if names.empty?
          message = "文書「#{title}」中に宿題はありません．"
        else
          # 担当者名・AI番号・doc_idをペアで表示
          message = "文書「#{title}」中の宿題担当を表示します．\n 以下のリンクからタスクを作成してください．\n" 
          names.zip(ai_numbers, doc_ids, task_urls).each do |name, ai_num, doc_id, task_url|
            message += "<#{task_url}|#{name}{#{ai_num}}>\n"
          end
        end
        
        client.say(channel: data.channel, text: message)

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

