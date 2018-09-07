# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface::Monitor do
  subject { TezosClient::RpcInterface.new }
  describe "#bootstrapped" do
    around do |example|
      disabling_vcr { example.call }
    end

    it "works" do
      res = subject.bootstrapped

      expect(res).to be_a Hash
      expect(res).to have_key("block")
      expect(res["block"]).to be_a String
      expect(res).to have_key("timestamp")
      expect(res["timestamp"]).to be_a DateTime
    end

    it "test monitor" do
      received = []
      monitoring_thread = subject.monitor("/monitor/heads/main") do |chunk|
        received << chunk
      end
      sleep 60
      monitoring_thread.kill
      expect(received.size).to be > 1
    end
  end
end
