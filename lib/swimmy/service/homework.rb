require 'open3'
require 'json'

module Swimmy
  module Service
    class Homework
      CLI_DIR = "/home/abo-n/git/RASK_CLI_TEMPLATE"
      CLI_PATH = "#{CLI_DIR}/target/debug/rask-cli"
      DESC_GT_ENTITY = /\\u003e/
      HOMEWORK_TASK_PATTERN = /--\s*>\s*\(([^!]+) !:(\d+)\)/
      DOCUMENTS_COMMAND_ARGS = ["get", "--documents", "--title"].freeze

      # ドキュメント一覧を取得
      def self.fetch_documents(title)
        stdout, stderr, status = Open3.capture3(CLI_PATH, *DOCUMENTS_COMMAND_ARGS, title, chdir: CLI_DIR)
        
        unless status.success?
          raise "CLIコマンド実行エラー: #{stderr.strip}"
        end
        
        stdout
      end

      # JSONからホームワーク情報を抽出
      def self.extract_homeworks(json_string)
        homeworks = []
        
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
              task_url: task_url,
              rask_url: doc["rask_url"] || "https://rask.nomlab.org"
            )
            homeworks << homework
          end
        end

        homeworks
      rescue JSON::ParserError => e
        raise "JSONの解析に失敗しました: #{e.message}"
      end

      # タイトルからホームワークを取得
      def self.get_homeworks_by_title(title)
        result = fetch_documents(title)
        extract_homeworks(result)
      end
    end
  end
end
