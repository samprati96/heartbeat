require 'spec_helper'

RSpec.describe Heartbeat::Node do
  let(:node) { Heartbeat::Node.new('node1') }

  describe '#initialize' do
    it 'initializes with a name' do
      expect(node.name).to eq('node1')
    end

    it 'sets the last_heartbeat time to now' do
      expect(node.last_heartbeat).to be_within(1.second).of(Time.now)
    end

    it 'sets retries to 0' do
      expect(node.retries).to eq(0)
    end
  end

  describe '#update_heartbeat' do
    it 'updates the last_heartbeat time' do
      old_time = node.last_heartbeat
      node.update_heartbeat
      expect(node.last_heartbeat).to be > old_time
    end

    it 'resets retries to 0 on successful heartbeat' do
      node.increment_retries
      node.update_heartbeat
      expect(node.retries).to eq(0)
    end
  end

  describe '#should_fail?' do
    it 'returns true if retries exceed the max limit' do
      Heartbeat::Node::MAX_RETRIES.times { node.increment_retries }
      expect(node.should_fail?).to be true
    end

    it 'returns false if retries are less than the max limit' do
      expect(node.should_fail?).to be false
    end
  end
end

RSpec.describe Heartbeat::Tracker do
  let(:tracker) { Heartbeat::Tracker.new }
  let(:node1) { Heartbeat::Node.new('node1') }
  let(:node2) { Heartbeat::Node.new('node2') }

  describe '#register_node' do
    it 'registers a node correctly' do
      tracker.register_node(node1)
      expect(Heartbeat.nodes[node1.name]).to eq(node1)
    end
  end

  describe '#update_node_heartbeat' do
    it 'updates the heartbeat of a node' do
      tracker.register_node(node1)
      old_time = node1.last_heartbeat
      tracker.update_node_heartbeat(node1)
      expect(node1.last_heartbeat).to be > old_time
    end
  end

  describe '#check_for_timeouts' do
    it 'transitions nodes to failed state when retries exceed MAX_RETRIES' do
      tracker.register_node(node1)
      Heartbeat.timeout = 1 # To simulate timeout
      node1.increment_retries
      node1.increment_retries
      node1.increment_retries

      tracker.check_for_timeouts
      expect(node1.aasm_state).to eq('failed')
    end

    it 'marks nodes as inactive if retries are below MAX_RETRIES' do
      tracker.register_node(node1)
      Heartbeat.timeout = 1 # To simulate timeout

      tracker.check_for_timeouts
      expect(node1.aasm_state).to eq('inactive')
    end
  end
end

RSpec.describe Heartbeat::Emitter do
  let(:tracker) { instance_double(Heartbeat::Tracker) }
  let(:emitter) { Heartbeat::Emitter.new(tracker) }

  describe '#start_heartbeat' do
    it 'processes nodes in batches based on size' do
      Heartbeat.nodes = (1..1000).map { |i| Heartbeat::Node.new("node#{i}") }.to_h
      allow(tracker).to receive(:update_node_heartbeat)

      expect { emitter.start_heartbeat }.to change { Heartbeat.nodes.size }.by(0)
    end
  end

  describe '#stop_heartbeat' do
    it 'stops the heartbeat loop' do
      emitter.start_heartbeat
      expect(emitter.instance_variable_get(:@running)).to be true
      emitter.stop_heartbeat
      expect(emitter.instance_variable_get(:@running)).to be false
    end
  end
end

RSpec.describe Heartbeat::Notifiers::BaseNotifier do
  let(:notifier) { Heartbeat::Notifiers::BaseNotifier.new }
  let(:node) { Heartbeat::Node.new('node1') }

  describe '#notify_with_retries' do
    it 'retries up to MAX_RETRIES on failure' do
      allow(notifier).to receive(:notify).and_raise(StandardError, "Test error")
      expect(Heartbeat.logger).to receive(:warn).exactly(3).times
      notifier.notify_with_retries(node)
    end

    it 'does not retry after MAX_RETRIES failures' do
      allow(notifier).to receive(:notify).and_raise(StandardError, "Test error")
      expect(Heartbeat.logger).to receive(:error).once
      notifier.notify_with_retries(node)
    end
  end
end

RSpec.describe Heartbeat::Notifiers::RedisNotifier do
  let(:redis_notifier) { Heartbeat::Notifiers::RedisNotifier.new('redis://localhost:6379', 'heartbeat_channel') }
  let(:node) { Heartbeat::Node.new('node1') }

  describe '#notify' do
    it 'sends a notification to Redis' do
      allow_any_instance_of(Redis).to receive(:publish).and_return(1)
      expect { redis_notifier.notify(node) }.not_to raise_error
    end

    it 'raises an error if Redis connection fails' do
      allow_any_instance_of(Redis).to receive(:publish).and_raise(Redis::BaseConnectionError)
      expect { redis_notifier.notify(node) }.to raise_error('Redis Connection Error')
    end
  end
end

RSpec.describe Heartbeat::Notifiers::SlackNotifier do
  let(:slack_notifier) { Heartbeat::Notifiers::SlackNotifier.new('https://slack.webhook.url') }
  let(:node) { Heartbeat::Node.new('node1') }

  describe '#notify' do
    it 'sends a notification to Slack' do
      allow(Net::HTTP).to receive(:post).and_return(double('response', is_a?: true, code: '200', message: 'OK'))
      expect { slack_notifier.notify(node) }.not_to raise_error
    end

    it 'raises an error if Slack API returns failure' do
      allow(Net::HTTP).to receive(:post).and_return(double('response', is_a?: false, code: '500', message: 'Internal Server Error'))
      expect { slack_notifier.notify(node) }.to raise_error('Slack API Error: 500 - Internal Server Error')
    end
  end
end
