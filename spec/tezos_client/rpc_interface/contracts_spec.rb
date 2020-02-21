# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface::Contracts, :vcr do
  include_context "public rpc interface"
  subject { rpc_interface }

  let(:script) { File.expand_path("./spec/fixtures/demo.py") }
  let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
  let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
  let(:amount) { 0 }
  let(:init_params) { "MyContract()" }


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

  describe "#balance" do
    let(:contract_address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }

    it "returns the balance" do
      res = subject.balance(contract_address)
      expect(res).to be_a Numeric
    end
  end

  describe "#contract_counter" do
    let(:contract_address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }

    it "returns the counter" do
      res = subject.contract_counter(contract_address)
      expect(res).to be_a Numeric
    end
  end

  describe "#contract_manager_key" do
    let(:contract_address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }

    it "returns the manager public key" do
      res = subject.contract_manager_key(contract_address)
      expect(res).to start_with("edpk")
    end
  end

  describe "#contract_storage" do
    let!(:contract_address) do
      if reading_vcr_cassette?
        "KT1HftW8XhqWMyhRfZQYh9hVfi4SgyatEpve"
      else
        new_kt_hash = new_contract_address
        STDERR.puts "please insert this contract hash here #{new_kt_hash} #{__FILE__}:#{__LINE__-3}"
        new_kt_hash
      end
    end
    it "returns the contract storage" do
      res = subject.contract_storage(contract_address)
      p res
    end
  end

  describe "#big_map_value" do
    let!(:contract_address) do
      if reading_vcr_cassette?
        "KT1PNYsy2w5EreQevZsaZgv4ux3okwNdLUCr"
      else
        new_kt_hash = new_contract_address
        puts "please insert this contract hash here #{new_kt_hash} #{__FILE__}:#{__LINE__-3}"
        new_kt_hash
      end
    end

    let(:big_map_id) { subject.list_big_map_by_contract(contract_address: contract_address)[1][:id] }
    let(:key) { "hello" }
    let(:type_key) { { prim: "string" } }

    before do
      res = tezos_client.call_contract(
        from: source,
        amount: amount,
        secret_key: secret_key,
        to: contract_address,
        entrypoint: "add_second",
        params: {
          "prim" => "Pair",
          "args" => [
            { "string" => key },
            { "string" => "world" }]
        },
        params_type: :micheline
      )
      monitor_operation(res[:operation_id])
    end

    it "returns the the big map value" do
      res = subject.big_map_value(big_map_id: big_map_id, key: { "string" => key }, type_key: type_key)
      expect(res).to eq(
        "string" => "world"
      )
    end
  end

  describe "#list_big_map_by_contract", :vcr, :deploying_simple_contract do
    let!(:contract_address) do
      if reading_vcr_cassette?
        "KT1CVHHink8sJcD6jV4nuaeBFJUpP5vDKkCD"
      else
        new_kt_hash = new_contract_address
        puts "please insert this contract hash here #{new_kt_hash} #{__FILE__}:#{__LINE__-3}"
        new_kt_hash
      end
    end

    it "returns the list of big map in contract" do
      res = subject.list_big_map_by_contract(contract_address: contract_address)
      expect(res).to match_array([
        {
          name: :big_map_first,
          id: a_string_matching(/\A[0-9]+\z/),
          type_value: { prim: "int" },
          type_key: { prim: "string" }
        }.with_indifferent_access,
        {
          name: :big_map_second,
          id: a_string_matching(/\A[0-9]+\z/),
          type_value: { prim: "string" },
          type_key: { prim: "string" }
        }.with_indifferent_access
      ])
    end
  end
end
