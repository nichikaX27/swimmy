require 'open3'

module Swimmy
  module Driver
    class RaskCliDriver
      DOCUMENTS_COMMAND_ARGS = ["get", "--documents", "--title"].freeze

      class CommandFailedError < StandardError; end

      def initialize(cli_dir: nil)
        @cli_dir = cli_dir || self.class.resolve_cli_dir
      end

      def fetch_documents(title)
        stdout, stderr, status = Open3.capture3(cli_path, *DOCUMENTS_COMMAND_ARGS, title, chdir: @cli_dir)

        unless status.success?
          raise CommandFailedError, "CLIコマンド実行エラー: #{stderr.strip}"
        end

        stdout
      end

      private

      def cli_path
        File.join(@cli_dir, "target", "debug", "rask-cli")
      end

      def self.resolve_cli_dir
        dir = ENV['RASK_CLI_DIR'].to_s.strip
        return dir unless dir.empty?
        raise "環境変数 RASK_CLI_DIR が設定されていません。`.env` または実行環境に `RASK_CLI_DIR=/path/to/RASK_CLI_TEMPLATE` を追加してください。"
      end
    end
  end
end
