# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface, :vcr do
  describe "#get" do
    it "works" do
      res = subject.get "/monitor/bootstrapped"
      expect(res).to be_a Hash
      p res
    end
  end
end
