# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface::Monitor, :require_node do
  include_context "public rpc interface"

  subject { rpc_interface }

  describe "#monitor" do
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

    describe "#monitor_block" do
      it "test monitor" do
        received = []
        monitoring_thread = subject.monitor_block do |chunk|
          received << chunk
        end

        timeout = Time.now + 240
        while received.size < 2 && Time.now < timeout
          sleep 1
        end

        monitoring_thread.kill
        block_hashes = received.map { |e| e["hash"] }.uniq
        expect(block_hashes.size).to be > 1
      end
    end
  end
end
