# frozen_string_literal: true

RSpec.describe TezosClient, vcr: true do
  include_context "public rpc interface"
  include_context "contract origination"
  subject { tezos_client }

  before do
    wait_new_block
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

    context "with parameters", :require_node do
      let!(:contract_address) do
        originate_demo_contract
      end

      it "works" do
        res = subject.transfer(
          amount: 5,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: contract_address,
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
              "tz1Zbws4QQPy4zKQjQApSHir9kTnKHt5grDn" => 1_000_000_000,
            },
            secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
          )
        end.to raise_exception(TezosClient::TezBalanceTooLow)
      end
    end
  end

  describe "#monitor_operation", :require_node do
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
          allow_any_instance_of(TezosClient).to receive(:block_include_operation?).and_raise(StandardError, "rspec makes me fail")
          expect { subject.monitor_operation(op_id) }.to raise_exception StandardError, "rspec makes me fail"
        end
      end
    end
  end

  describe "inject_raw_operations", :require_node do
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
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }

    context "with liquidity", :require_node do
      let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
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

      context "with bad params" do

        it "raise error" do
          expect {
            res = subject.originate_contract(
              from: source,
              amount: amount,
              script: script,
              secret_key: secret_key,
              init_params: nil
            )
            pp res
          }.to raise_error TezosClient::LiquidityError
        end
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

      context "with no secret_key" do
        it "works" do
          res = subject.originate_contract(
            from: source,
            amount: amount,
            script: script,
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
    end
    context "with smartpy" do
      let(:script) { "./spec/fixtures/demo.py" }
      let(:init_params) { "MyContract()" }

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
    end
  end

  context "#multisig", :require_node do
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

    context "with smartpy" do
      describe "#call_contract" do
        let(:contract_address) { originate_demo_contract_with_smartpy }
        let(:amount) { 1 }

        it "works" do
          res = subject.call_contract(
            from: source,
            amount: amount,
            secret_key: secret_key,
            to: contract_address,
            entrypoint: "default",
            params: { int:  "1" },
            params_type: :micheline
          )
          pp res
        end
      end
    end

    describe "#call Pay" do
      let(:contract_address) { originate_multisig_contract }
      let(:entrypoint) { "pay" }
      let(:params) { "()" }
      let(:amount) { 1 }

      it "works" do
        res = subject.call_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          entrypoint: entrypoint,
          params: params,
          params_type: :caml
        )
        pp res
      end

      context "without script" do
        it "raise error" do
          expect {
            res = subject.call_contract(
              from: source,
              amount: amount,
              script: nil,
              secret_key: secret_key,
              to: contract_address,
              entrypoint: entrypoint,
              params: params,
              params_type: :caml
            )
            pp res
          }.to raise_error ArgumentError, "need liquidity script path with camel type"
        end
      end

      context "with bad params type" do
        it "raise error" do
          expect {
            res = subject.call_contract(
              from: source,
              amount: amount,
              script: script,
              secret_key: secret_key,
              to: contract_address,
              entrypoint: entrypoint,
              params: params,
              params_type: :micheline
            )
            pp res
          }.to raise_error
        end
      end

      context "with unknown params type" do
        it "raise error" do
          expect {
            res = subject.call_contract(
              from: source,
              amount: amount,
              script: script,
              secret_key: secret_key,
              to: contract_address,
              entrypoint: entrypoint,
              params: params,
              params_type: :toto
            )
            pp res
          }.to raise_error ArgumentError, "params type must be equal to [ :micheline, :caml ]"
        end
      end
    end

    describe "ignore_counter_error option" do
      let(:params) do
        {
          amount: 0.1,
          from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
          secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
          ignore_counter_error: ignore_counter_error
        }
      end

      context "when the ignore_counter_error option is set to false" do
        let(:ignore_counter_error) { false }

        it "raises an error when two transactions from the same source are executed" do
          disabling_vcr do
            expect do
              subject.transfer params.merge(amount: 0.01)
              subject.transfer params
            end.to raise_error TezosClient::RpcRequestFailure, /Counter .* already used for contract/
          end
        end
      end

      context "when the ignore_counter_error option is set to false" do
        let(:ignore_counter_error) { true }

        it "works when two transactions from the same source are executed" do
          disabling_vcr do
            expect do
              subject.transfer params.merge(amount: 0.01)
              subject.transfer params
            end.not_to raise_error
          end
        end
      end
    end

    describe "#call Manage" do
      let(:contract_address) { originate_multisig_contract }
      let(:manage_amount) { 1 }
      let(:entrypoint) { "manage" }
      let(:params) { "(Some { destination = tz1YLtLqD1fWHthSVHPD116oYvsd4PTAHUoc; amount = #{manage_amount}tz })" }
      before do
        res = subject.call_contract(
          from: source,
          amount: manage_amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          entrypoint: "pay",
          params: %w{ () },
          params_type: :caml
        )
        monitor_operation(res[:operation_id])
      end

      it "works" do
        res = subject.call_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          entrypoint: entrypoint,
          params: params,
          params_type: :caml
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


    it "fails in private chain" do
      expect(key[:address]).to eq "tz1RdraebVC4gRbrnMDWQjZ28FtvgQZWJp21"

      expect {
        subject.activate_account(
          pkh: pkh,
          secret: secret,
          from: pkh,
          secret_key: secret_key
        )
      }.to raise_error TezosClient::InvalidActivation
    end
  end

  describe "#reveal public key" do
    let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
    let(:registered_key) do
      {
        secret_key: "edsk4aJApTCTa5DHNi6yjgRVpNNZPz4YmiffJtSvgbsQTWEVU7QK2M",
        public_key: "edpkusTky9AbPqUhnaJUeYiRQH6pUEyTr4vNv1qBPdTFNSQeyxeYBX",
        address: "tz1L4WMuHychSsgJiS9At69TZx6ZbYVBKsfs"
      }
    end

    let(:key) do
      if reading_vcr_cassette?
        registered_key
      else
        key = subject.generate_key
        puts "Please update :registered_key to this value: #{key}"
        key
      end
    end
    let(:secret_key) { key[:secret_key] }

    before do
      subject.transfer(
        amount: 0.1,
        from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
        to: key[:address],
        secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
      )
      wait_new_block
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
        wait_new_block
      end

      it "raises an exception" do
        expect do
          subject.reveal_pubkey(secret_key: secret_key)
          wait_new_block
          subject.reveal_pubkey(secret_key: secret_key)
        end.to raise_exception TezosClient::PreviouslyRevealedKey, "Previously revealed key for address tz1UTikevS42TFpT4uhtxkNbeYsG3ea7bsrB"
      end
    end
  end

  describe "#contract_manager_key" do
    let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
    let(:address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }

    it "works" do
      res = subject.contract_manager_key(address)
      expect(res).to match /edpk[a-zA-Z1-9]+/
    end

    context "not reveal key" do
      let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
      let(:key) { subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/456789658'") }

      it "works" do
        res = subject.contract_manager_key(key[:address])
        expect(res).to be_nil
      end
    end
  end

  describe "#get_storage", :require_node, vcr: false do
    let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
    let!(:contract_address) { originate_demo_contract }

    # TODO: fix me when alphanet-node is up again
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

  describe "#contract failure", :require_node do
    let(:script) { File.expand_path("./spec/fixtures/multisig.liq") }
    let(:source) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:amount) { 0 }
    let!(:contract_address) { originate_multisig_contract }
    let(:entrypoint) { "manage" }
    let(:params) {  "(Some { destination = tz1YLtLqD1fWHthSVHPD116oYvsd4PTAHUoc; amount = 10000000000tz })"  }


    it "raises an error" do
      expect do
        subject.call_contract(
          from: source,
          amount: amount,
          script: script,
          secret_key: secret_key,
          to: contract_address,
          entrypoint: entrypoint,
          params: params,
          params_type: :caml
        )
      end.to raise_exception TezosClient::ScriptRuntimeError, 'Script runtime Error when executing : {"string"=>"Balance to low for withdrawal"} (location: 199)'
    end
  end
end
