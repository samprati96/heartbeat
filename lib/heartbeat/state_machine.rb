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
        end

        event :timeout do
          transitions from: :active, to: :inactive
        end
      end
    end
  end
end
