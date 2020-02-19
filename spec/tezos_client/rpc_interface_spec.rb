# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface, :vcr do
  include_context "public rpc interface"
  subject { rpc_interface }

  describe "#get" do
    it "works" do
      res = subject.get "/monitor/bootstrapped"
      expect(res).to be_a Hash
    end
  end

  describe "#get block head" do
    it "works" do
      res = subject.get "chains/main/blocks/head"
      expect(res).to be_a Hash
    end
  end
end
