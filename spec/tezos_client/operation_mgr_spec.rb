# frozen_string_literal: true

RSpec.describe TezosClient::OperationMgr do
  subject(:operation_mgr) { described_class.new(rpc_interface: fake_rpc_interface, rpc_operation_args: "", secret_key: "", branch: "", protocol: "") }

  describe "#preapply" do
    subject { operation_mgr.preapply }

    let(:json_response) { JSON.parse(File.read(File.expand_path(fixture_file))).map(&:with_indifferent_access)}
    let(:fake_rpc_interface) { instance_double(TezosClient::RpcInterface, preapply_operations: json_response) }

    before do
      expect(operation_mgr).to receive(:rpc_operation_args)
      expect(operation_mgr).to receive(:base_58_signature)
    end

    context "when transaction result contains errors in internal operation" do
      let(:fixture_file) { "./spec/fixtures/operation_results/failure_within_internal_operation.json" }

      it "raise internal operation error" do
        expect { subject }.not_to raise_error TezosClient::ScriptRuntimeError, /not enough tokens/
      end
    end

    context "when transaction result contains errors" do
      let(:fixture_file) { "./spec/fixtures/operation_results/failure.json" }

      it "raise error" do
        expect { subject }.not_to raise_error TezosClient::ScriptRuntimeError, /azrzae/
      end
    end

    context "when transaction succeeds" do
      let(:fixture_file) { "./spec/fixtures/operation_results/success.json" }

      it "do not raise error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
