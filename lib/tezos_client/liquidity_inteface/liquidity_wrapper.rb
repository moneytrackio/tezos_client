# frozen_string_literal: true

class TezosClient
  class LiquidityInterface
    # Wrapper used to call the tezos-client binary
    module LiquidityWrapper
      def call_liquidity(command, verbose: false)
        cmd = liquidity_cmd(verbose: verbose).concat command
        log cmd.to_s
        Open3.popen3(*cmd) do |_stdin, stdout, stderr, wait_thr|
          err = stderr.read
          status = wait_thr.value.exitstatus
          log err

          if status != 0
            raise LiquidityError, "command '#{cmd}' existed with status #{status}: #{err}"
          end

          output = stdout.read

          if block_given?
            yield(output)
          else
            output
          end
        end
      end

      def liquidity_cmd(verbose:)
        liquidity_request = ["liquidity"]
        liquidity_request << "--verbose" if verbose
        liquidity_request << "--tezos-node"
        liquidity_request << tezos_node.to_s
        liquidity_request
      end
    end
  end
end

#res = Open3.popen3(
#    ["liquidity",
#    "--tezos-node", "tezos_node:8094",
#    "../../TPHN/smart-contract-spec/contracts/insurance/insurance_contract.liq",
#    "--json", "-o", "/var/folders/p6/f3tstn_16v57wd9113bwl0tm0000gn/T/script20191113-23531-rpsa2f.json",
#    "--data", "add_insuree", "(\"61715051100278\", tz1WUbuCKRKwtVZYAGKY23UDU9jyJXpp9Nji)"]
#)