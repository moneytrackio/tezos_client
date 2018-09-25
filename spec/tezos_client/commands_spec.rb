# frozen_string_literal: true

RSpec.describe TezosClient::Commands do
  include_context "public rpc interface"

  subject { tezos_client }


  # Tezos client is not installed on travis machine
  unless ENV["TRAVIS"]
    describe "#known_contracts" do
      it "works" do
        expect do
          subject.known_contracts
        end.not_to raise_error
      end

      it "returns a Hash" do
        res = subject.known_contracts
        p res
        expect(res).to be_a Hash
      end
    end

    describe "#gen_keys" do
      it "works silently" do
        expect do
          subject.gen_keys("spec_#{SecureRandom.hex(3)}")
        end.not_to raise_error
      end
    end

    describe "#addresses" do
      it "works" do
        addresses = subject.addresses
        expect(addresses).to be_a Hash
      end
    end

    describe "#import_secret_key" do
      let(:private_key) { subject.generate_key[:secret_key] }
      let(:key_name) { "spec_#{SecureRandom.hex(3)}" }

      it "import secret keys" do
        subject.import_secret_key(key_name, "unencrypted:#{private_key}")
      end
    end

    describe "#bootstrapped" do
      it "works" do
        res = subject.bootstrapped
        expect(res).to be_a Hash
      end

      it "returns the block Header" do
        res = subject.bootstrapped
        expect(res).to be_a Hash
        expect(res["block"]).to be_a String
        expect(res["timestamp"]).to be_a DateTime
      end
    end

  end
end
