require 'redis'

module Heartbeat
  module Notifiers
    class RedisNotifier < BaseNotifier
      def initialize(redis_url, channel)
        @redis = Redis.new(url: redis_url)
        @channel = channel
      end

      def notify(node)
        begin
          @redis.publish(@channel, "ALERT: Node '#{node.name}' has failed. Immediate action required!")
        rescue Redis::BaseConnectionError => e
          raise "Redis Connection Error: #{e.message}"
        rescue StandardError => e
          raise "Unexpected Redis Error: #{e.message}"
        end
      end
    end
  end
end
