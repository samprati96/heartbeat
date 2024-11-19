require 'containers/min_heap'
require 'aasm'

module Heartbeat
  class << self
    attr_accessor :nodes, :timeout

    def setup
      yield self
    end
  end

  # Default configuration
  Heartbeat.setup do |config|
    config.nodes = {}  # A hash to store node states
    config.timeout = 10  # Timeout interval in seconds
  end
end
