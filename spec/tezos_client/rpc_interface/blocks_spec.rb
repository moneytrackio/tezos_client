# frozen_string_literal: true

RSpec.describe TezosClient::RpcInterface::Blocks, :vcr do
  subject { TezosClient::RpcInterface.new }

  let(:block_hash) { "BLXhD7T43aKby6aDasVhB9u4tCdbhUqKZaDPC2sMqZc5Lqh4JpR" }


  describe "#blocks" do
    context "default arguments" do
      it "returns the last 50 blocks" do
        res = subject.blocks
        expect(res).to be_an Array
        expect(res.length).to eq 50
      end
      context "given a block head" do
        let(:head) { "BLCJiR9YDRW4FBYP8dfbp2rf2iokT8gTBwTjNhzUqJzRtcLDh46" }
        it "returns the 50 previous blocks" do
          res = subject.blocks(head: head)
          expect(res).to be_an Array
          expect(res.length).to eq 50
          expect(res[0]).to eq "BLCJiR9YDRW4FBYP8dfbp2rf2iokT8gTBwTjNhzUqJzRtcLDh46"
        end
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

    context "specific block" do
      it "returns the block" do
        res = subject.block_operations(block_hash)
        expect(res).to be_an Array
        expect(res[0]).to be_an Array
        expect(res[0][0]).to have_key "hash"
      end
    end

    context "bock with originations" do
      let(:block_hash) { "BLyqFgbrJ5PRo3hFTSjhJKYjdFHcc2jFjQPg4naQiqrYtG15KgJ" }
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

    context "specific block" do
      it "returns the block" do
        res = subject.block_operation_hashes(block_hash)
        expect(res).to be_an Array
        expect(res[0]).to be_an Array
        expect(res[0][0]).to be_a String
      end
    end
  end

end
