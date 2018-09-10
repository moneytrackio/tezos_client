# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface, :vcr do

  include_context "public rpc interface"
  subject { rpc_interface }

  describe "#get" do
    it "works" do
      res = subject.get "/monitor/bootstrapped"
      expect(res).to be_a Hash
      p res
    end
  end
end
