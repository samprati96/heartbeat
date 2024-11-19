module Heartbeat
  class Tracker
    def initialize
      @min_heap = Containers::MinHeap.new { |a, b| a[:last_heartbeat] <=> b[:last_heartbeat] }
    end

    def register_node(node)
      @min_heap.push({ node: node, last_heartbeat: node.last_heartbeat })
      Heartbeat.nodes[node.name] = node
    end

    def update_node_heartbeat(node)
      node.update_heartbeat
      @min_heap.push({ node: node, last_heartbeat: node.last_heartbeat })
    end

    def check_for_timeouts
      # Check the root node of the heap (i.e., the node with the oldest heartbeat time)
      while @min_heap.any? && Time.now - @min_heap.peek[:last_heartbeat] > Heartbeat.timeout
        entry = @min_heap.pop # Extract the node with the oldest heartbeat
        node = entry[:node]

        # If the node should fail, transition it to the failed state
        if node.should_fail?
          node.fail! if node.aasm_state != :failed
        else
          # Otherwise, mark the node as inactive and increment retries
          node.timeout! if node.aasm_state != :inactive
          node.increment_retries
        end
      end
    end

    def reassign_task_if_needed
      @min_heap.each do |entry|
        node = entry[:node]
        if node.aasm_state == :failed
          # Logic for task reassignment (not implemented here)
          puts "Reassigning task from node #{node.name}."
        end
      end
    end
  end
end
