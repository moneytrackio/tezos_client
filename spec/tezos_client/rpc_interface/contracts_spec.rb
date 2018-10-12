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
      expect(res).to be_a Hash
      expect(res).to have_key "manager"
      expect(res["manager"]).to start_with("tz1")

      expect(res).to have_key "key"
      expect(res["key"]).to start_with("edpk")
    end
  end
end
