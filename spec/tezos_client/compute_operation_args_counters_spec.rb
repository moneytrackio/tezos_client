# frozen_string_literal: true

RSpec.describe TezosClient::ComputeOperationArgsCounters do
  subject { described_class.new(pending_operations: pending_operations, operation_args: operation_args).call }

  context "when there is no pending operation" do
    let(:pending_operations) { { "applied" => [] } }
    let(:operation_args) do
      [{ source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "168" }]
    end

    it "returns the same operation_args" do
      expect(subject).to eq operation_args
    end
  end

  context "when there is one pending operation" do
    let(:pending_operations) do
      {
        "applied" =>
        [
          { "hash" => "oonsGDMUpW8iQFBsyKbPdw4X45sCVfF6U7EbaW5QJWsTtWdKHGv",
            "contents" => [{ "kind" => "transaction", "source" => "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", "counter" => "189", "destination" => "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }],
            "signature" => "sigatFpAoRC2k85tXxKMzVQYvNvoQxKzYL12qvQtsPHyGpZCWJtLu4gJhRG1DMWYnpY9gKLYY3oRcNi9c8TC3bD5bj7AuWR3" }
        ]
      }
    end

    context "when there is one operation arg" do
      let(:operation_args) do
        [{ source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "189" }]
      end

      it "returns the operation args with updated counter" do
        expect(subject).to eq([{ source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "190" }])
      end
    end

    context "when there is multiple operation args with the same source" do
      let(:operation_args) do
        [
          { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "189" },
          { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "190" }
        ]
      end

      it "returns the operation args with updated counters" do
        expect(subject).to eq(
          [
            { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "190" },
            { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "191" }
          ]
        )
      end
    end
  end

  context "when there is multiple pending operations from the same source" do
    let(:pending_operations) do
      {
        "applied" =>
        [
          { "hash" => "oonsGDMUpW8iQFBsyKbPdw4X45sCVfF6U7EbaW5QJWsTtWdKHGv",
            "contents" => [{ "kind" => "transaction", "source" => "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", "counter" => "189", "destination" => "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }],
            "signature" => "sigatFpAoRC2k85tXxKMzVQYvNvoQxKzYL12qvQtsPHyGpZCWJtLu4gJhRG1DMWYnpY9gKLYY3oRcNi9c8TC3bD5bj7AuWR3" },
          { "hash" => "oonsGDMUpW8iQFBsyKbPdw4X45sCVfF6U7EbaW5QJWsTtWdKHGv",
            "contents" => [{ "kind" => "transaction", "source" => "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", "counter" => "190", "destination" => "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }],
            "signature" => "sigatFpAoRC2k85tXxKMzVQYvNvoQxKzYL12qvQtsPHyGpZCWJtLu4gJhRG1DMWYnpY9gKLYY3oRcNi9c8TC3bD5bj7AuWR3" }
        ]
      }
    end

    context "when there is one operation arg" do
      let(:operation_args) do
        [{ source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "189" }]
      end

      it "returns the operation args with updated counter" do
        expect(subject).to eq([{ source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "191" }])
      end
    end

    context "when there is multiple operation args with the same source" do
      let(:operation_args) do
        [
          { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "189" },
          { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "190" }
        ]
      end

      it "returns the operation args with updated counters" do
        expect(subject).to eq(
          [
            { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "191" },
            { source: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq", counter: "192" }
          ]
        )
      end
    end
  end
end
