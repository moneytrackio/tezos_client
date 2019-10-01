# frozen_string_literal: true

RSpec.describe TezosClient, :vcr do

  include_context "public rpc interface"
  subject { tezos_client }

  def wait_new_block(timeout: 240)
    blocks_to_wait = 2
    received_blocks = []
    monitor_thread = subject.monitor_block do |block|
      received_blocks << block[:hash]
      received_blocks.uniq!
    end

    limit_time = Time.now + timeout

    while received_blocks.size < blocks_to_wait && Time.now < limit_time
      sleep(1)
    end
    monitor_thread.terminate

    raise "no block received for 4 minutes" unless received_blocks.size == blocks_to_wait
  end

  before do
    disabling_vcr { wait_new_block } if VCR.current_cassette&.recording?
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
          to: "KT1FLmwGK2ptfyG8gxAPWPMVS7iGgPzkJEBE",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
          parameters: '"pro"'
        )
        expect(res).to be_a Hash
        expect(res).to have_key :operation_id
        expect(res[:operation_id]).to be_a String
      end
    end

    context "with decimal amount" do
      it "works" do
        res = subject.transfer(
          amount: 0.1,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
        )
        expect(res).to be_a Hash
        expect(res).to have_key :operation_id
        expect(res[:operation_id]).to be_a String
      end
    end
  end

  describe "#transfer_to_many" do
    it "works" do
      res = subject.transfer_to_many(
        from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        amounts: {
          "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" => 0.01,
          "tz1Zbws4QQPy4zKQjQApSHir9kTnKHt5grDn" => 0.02
        },
        secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
      )
      expect(res).to be_a Hash
      expect(res).to have_key :operation_id
      expect(res[:operation_id]).to be_a String
    end

    context "not enough tezos" do
      it "raises an exception" do
        expect do
          subject.transfer_to_many(
            from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
            amounts: {
              "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" => 0.01,
              "tz1Zbws4QQPy4zKQjQApSHir9kTnKHt5grDn" => 100_000,
            },
            secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
          )
        end.to raise_exception(TezosClient::TezBalanceTooLow)
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

      context "when monitoring thread raises an exception" do
        it "redirects the exception" do
          disabling_vcr do
            allow_any_instance_of(TezosClient).to receive(:block_include_operation?).and_raise(Exception, "rspec makes me fail")
            expect { subject.monitor_operation(op_id) }.to raise_exception Exception, "rspec makes me fail"
          end
        end
      end
    end
  end

  describe "inject_raw_operations" do
    let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }
    let(:init_params) { '"test"' }

    it "works" do
      origination = subject.originate_contract(
        from: source,
        amount: amount,
        script: script,
        secret_key: secret_key,
        init_params: init_params,
        dry_run: true
      )

      transfer = subject.transfer_to_many(
        from: source,
        amounts: {
          "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" => 0.01,
          "tz1Zbws4QQPy4zKQjQApSHir9kTnKHt5grDn" => 0.02
        },
        secret_key: secret_key,
        dry_run: true
      )

      raw_operations = transfer[:rpc_operation_args].push(origination[:rpc_operation_args])

      subject.inject_raw_operations(
        from: source,
        secret_key: secret_key,
        raw_operations: raw_operations
      )
    end
  end

  describe "#pending_operations" do

    let!(:op_id) do
      res = subject.transfer(
        amount: 1,
        from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
      )
      res[:operation_id]
    end

    it "works" do
      res = subject.pending_operations
      expect(res).to be_a Hash
      operations = res["applied"].select { |operation| operation.fetch("contents", []).map { |content| content&.fetch("source", nil) }&.include?("tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq") }
      expect(operations.size).to eq 1
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
      expect(res).to have_key :rpc_operation_args

      expect(res[:operation_id]).to be_a String
      expect(res[:originated_contract]).to be_a String
      expect(res[:rpc_operation_args]).to be_a Hash
    end

    context "dry_run" do
      it "works" do
        res = subject.originate_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          init_params: init_params,
          dry_run: true
        )

        expect(res).to be_a Hash
        expect(res).to have_key :originated_contract
        expect(res).to have_key :rpc_operation_args

        expect(res[:originated_contract]).to be_a String
        expect(res[:rpc_operation_args]).to be_a Hash
      end
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

    describe "#call Pay" do
      let(:contract_address) { "KT1MX7W5bWVi9T3wivxKd96s2uFUyFx1nLx7" }
      let(:call_params) { %w{pay ()} }
      let(:amount) { 0.001 }

      it "works" do
        disabling_vcr do
          res = subject.transfer(
            amount: 0.1,
            from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
            to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
            secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
          )
          pp res
          counter =  res[:rpc_operation_args][:counter].to_i + 1

          20.times do |i|
            res2 = subject.transfer(
              amount: 0.01,
              from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
              to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
              secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
              cast_counter: counter + i
            )
            pp res2
          end
        end
      end
    end

    describe "#call Manage" do
      let(:contract_address) { "KT1MX7W5bWVi9T3wivxKd96s2uFUyFx1nLx7" }
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
  end


  describe "#activate account" do
    let(:mnemonic) { "twelve april shield tell audit fever strike radio lunch father orphan lock fancy clutch sister" }
    let(:password) { "igfcjveu.zufhhxdz@tezos.example.orgS6fvIJnDXQ" }
    let(:secret) { "23d18abce360452faa65b9909b6bf259562af0f8" }

    let(:key) { subject.generate_key(mnemonic: mnemonic, password: password) }
    let(:secret_key) { key[:secret_key] }
    let(:pkh) { key[:address] }


    it "works" do
      expect(key[:address]).to eq "tz1RdraebVC4gRbrnMDWQjZ28FtvgQZWJp21"

      res = subject.activate_account(
        pkh: pkh,
        secret: secret,
        from: pkh,
        secret_key: secret_key
      )
      pp res
    end
  end

  describe "#reveal public key" do
    let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
    let(:key) { subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/0'") }
    let(:secret_key) { key[:secret_key] }

    before do
      subject.transfer(
        amount: 0.1,
        from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        to: key[:address],
        secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
      )
      disabling_vcr { wait_new_block } if VCR.current_cassette&.recording?
    end


    it "works" do
      res = subject.reveal_pubkey(
        secret_key: secret_key
      )

      expect(res).to have_key(:operation_id)
      expect(res[:operation_id]).to match /o[a-zA-Z1-9]+/
    end

    context "previously revealed key" do

      let(:key) { subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/1'") }
      let(:secret_key) { key[:secret_key] }

      before do
        subject.transfer(
          amount: 0.1,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: key[:address],
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
        )
        disabling_vcr { wait_new_block } if VCR.current_cassette&.recording?
      end

      it "raises an exception" do
        expect do
          subject.reveal_pubkey(secret_key: secret_key)
          disabling_vcr { wait_new_block } if VCR.current_cassette&.recording?
          subject.reveal_pubkey(secret_key: secret_key)
        end.to raise_exception TezosClient::PreviouslyRevealedKey, "Previously revealed key for address tz1UTikevS42TFpT4uhtxkNbeYsG3ea7bsrB"
      end
    end
  end

  describe "#contract_manager_key" do
    let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
    let(:key) { subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/0'") }

    it "works" do
      res = subject.contract_manager_key(key[:address])
      expect(res).to have_key(:manager)
      expect(res[:manager]).to eq key[:address]
      expect(res).to have_key(:key)
      expect(res[:key]).to match /edpk[a-zA-Z1-9]+/
    end

    context "not reveal key" do
      let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
      let(:key) { subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/456789658'") }

      it "works" do
        res = subject.contract_manager_key(key[:address])
        expect(res).to have_key(:manager)
        expect(res[:manager]).to eq key[:address]
        expect(res).not_to have_key(:key)
      end
    end
  end

  describe "#get_storage", vcr: false do
    let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
    let(:contract_address) { "KT1FLmwGK2ptfyG8gxAPWPMVS7iGgPzkJEBE" }

    it "works" do
      res = subject.get_storage(script: script, contract_address: contract_address)
      expect(res).to be_a String
    end
  end


  describe "#activation error" do
    let(:mnemonic) { "twelve april shield tell audit fever strike radio lunch father orphan lock fancy clutch sister" }
    let(:password) { "igfcjveu.zufhhxdz@tezos.example.orgS6fvIJnDXQ" }
    let(:secret) { "23d18abce360452faa65b9909b6bf259562af0f8" }

    let(:key) { subject.generate_key(mnemonic: mnemonic, password: password) }
    let(:secret_key) { key[:secret_key] }
    let(:pkh) { key[:address] }


    it "raises an error" do
      expect do
        subject.activate_account(pkh: pkh, secret: secret, from: pkh, secret_key: secret_key)
      end.to raise_exception TezosClient::InvalidActivation, "Invalid activation (pkh: tz1RdraebVC4gRbrnMDWQjZ28FtvgQZWJp21)"
    end
  end

  describe "#not enough tez error" do
    it "raises an error" do
      expect do
        subject.transfer(
          amount: 1000000000,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
        )
      end.to raise_exception TezosClient::TezBalanceTooLow, /Tezos balance too low for address tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq \(balance: \d+, amount 1000000000000000\)/
    end
  end

  describe "#contract failure" do
    let(:script) { File.expand_path("./spec/fixtures/multisig.liq") }
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }
    let(:contract_address) { "KT1MX7W5bWVi9T3wivxKd96s2uFUyFx1nLx7" }
    let(:call_params) { [ "manage", "(Some { destination = tz1YLtLqD1fWHthSVHPD116oYvsd4PTAHUoc; amount = 10000000000tz })" ] }


    it "raises an error" do
      expect do
        subject.call_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          parameters: call_params
        )
      end.to raise_exception TezosClient::ScriptRuntimeError, 'Script runtime Error when executing : {"string"=>"Balance to low for withdrawal"} (location: 199)'
    end
  end
end