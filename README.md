# Heartbeat Gem

The **Heartbeat Gem** is a monitoring solution designed to track the health of nodes in a distributed system. It periodically checks the status of nodes and triggers notifications in case of failures or timeouts. This gem supports various notifier backends (such as Redis, Slack, etc.), retry mechanisms, and concurrency to handle large-scale systems with millions of nodes.

---

## Features

- **Node Heartbeat Monitoring**: Tracks the heartbeat of nodes and triggers failure handling if a node does not respond within the expected time.
- **Customizable Configuration**: Configure timeouts, notifiers, maximum concurrent threads, and batch sizes based on the number of nodes.
- **Batch Processing & Concurrency**: Efficiently handles node updates using batching and concurrency to scale with large systems.
- **Failure Notifications**: Send alerts via custom notifiers (Redis, Slack, etc.) when nodes fail.
- **Retries**: Implements a retry mechanism to handle temporary failures in notification systems.
- **State Machine for Node Status**: Manages node states (`active`, `inactive`, `failed`) using AASM (state machine gem).

---

## Installation

To install the gem, add it to your Gemfile:

```ruby
gem 'heartbeat'
```

Then run:

```bash
bundle install
```

---

## Configuration

The gem can be configured using the `Heartbeat.setup` block. You can customize settings like the timeout interval, notifiers, and concurrency limits.

### Example Configuration

```ruby
Heartbeat.setup do |config|
  config.nodes = {}  # A hash to store node states
  config.timeout = 30  # Timeout interval in seconds
  config.notifiers = [Heartbeat::Notifiers::SlackNotifier.new('https://slack.webhook.url')]  # List of notifiers
  config.logger = Logger.new(STDOUT)  # Logs to console by default
  config.logger.level = Logger::INFO  # Default log level
  config.max_concurrent_threads = 4  # Maximum concurrent threads
  config.batch_size_thresholds = {
    small: 500,    # Batch size for fewer than 10,000 nodes
    medium: 1000,  # Batch size for fewer than 100,000 nodes
    large: 5000    # Batch size for larger node sets
  }
end
```

### Available Configuration Options:

- `nodes`: A hash to store the nodes in the system.
- `timeout`: The time (in seconds) before considering a node as inactive.
- `notifiers`: A list of notifier objects that will be used to send alerts (e.g., `SlackNotifier`, `RedisNotifier`).
- `logger`: A logger for logging events and errors.
- `max_concurrent_threads`: Maximum number of concurrent threads for processing nodes in batches.
- `batch_size_thresholds`: Defines batch sizes for different node count ranges.
  
### Failure Callback

You can define a callback function that will be triggered when a node fails.

```ruby
Heartbeat.on_failure do |node|
  puts "Node '#{node.name}' has failed!"
end
```

---

## Node Model

The **Node** model represents a node that is being monitored. It tracks the `last_heartbeat` time and handles retries in case of failed heartbeats.

### Usage Example:

```ruby
node = Heartbeat::Node.new('node1')
node.update_heartbeat  # Update the node's heartbeat
node.increment_retries  # Increment the retry count
```

---

## Tracker

The **Tracker** class is responsible for registering nodes, updating heartbeats, and checking for timeouts.

### Usage Example:

```ruby
tracker = Heartbeat::Tracker.new
node = Heartbeat::Node.new('node1')
tracker.register_node(node)
tracker.update_node_heartbeat(node)  # Update heartbeat for a node
tracker.check_for_timeouts  # Check for nodes that have timed out
```

---

## Emitter

The **Emitter** class is responsible for starting and stopping the heartbeat process, processing nodes in batches, and handling concurrency. It uses a dynamic batching strategy based on the number of nodes.

### Usage Example:

```ruby
emitter = Heartbeat::Emitter.new(tracker)
emitter.start_heartbeat  # Start the heartbeat process
# To stop the heartbeat process
emitter.stop_heartbeat
```

---

## Notifiers

Notifiers send alerts when a node fails or times out. You can implement custom notifiers by inheriting from the `BaseNotifier` class.

### Available Notifiers:

- **SlackNotifier**: Sends notifications to a Slack webhook.
- **RedisNotifier**: Publishes failure alerts to a Redis channel.

#### Example of SlackNotifier:

```ruby
slack_notifier = Heartbeat::Notifiers::SlackNotifier.new('https://slack.webhook.url')
Heartbeat.notifiers << slack_notifier
```

#### Example of RedisNotifier:

```ruby
redis_notifier = Heartbeat::Notifiers::RedisNotifier.new('redis://localhost:6379', 'heartbeat_channel')
Heartbeat.notifiers << redis_notifier
```

---

## Node State Machine

The Node uses an **AASM** (State Machine) to transition between the following states:

- **active**: The node is active and has recently sent a heartbeat.
- **inactive**: The node has missed a heartbeat but is still within the retry limit.
- **failed**: The node has exceeded the maximum retries and is marked as failed.

---

## Example Usage

### Full Example:

```ruby
# Setup the Heartbeat configuration
Heartbeat.setup do |config|
  config.timeout = 60  # 1 minute timeout
  config.max_concurrent_threads = 5
  config.batch_size_thresholds = {
    small: 200,    # Batch size for fewer than 1,000 nodes
    medium: 500,   # Batch size for fewer than 10,000 nodes
    large: 1000    # Batch size for larger node sets
  }
  config.notifiers = [
    Heartbeat::Notifiers::SlackNotifier.new('https://slack.webhook.url')
  ]
end

# Initialize the tracker
tracker = Heartbeat::Tracker.new

# Register nodes
node1 = Heartbeat::Node.new('node1')
tracker.register_node(node1)

# Start monitoring heartbeat
emitter = Heartbeat::Emitter.new(tracker)
emitter.start_heartbeat
```

---

## Running Tests

The gem includes RSpec tests for the core functionality, including node state changes, heartbeat processing, and notification delivery.

To run the tests:

1. Install RSpec if you haven't already:

```bash
gem install rspec
```

2. Run the tests:

```bash
bundle exec rspec
```

---

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Create a new pull request.

---

Feel free to adjust the README to fit your use case and expand on any details as needed!