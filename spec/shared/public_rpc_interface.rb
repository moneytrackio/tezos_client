# frozen_string_literal: true

RSpec.shared_context "public rpc interface", shared_context: :metadata do
  let(:rpc_node_address) { "tezos_node" }
  let(:rpc_node_port) { 8094 }

  let(:tezos_client) { TezosClient.new(rpc_node_address: rpc_node_address, rpc_node_port: rpc_node_port) }
  let(:rpc_interface) { TezosClient::RpcInterface.new(host: rpc_node_address, port: rpc_node_port) }
end
