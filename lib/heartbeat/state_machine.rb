module Heartbeat
  module StateMachine
    extend ActiveSupport::Concern

    included do
      include AASM

      aasm :column => 'state' do
        state :active, initial: true
        state :inactive
        state :failed

        event :heartbeat do
          transitions from: [:inactive, :failed], to: :active
        end

        event :fail do
          transitions from: :active, to: :failed

          # Add a callback to notify about failure
          after do
            notify_failure(self)
          end
        end

        event :timeout do
          transitions from: :active, to: :inactive
        end
      end
    end

    def notify_failure(node)
      if Heartbeat.failure_callback
        Heartbeat.failure_callback.call(node)
      else
        Heartbeat.logger.error("No failure callback defined. Node '#{node.name}' has failed.")
      end

      if Heartbeat.notifiers.empty?
        Heartbeat.logger.warn("No notifiers configured. Failed node '#{node.name}' notification skipped.")
      else
        Heartbeat.notifiers.each { |notifier| notifier.notify_with_retries(node) }
      end
    end

  end
end
