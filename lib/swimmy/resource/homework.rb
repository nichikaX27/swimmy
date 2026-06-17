module Swimmy
  module Resource
    class Homework
      attr_accessor :name, :ai_number, :doc_id, :task_url

      def initialize(name:, ai_number:, doc_id:, task_url:)
        @name = name
        @ai_number = ai_number
        @doc_id = doc_id
        @task_url = task_url
      end

      # Slack形式のリンク表記
      def to_slack_link
        "<#{@task_url}|#{@name}{#{@ai_number}}>"
      end
    end
  end
end
