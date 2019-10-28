# frozen_string_literal: true


RSpec.describe TezosClient::RpcInterface::Helper do
  using TezosClient::StringUtils

  include_context "public rpc interface"

  subject { TezosClient::RpcInterface.new(host: rpc_node_address, port: rpc_node_port) }


  let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
  let(:from) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
  let(:branch) { subject.head_hash }
  let(:protocol) { "PsBabyM1eUXZseaJdmXFApDSBqj8YBfwELoxZHHW77EMcAbbwAS" }

  let(:liquidity_interface) { TezosClient::LiquidityInterface.new(rpc_node_address: rpc_node_address, rpc_node_port: rpc_node_port) }

  let(:script_path) { File.expand_path("./spec/fixtures/demo.liq") }

  let(:script) do
    liquidity_interface.origination_script(
      from: from,
      script: script_path,
      init_params: '"test"'
    )
  end

  let(:counter) { subject.contract_counter(from) + 1 }

  describe "#forge_transaction" do
    let(:transaction_args) do
      {
        kind: "transaction",
        amount: "100",
        source: from,
        destination: from,
        gas_limit: "10000",
        storage_limit: "6000",
        counter: "0",
        fee: "50000"
      }
    end

    it "returns a String" do
      transaction_hex = subject.forge_operation(operation: transaction_args, branch: branch)
      expect(transaction_hex).to be_a String
      expect { transaction_hex.to_bin } .not_to raise_error
    end
  end

  describe "#forge_origination" do
    it "works" do
      origination_hex = subject.forge_operation(
        operation: subject.origination_operation(
          operation_kind: "origination",
          delegatable: false,
          spendable: false,
          from: from,
          amount: 0.05,
          fee: 0.05,
          gas_limit: 0.05,
          storage_limit: 0.006,
          counter: counter,
          manager: from,
          script: script
        ),
        branch: branch
      )

      expect(origination_hex).to be_a String
      expect { origination_hex.to_bin } .not_to raise_error
    end
  end

  describe "#run_transaction" do
    it "returns a hash" do
      res = subject.run_operation(
         operation: subject.transaction_operation(
             from: from,
             to: from,
             amount: 1,
             fee: 0.05,
             gas_limit: 0.05,
             storage_limit: 0.006,
             counter: counter
           ),
         branch: branch,
         chain_id: subject.chain_id,
         signature: TezosClient::RANDOM_SIGNATURE
      )
      pp res
      expect(res).to have_key("metadata")
      expect(res["metadata"]).to have_key("operation_result")
      expect(res["metadata"]["operation_result"]).to have_key("status")
      expect(res["metadata"]["operation_result"]["status"]).to eq "applied"
    end
  end

  describe "#run_origination" do
    it "returns a hash" do
      res = subject.run_operation(
        operation: subject.origination_operation(
          delegatable: false,
          spendable: false,
          from: from,
          amount: 0.05,
          fee: 0.05,
          gas_limit: 0.05,
          storage_limit: 0.006,
          counter: counter,
          manager: from,
          script: script
        ),
        branch: branch,
        chain_id: subject.chain_id,
        signature: TezosClient::RANDOM_SIGNATURE
      )
      expect(res).to be_a Hash

      expect(res).to have_key("metadata")
      expect(res["metadata"]).to have_key("operation_result")
      expect(res["metadata"]["operation_result"]).to have_key("status")
      expect(res["metadata"]["operation_result"]["status"]).to eq "applied"
      expect(res["metadata"]["operation_result"]).to have_key("originated_contracts")
      expect(res["metadata"]["operation_result"]["originated_contracts"][0]).to be_a String

      # pp res
      # pp res['metadata']
    end
  end

  describe "#preapply_transaction" do
    let(:transaction_args) do
      {
        operation:
          subject.transaction_operation(
            from: from,
            to: from,
            amount: 1,
            fee: 0.05,
            gas_limit: 0.05,
            storage_limit: 0.006,
            counter: counter
          ),
        branch: branch
      }
    end

    let(:transaction_hex) { subject.forge_operation(transaction_args) }

    let(:signature) do
      TezosClient.new.sign_operation(
        secret_key: secret_key,
        operation_hex: transaction_hex
      )
    end

    it "works" do
      res = subject.preapply_operation(
        transaction_args.merge(
          protocol: protocol,
          signature: signature
        )
      )
      pp res
      expect(res).to have_key("metadata")
      expect(res["metadata"]).to have_key("operation_result")
      expect(res["metadata"]["operation_result"]).to have_key("status")
      expect(res["metadata"]["operation_result"]["status"]).to eq "applied"
    end
  end

  describe "#preapply_origination" do
    let(:origination_args) do
      {
        operation: subject.origination_operation(
          delegatable: false,
          spendable: false,
          from: from,
          amount: 0.05,
          fee: 0.05,
          gas_limit: 0.05,
          storage_limit: 0.006,
          counter: counter,
          manager: from,
          script: script,
        ),
        branch: branch
      }
    end

    let(:origination_hex) { subject.forge_operation(origination_args) }

    let(:signature) do
      TezosClient.new.sign_operation(
        secret_key: secret_key,
        operation_hex: origination_hex
      )
    end

    it "works" do
      res = subject.preapply_operation(
        origination_args.merge(
          protocol: protocol,
          signature: signature
        )
      )
      pp res
      expect(res).to have_key("metadata")
      expect(res["metadata"]).to have_key("operation_result")
      expect(res["metadata"]["operation_result"]).to have_key("status")
      expect(res["metadata"]["operation_result"]["status"]).to eq "applied"

      expect(res["metadata"]["operation_result"]).to have_key("originated_contracts")
      expect(res["metadata"]["operation_result"]["originated_contracts"][0]).to be_a String
    end
  end
end
