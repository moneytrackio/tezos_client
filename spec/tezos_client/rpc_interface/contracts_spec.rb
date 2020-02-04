# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface::Contracts, :vcr do
  include_context "public rpc interface"
  subject { rpc_interface }

  let(:contract_address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }

  describe "#balance" do
    it "returns the balance" do
      res = subject.balance(contract_address)
      expect(res).to be_a Numeric
    end
  end

  describe "#contract_counter" do
    it "returns the counter" do
      res = subject.contract_counter(contract_address)
      expect(res).to be_a Numeric
    end
  end

  describe "#contract_manager_key" do
    it "returns the manager public key" do
      res = subject.contract_manager_key(contract_address)
      expect(res).to start_with("edpk")
    end
  end

  describe "#contract_storage" do

    let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }
    let(:init_params) { '"test"' }

    let(:new_contract_address) do
      res = tezos_client.originate_contract(
        from: source,
        amount: amount,
        script: script,
        secret_key: secret_key,
        init_params: init_params
      )
      monitor_operation(res[:operation_id])
      res[:originated_contract]
    end

    let!(:contract_address) do
      if reading_vcr_cassette?
        "KT1KxbB1jzRChznkjbqDQB86VJoEj7saVPzT"
      else
        new_kt_hash = new_contract_address
        puts "please insert this contract hash here #{new_kt_hash} #{__FILE__}:#{__LINE__-3}"
        new_kt_hash
      end
    end
    it "returns the contract storage" do
      res = subject.contract_storage(contract_address)
      p res
    end
  end

  describe "#big_map_value" do
    let(:big_map_id) { 74 }
    let(:key) { { string: "InsuranceContract" } }
    let(:type_key) { { prim: "string" } }

    it "returns the the big map value" do
      res = subject.big_map_value(big_map_id: big_map_id, key: key, type_key: type_key)
      expect(res).to eq(
        "prim" => "Pair",
        "args" => [
          { "string" => "KT1J3z1Fbc4MgEh9b5pEe4ZzgK8Wcn7Q8F6M" },
          { "string" => "edpkugJHjEZLNyTuX3wW2dT4P7PY5crLqq3zeDFvXohAs3tnRAaZKR" }
        ]
      )
    end
  end
end
