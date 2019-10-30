# frozen_string_literal: true

class TezosClient
  class LiquidityInterface
    # Wrapper used to call the tezos-client binary
    module LiquidityWrapper
      def call_liquidity(command, verbose: false)
        cmd = "#{liquidity_cmd(verbose: verbose)} #{command}"
        log cmd
        Open3.popen3(cmd) do |_stdin, stdout, stderr, wait_thr|
          err = stderr.read
          status = wait_thr.value.exitstatus

          if status != 0
            raise LiquidityError, "command '#{cmd}' existed with status #{status}: #{err}"
          end

          log err
          output = stdout.read

          if block_given?
            yield(output)
          else
            output
          end
        end
      end

      def liquidity_cmd(verbose:)
        verbose_option = verbose ? "--verbose" : ""
        "liquidity #{verbose_option} --tezos-node #{tezos_node}"
      end
    end
  end
end
