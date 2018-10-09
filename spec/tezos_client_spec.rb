# frozen_string_literal: true

RSpec.describe TezosClient, :vcr do

  include_context "public rpc interface"
  subject { tezos_client }

  def wait_new_block(timeout: 60)
    blocks_to_wait = 2
    monitor_thread = subject.monitor_block do
      blocks_to_wait -= 1
    end

    limit_time = Time.now + timeout

    while blocks_to_wait > 0 && Time.now < limit_time
      sleep(1)
    end
    monitor_thread.terminate
  end

  before do
    disabling_vcr { wait_new_block } if VCR.current_cassette.recording?
  end

  describe "#transfer" do
    it "works" do
      res = subject.transfer(
        amount: 1,
        from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
      )
      expect(res).to be_a Hash
      expect(res).to have_key :operation_id
      expect(res[:operation_id]).to be_a String
    end

    context "with parameters" do
      it "works" do
        res = subject.transfer(
          amount: 5,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "KT1MZTrMDPB42P9yvjf7Cy8Lkjxjj4jetbCt",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
          parameters: '"pro"'
        )
        expect(res).to be_a Hash
        expect(res).to have_key :operation_id
        expect(res[:operation_id]).to be_a String
      end
    end
  end

  unless ENV["TRAVIS"]
    describe "#monitor_operation" do
      let(:op_id) do
        res = subject.transfer(
          amount: 1,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
        )
        res[:operation_id]
      end
      it "works" do
        disabling_vcr do
          block_id = subject.monitor_operation(op_id)
          expect(block_id).to be_a String
        end
      end
    end
  end


  describe "#originate_contract" do
    let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }
    let(:init_params) { '"test"' }

    it "works" do
      res = subject.originate_contract(
        from: source,
        amount: amount,
        script: script,
        secret_key: secret_key,
        init_params: init_params
      )

      expect(res).to be_a Hash
      expect(res).to have_key :operation_id
      expect(res).to have_key :originated_contract
      expect(res[:operation_id]).to be_a String
      expect(res[:originated_contract]).to be_a String
    end

    context "with no script" do
      it "works" do
        res = subject.originate_contract(
          from: source,
          amount: amount,
          secret_key: secret_key,
          spendable: true
        )

        expect(res).to be_a Hash
        expect(res).to have_key :operation_id
        expect(res).to have_key :originated_contract
        expect(res[:operation_id]).to be_a String
        expect(res[:originated_contract]).to be_a String
        pp res
      end
    end
  end


  context "#multisig" do
    let(:script) { File.expand_path("./spec/fixtures/multisig.liq") }
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }

    describe "#originate_contract" do
      let(:init_params) { ["Set [#{source}]", "1p"] }

      it "works" do
        res = subject.originate_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          init_params: init_params
        )

        expect(res).to be_a Hash
        expect(res).to have_key :operation_id
        expect(res).to have_key :originated_contract
        expect(res[:operation_id]).to be_a String
        expect(res[:originated_contract]).to be_a String
        p res
      end
    end

    describe "#call Manage" do
      let(:contract_address) { "KT1STzq9p2tfW3K4RdoM9iYd1htJ4QcJ8Njs" }
      let(:call_params) { [ "manage", "(Some { destination = tz1YLtLqD1fWHthSVHPD116oYvsd4PTAHUoc; amount = 1tz })" ] }

      it "works" do
        res = subject.call_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          parameters: call_params
        )
        pp res
      end
    end

    describe "#call Pay" do
      let(:contract_address) { "KT1STzq9p2tfW3K4RdoM9iYd1htJ4QcJ8Njs" }
      let(:call_params) { [ "pay", "()" ] }
      let(:amount) { 1 }

      it "works" do
        res = subject.call_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          parameters: call_params
        )
        pp res
      end
    end
  end
end