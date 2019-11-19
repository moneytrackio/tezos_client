# frozen_string_literal: true

RSpec.describe TezosClient::SmartpyInterface do
  let(:script) { File.expand_path("./spec/fixtures/demo.py") }
  let(:init_params) { "MyContract(1, 2)" }

  let(:rpc_node_address) { "tezos_node" }
  let(:rpc_node_port) { 8094 }
  let(:default_options) do
    {
      rpc_node_address: rpc_node_address,
      rpc_node_port: rpc_node_port
    }
  end

  subject { described_class.new(default_options) }


  describe "#json_script" do
    it "works" do
      json_init_script, json_contract_script = subject.json_scripts(
        script: script,
        init_params: init_params
      )
      expect(json_init_script).to be_an Hash
      expect(json_contract_script).to be_an Array
    end
  end

  describe "#call_parameters" do
    let(:inputs) do
      {
        script: script,
        parameters: [
          "myEntryPoint",
          "1"
        ],
        init_params: init_params
      }
    end

    it "work" do
      subject.call_parameters(**inputs)
    end
  end
end