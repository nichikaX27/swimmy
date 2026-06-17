module Swimmy
  module Service
    class Homework
      CLI_DIR = "/home/abo-n/git/RASK_CLI_TEMPLATE"
      CLI_PATH = "#{CLI_DIR}/target/debug/rask-cli"
      RASK_URL = "https://rask.nomlab.org"
      TASK_URL_TEMPLATE = "#{RASK_URL}/tasks/new?desc_header=Created+from+[AI%s](#{RASK_URL}/documents/%s?ai=%s)"
      DESC_GT_ENTITY = /\\u003e/
      HOMEWORK_TASK_PATTERN = /--\s*>\s*\(([^!]+) !:(\d+)\)/
      DOCUMENTS_COMMAND_ARGS = ["get", "--documents", "--title"]

      # ドキュメント一覧を取得
      def self.fetch_documents(title)
        require 'open3'

        result = nil
        Dir.chdir(CLI_DIR) do
          stdout, stderr, status = Open3.capture3(CLI_PATH, *DOCUMENTS_COMMAND_ARGS, title)
          unless status.success?
            raise "コマンドが失敗しました: #{stderr.strip}"
          end
          result = stdout
        end

        result
      end

      # JSONからホームワーク情報を抽出
      def self.extract_homeworks(json_string)
        require 'json'

        homeworks = []
        begin
          json = JSON.parse(json_string)

          return homeworks if json.nil? || json.empty?

          json.each do |doc|
            desc = doc["description"]
            doc_id = doc["id"]
            task_url = doc["task_url"]

            next unless desc

            # \u003eを>に変換
            desc = desc.gsub(DESC_GT_ENTITY, ">")
            desc.scan(HOMEWORK_TASK_PATTERN).each do |name, ai_num|
              homework = Swimmy::Resource::Homework.new(
                name: name.strip,
                ai_number: ai_num.strip,
                doc_id: doc_id.to_s,
                task_url: task_url || format(TASK_URL_TEMPLATE, ai_num.strip, doc_id, ai_num.strip)
              )
              homeworks << homework
            end
          end
        rescue JSON::ParserError => e
          raise "JSONの解析に失敗しました: #{e.message}"
        end

        homeworks
      end

      # タイトルからホームワークを取得
      def self.get_homeworks_by_title(title)
        raise "文書名を指定してください．" if title.empty?

        result = fetch_documents(title)
        extract_homeworks(result)
      end
    end
  end
end
