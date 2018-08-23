# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface do
  describe "#bootstrapped" do
    it "works" do
      res = subject.bootstrapped

      expect(res).to be_a Hash
      expect(res).to have_key("block")
      expect(res["block"]).to be_a String
      expect(res).to have_key("timestamp")
      expect(res["timestamp"]).to be_a DateTime
    end

    it "test monitor" do
      monitoring_thread = subject.monitor("/monitor/heads/main") do |chunk|
        p chunk
      end
      p "monitoring"
      sleep 10
      puts "time to sleep"
      monitoring_thread.kill
    end
  end
end
