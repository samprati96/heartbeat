# Heartbeat

The `heartbeat` gem provides an easy way to monitor worker processes by tracking periodic heartbeat signals. It allows detecting unresponsive workers based on a configurable timeout and provides hooks for handling failures (e.g., reassigning jobs). The gem is designed to be lightweight and efficient, making it ideal for distributed systems where monitoring worker health is critical.

## Features

- **Emit Periodic Heartbeats**: Workers send periodic heartbeats to indicate they are alive.
- **Monitor Worker Health**: Track and monitor the status of workers based on heartbeat signals.
- **Detect Expired Workers**: Identify workers that have stopped emitting heartbeats after a configurable timeout period.
- **Custom Failure Handling**: Detect unresponsive workers and take necessary actions such as job reassignment.
- **Thread Safety**: Uses Mutex to ensure thread-safe operations in a multi-threaded environment.
- **Efficient Monitoring**: Utilizes a Min-Heap data structure to efficiently detect expired workers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heartbeat'
```

Then execute:

```bash
$ bundle install
```

Or install it manually:

```bash
$ gem install heartbeat
```

## Usage

### Creating a Worker

You can create a worker that sends periodic heartbeat signals:

```ruby
require 'heartbeat'

# Create a monitor with a 5-second timeout threshold
monitor = Heartbeat.create_monitor(5)

# Create a worker with a 2-second heartbeat interval
worker = Heartbeat.create_worker('worker_1', 2, monitor)

# Start the worker to begin emitting heartbeats
worker.start
```

### Monitoring Workers

The `Monitor` class tracks the heartbeats and can detect expired workers:

```ruby
# List all active workers
monitor.active_workers # => ['worker_1']

# Detect expired workers
expired_workers = monitor.expired_workers
puts "Expired workers: #{expired_workers}" unless expired_workers.empty?
```

### Example Loop

```ruby
require 'heartbeat'

# Create a monitor with a 5-second timeout threshold
monitor = Heartbeat.create_monitor(5)

# Create multiple workers
worker1 = Heartbeat.create_worker('worker_1', 2, monitor)
worker2 = Heartbeat.create_worker('worker_2', 3, monitor)

# Start workers
worker1.start
worker2.start

# Monitor workers in a loop
loop do
  expired = monitor.expired_workers
  puts "Expired workers: #{expired}" unless expired.empty?
  sleep(1)
end
```

### Stopping Workers

To stop a worker from emitting heartbeats:

```ruby
worker1.stop
worker2.stop
```

---

## Core Classes

### `Heartbeat::Worker`

The `Worker` class handles emitting periodic heartbeat signals. You can configure the heartbeat interval and control when the worker starts and stops.

- **`start`**: Starts the worker to emit heartbeats at the specified interval.
- **`stop`**: Stops the worker from emitting heartbeats.

### `Heartbeat::Monitor`

The `Monitor` class is responsible for tracking workers' heartbeats, detecting expired workers, and managing worker health. It supports:

- **`record_heartbeat(worker_id)`**: Records a heartbeat for a worker.
- **`expired_workers`**: Returns a list of workers whose heartbeats are overdue.
- **`active_workers`**: Returns a list of currently active workers.

### `Heartbeat::Version`

This class defines the version of the `heartbeat` gem.

---

## Development

After checking out the repo, run the following to install dependencies:

```bash
bin/setup
```

To run tests:

```bash
rake spec
```

To install the gem locally:

```bash
bundle exec rake install
```

To release a new version, update the version number in `lib/heartbeat/version.rb` and run:

```bash
bundle exec rake release
```

---

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/[USERNAME]/heartbeat](https://github.com/[USERNAME]/heartbeat).

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/heartbeat/blob/master/CODE_OF_CONDUCT.md).

---

## License

The `heartbeat` gem is available as open-source under the MIT License.

---

### Publishing the Gem

To push your gem to RubyGems:

1. Sign up for a RubyGems account (if you don't already have one).
2. Build the gem:

   ```bash
   gem build heartbeat.gemspec
   ```

3. Push the gem to RubyGems:

   ```bash
   gem push heartbeat-0.1.0.gem
   ```

Your gem is now live and ready to be used by others!

---

This README provides a complete guide for installing, using, and contributing to the `heartbeat` gem. Make sure to update your GitHub username or project-specific links when using this template!