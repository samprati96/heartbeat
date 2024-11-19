require 'spec_helper'
require 'containers/min_heap'
require 'aasm'
require 'heartbeat'

RSpec.describe 'Heartbeat Gem' do
  before(:each) do
    # Reset the configuration before each test
    Heartbeat.setup do |config|
      config.nodes = {}
      config.timeout = 10  # 10 seconds for testing
    end
    @tracker = Heartbeat::Tracker.new
  end

  describe 'Node Registration' do
    it 'should register a node successfully' do
      node1 = Heartbeat::Node.new("Node 1")
      @tracker.register_node(node1)

      expect(Heartbeat.nodes).to have_key("Node 1")
      expect(Heartbeat.nodes["Node 1"]).to eq(node1)
    end
  end

  describe 'Heartbeat Emission' do
    it 'should update the heartbeat of a node' do
      node1 = Heartbeat::Node.new("Node 1")
      @tracker.register_node(node1)

      # Simulate a heartbeat update
      node1.update_heartbeat
      expect(node1.last_heartbeat).to be_within(1.second).of(Time.now)
    end
  end

  describe 'State Transitions' do
    it 'should transition node state to active on receiving a heartbeat' do
      node1 = Heartbeat::Node.new("Node 1")
      @tracker.register_node(node1)

      # Initially, the state should be active
      expect(node1.aasm_state).to eq(:active)

      # Simulate heartbeat and check state
      node1.update_heartbeat
      expect(node1.aasm_state).to eq(:active)
    end

    it 'should transition node state to inactive if timeout occurs' do
      node1 = Heartbeat::Node.new("Node 1")
      @tracker.register_node(node1)

      # Simulate timeout (wait for the timeout interval to elapse)
      sleep 15  # Timeout period of 10 seconds in this example
      @tracker.check_for_timeouts

      expect(node1.aasm_state).to eq(:inactive)
    end

    it 'should transition node state to failed after multiple timeouts and retries' do
      node1 = Heartbeat::Node.new("Node 1")
      @tracker.register_node(node1)

      # Simulate heartbeats, so the node is active initially
      node1.update_heartbeat
      expect(node1.aasm_state).to eq(:active)

      # Simulate multiple timeouts (each time incrementing retries)
      2.times do
        sleep 15 # Wait for the timeout period
        @tracker.check_for_timeouts
        expect(node1.aasm_state).to eq(:inactive)
      end

      # After the 3rd timeout, the node should fail
      sleep 15
      @tracker.check_for_timeouts
      expect(node1.aasm_state).to eq(:failed)
    end
  end

  describe 'Timeout Detection' do
    it 'should detect when a node has timed out' do
      node1 = Heartbeat::Node.new("Node 1")
      @tracker.register_node(node1)

      # Simulate timeout (sleep for 15 seconds)
      sleep 15
      @tracker.check_for_timeouts

      expect(node1.aasm_state).to eq(:inactive)
    end
  end

  describe 'Task Reassignment (Failover)' do
    it 'should reassign tasks if a node fails' do
      node1 = Heartbeat::Node.new("Node 1")
      node2 = Heartbeat::Node.new("Node 2")
      @tracker.register_node(node1)
      @tracker.register_node(node2)

      # Simulate node failure
      sleep 15  # Wait for timeout
      @tracker.check_for_timeouts

      # Node 1 should be inactive after timeout
      expect(node1.aasm_state).to eq(:inactive)

      # Simulate task reassignment due to failure
      @tracker.reassign_task_if_needed

      # Here we just check if reassigning logic was triggered
      # In a real implementation, we'd check task state or logs
      expect { @tracker.reassign_task_if_needed }.not_to raise_error
    end
  end
end
