module Heartbeat
  module Notifiers
    class BaseNotifier
      MAX_RETRIES = 3
      RETRY_DELAY = 5 # seconds

      def notify_with_retries(node)
        attempts = 0
        begin
          notify(node)
        rescue StandardError => e
          attempts += 1
          if attempts <= MAX_RETRIES
            Heartbeat.logger.warn("Retrying notification for node '#{node.name}' (attempt #{attempts}) due to: #{e.message}")
            sleep RETRY_DELAY
            retry
          else
            Heartbeat.logger.error("Failed to notify for node '#{node.name}' after #{MAX_RETRIES} attempts: #{e.message}")
          end
        end
      end
      
      def notify(node)
        raise NotImplementedError, "Subclasses must implement `notify` method"
      end
    end
  end
end
