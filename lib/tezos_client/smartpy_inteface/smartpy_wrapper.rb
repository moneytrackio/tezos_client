# frozen_string_literal: true

class TezosClient
  class SmartpyInterface
    # Wrapper used to call the tezos-client binary
    module SmartpyWrapper
      def call_smartpy(command)
        cmd = smartpy_cmd + command
        pp cmd
        log cmd.to_s
        Open3.popen3(*cmd) do |_stdin, stdout, stderr, wait_thr|
          err = stderr.read
          status = wait_thr.value.exitstatus
          log err

          if status != 0
            raise "command '#{cmd}' existed with status #{status}: #{err}"
          end

          output = stdout.read

          if block_given?
            yield(output)
          else
            output
          end
        end
      end

      def smartpy_cmd
        liquidity_request = ["/Users/sebastienlauret/SmartPyBasic/SmartPy.sh"]
        liquidity_request
      end
    end
  end
end
