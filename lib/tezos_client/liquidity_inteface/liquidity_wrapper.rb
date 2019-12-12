# frozen_string_literal: true

class TezosClient
  class LiquidityInterface
    # Wrapper used to call the tezos-client binary
    module LiquidityWrapper
      def call_liquidity(command, verbose: false)
        cmd = liquidity_cmd(verbose: verbose).concat command

        ::Tools::SystemCall.execute(cmd)
      rescue SystemCallError => e
        raise LiquidityError, e.message
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
