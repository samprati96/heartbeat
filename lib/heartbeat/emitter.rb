module Heartbeat
  class Emitter
    def initialize(tracker)
      @tracker = tracker
    end

    def start_heartbeat
      # Here we simulate periodic heartbeats
      loop do
        Heartbeat.nodes.each_value do |node|
          @tracker.update_node_heartbeat(node)
        end
        sleep Heartbeat.timeout
        @tracker.check_for_timeouts
        @tracker.reassign_task_if_needed
      end
    end
  end
end
