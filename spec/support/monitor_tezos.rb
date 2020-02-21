# frozen_string_literal: true

module MonitorTezos
  def monitor_operation(operation_id)
    disabling_vcr { tezos_client.monitor_operation(operation_id) } unless reading_vcr_cassette?
  end

  def wait_new_block(timeout: 20)
    return if reading_vcr_cassette?

    disabling_vcr do
      blocks_to_wait = 2
      received_blocks = []
      monitor_thread = subject.monitor_block do |block|
        received_blocks << block[:hash]
        received_blocks.uniq!
      end

      limit_time = Time.now + timeout

      while received_blocks.size < blocks_to_wait && Time.now < limit_time
        sleep(1)
      end
      monitor_thread.terminate

      raise "no block received for 4 minutes" unless received_blocks.size >= blocks_to_wait
    end
  end
end

RSpec.configure do |config|
  config.include MonitorTezos
end
