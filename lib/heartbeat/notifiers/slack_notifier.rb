require 'net/http'
require 'json'

module Heartbeat
  module Notifiers
    class SlackNotifier < BaseNotifier
      def initialize(webhook_url)
        @webhook_url = webhook_url
      end

      def notify(node)
        message = { text: "ALERT: Node '#{node.name}' has failed. Immediate action required!" }
        uri = URI(@webhook_url)
        
        begin
          response = Net::HTTP.post(uri, message.to_json, "Content-Type" => "application/json")
          unless response.is_a?(Net::HTTPSuccess)
            raise "Slack API Error: #{response.code} - #{response.message}"
          end
        rescue StandardError => e
          raise "Failed to send Slack notification for node '#{node.name}': #{e.message}"
        end
      end

    end
  end
end
