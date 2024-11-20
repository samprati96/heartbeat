module Heartbeat
  class Node
    include Heartbeat::StateMachine  # Include the StateMachine module

    attr_reader :name, :last_heartbeat, :retries
    MAX_RETRIES = 3 # You can set this to any number of retries before failure


    def initialize(name)
      @name = name
      @last_heartbeat = Time.now
      @retries = 0
    end

    def update_heartbeat
      @last_heartbeat = Time.now
      @retries = 0  # Reset retries on successful heartbeat
      self.heartbeat!  # Trigger the heartbeat event in the state machine
    end

    # Increase the retry count
    def increment_retries
      @retries += 1
    end

    # Check if the node should fail
    def should_fail?
      @retries >= MAX_RETRIES
    end
  end
end
