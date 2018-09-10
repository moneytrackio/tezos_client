# frozen_string_literal: true

RSpec.shared_context "public rpc interface", shared_context: :metadata do
  let(:rpc_node_address) { "alphanet-node.tzscan.io" }
  let(:rpc_node_port) { 80 }

  let(:tezos_client) { TezosClient.new(rpc_node_address: rpc_node_address, rpc_node_port: rpc_node_port) }
  let(:rpc_interface) { TezosClient::RpcInterface.new(host: rpc_node_address, port: rpc_node_port) }
  let(:liquidity_interface) { TezosClient::LiquidityInterface.new(rpc_node_address: rpc_node_address, rpc_node_port: rpc_node_port) }

end
