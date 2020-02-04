# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface::Blocks do
  include_context "public rpc interface"
  subject { rpc_interface }
  let(:block_hash) { subject.block_header.fetch(:hash) }

  describe "#blocks" do
    context "default arguments" do
      it "returns the last 50 blocks" do
        res = subject.blocks
        expect(res).to be_an Array
        expect(res.length).to eq 50
      end
    end

    context "given a block head" do
      let(:head) { block_hash }
      it "returns the 50 previous blocks" do
        res = subject.blocks(head: head)
        expect(res).to be_an Array
        expect(res.length).to eq 50
        expect(res[0]).to match /B[1-9a-zA-Z]+/
      end
    end

    context "given a min_date" do
      let(:min_date) { Time.parse("2050-09-26T00:00:00Z") }
      it "returns an empty set" do
        res = subject.blocks(length: 10, min_date: min_date)
        expect(res).to be_nil
      end
    end

    context "given a min_date and a block head" do
      let(:head) { block_hash }
      let(:min_date) { Time.parse("2050-09-26T00:00:00Z") }
      it "ignores the min_date argument :(" do
        res = subject.blocks(head: head, min_date: min_date)
        expect(res).to be_an Array
        expect(res.length).to eq 50
      end
    end
  end

  describe "#block" do
    context "default block" do
      it "returns the head block" do
        res = subject.block
        expect(res).to be_a Hash
        expect(res).to have_key "operations"
      end
    end

    context "specific block" do
      it "returns the block" do
        res = subject.block(block_hash)
        expect(res).to be_a Hash
        expect(res).to have_key "operations"
      end
    end
  end

  describe "#block_header" do
    context "default block" do
      it "returns the head block" do
        res = subject.block_header
        expect(res).to be_a Hash
        expect(res).to have_key "level"
      end
    end

    context "specific block" do
      it "returns the block" do
        res = subject.block_header(block_hash)
        expect(res).to be_a Hash
        expect(res).to have_key "level"
      end
    end
  end

  describe "#block_operations" do
    context "default block" do
      it "returns the head block" do
        res = subject.block_operations
        expect(res).to be_an Array
      end
    end

    context "block with transaction" do
      let!(:block_hash) do
        res = tezos_client.transfer(
          amount: 1,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
        )
        monitor_operation(res[:operation_id])
      end

      it "returns the block" do
        res = subject.block_operations(block_hash)
        expect(res).to be_an Array
        expect(res[3]).to be_an Array
        expect(res[3][0]).to have_key "hash"
      end
    end

    context "block with origination" do
      let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
      let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
      let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
      let(:amount) { 0 }
      let(:init_params) { '"test"' }

      let!(:block_hash) do
        res = tezos_client.originate_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          init_params: init_params
        )
        disabling_vcr { p tezos_client.monitor_operation(res[:operation_id], timeout: 120) }
      end

      it "contain the origination operation" do
        res = subject.block_operations(block_hash)
        expect(res).to be_an Array
        expect(res[3]).to be_an Array
        expect(res[3][0]).to have_key "hash"
        expect(res[3][0]["contents"][0]).to have_key "kind"
        expect(res[3][0]["contents"][0]["kind"]).to eq "origination"
      end
    end
  end

  describe "#block_operation_hashes" do
    context "default block" do
      it "returns the head block" do
        res = subject.block_operation_hashes
        expect(res).to be_an Array
      end
    end

    context "Block with operations" do
      let!(:block_hash) do
        res = tezos_client.transfer(
          amount: 1,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
        )
        monitor_operation(res[:operation_id])
      end

      it "returns the block" do
        res = subject.block_operation_hashes(block_hash)
        expect(res).to be_an Array
        expect(res[3]).to be_an Array
        expect(res[3][0]).to be_a String
      end
    end
  end
end
