# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface, :vcr do
  describe "#constants" do
    it "returns the constants" do
      res = subject.constants
      expect(res).to be_a Hash
      expect(res).to have_key "proof_of_work_nonce_size"
    end
  end

  describe "#head_hash" do
    it "returns the current block hash" do
      res = subject.head_hash
      expect(res).to be_a String
      expect(res).to start_with "B"
    end
  end

  describe "#chain_id" do
    it "returns the current chain id" do
      res = subject.chain_id
      expect(res).to be_a String
      expect(res).to start_with "Net"
    end
  end
end
