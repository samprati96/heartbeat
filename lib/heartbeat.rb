require 'containers/min_heap'
require 'aasm'
require 'logger'

module Heartbeat
  class << self
    attr_accessor :nodes, :timeout, :notifiers, :logger, :failure_callback, :batch_size, :max_concurrent_threads, :batch_size_thresholds

    def setup
      yield self
    end
  end

  # Default configuration
  Heartbeat.setup do |config|
    config.nodes = {}  # A hash to store node states
    config.timeout = 30  # Timeout interval in seconds
    config.notifiers = [] # Initialize with an empty list of notifiers
    config.logger = Logger.new(STDOUT) # Logs to console by default
    config.logger.level = Logger::INFO # Default log level
    config.max_concurrent_threads = 4  # Default max threads for concurrency
    config.batch_size_thresholds = {
      small: 500,    # Batch size for fewer than 10,000 nodes
      medium: 1000,  # Batch size for fewer than 100,000 nodes
      large: 5000    # Batch size for larger node sets
    }
  end

  def self.on_failure(&block)
    @failure_callback = block
  end
end
