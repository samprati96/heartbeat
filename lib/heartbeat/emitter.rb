require 'concurrent'

module Heartbeat
  class Emitter
    def initialize(tracker)
      @tracker = tracker
      @running = false
    end

    def start_heartbeat
      @running = true
      while @running
        # Adjust batch size based on the number of nodes
        batch_size = determine_batch_size(Heartbeat.nodes.size)

        # Split the nodes into batches based on the dynamic batch size
        node_batches = Heartbeat.nodes.values.each_slice(batch_size).to_a

        # Limit concurrency based on configurable max_concurrent_threads
        max_concurrent_threads = Heartbeat.max_concurrent_threads
        futures = []

        node_batches.each_slice(max_concurrent_threads) do |batch_group|
          # Process each group of batches concurrently, with a maximum number of threads
          batch_group.each do |batch|
            futures << Concurrent::Future.execute do
              batch.each do |node|
                @tracker.update_node_heartbeat(node)
              end
            end
          end

          # Wait for all futures in this group to complete before proceeding
          futures.each(&:wait)
          futures.clear
        end

        # After processing the nodes, sleep, check timeouts, and reassign tasks
        sleep Heartbeat.timeout
        @tracker.check_for_timeouts
      end
    end

    def stop_heartbeat
      @running = false
    end

    private

    # Method to determine the batch size based on the number of nodes
    def determine_batch_size(node_count)
      if node_count < 10_000
        Heartbeat.batch_size_thresholds[:small]
      elsif node_count < 100_000
        Heartbeat.batch_size_thresholds[:medium]
      else
        Heartbeat.batch_size_thresholds[:large]
      end
    end
  end
end
