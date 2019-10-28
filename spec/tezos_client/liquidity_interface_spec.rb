# frozen_string_literal: true

RSpec.describe TezosClient::LiquidityInterface do
  include_context "public rpc interface"
  include_context "contract origination"


  let(:script) { File.expand_path("./spec/fixtures/demo.liq") }
  let(:from) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
  let(:contract_address) { "KT1FLmwGK2ptfyG8gxAPWPMVS7iGgPzkJEBE" }

  let(:rpc_node_address) { "tezos_node" }
  let(:rpc_node_port) { 8094 }

  let(:default_options) { { rpc_node_address: rpc_node_address, rpc_node_port: rpc_node_port } }

  context "with verbose option" do
    let(:interface) { TezosClient::LiquidityInterface.new(default_options.merge(options: { verbose: true })) }

    describe "#options" do
      subject { interface.options }

      it "sets verbose option" do
        expect(subject).to eq verbose: true
      end
    end

    describe "#liquidity_cmd" do
      subject { interface.liquidity_cmd verbose: true }

      it "add verbose param" do
        expect(subject).to match(/--verbose/)
      end
    end
  end

  context "without options" do
    subject { TezosClient::LiquidityInterface.new(default_options) }

    describe "#initial_storage" do
      it "works" do
        res = subject.initial_storage(
          from: from,
          script: script,
          init_params: '"pierre"'
        )
        expect(res).to be_an Array
      end
    end

    describe "#json_script" do
      it "works" do
        json_init_script, json_contract_script = subject.json_scripts(
          script: script
        )
        expect(json_init_script).to be_an Array
        expect(json_contract_script).to be_an Array
      end
    end

    describe "#origination_script" do
      it "works" do
        res = subject.origination_script(
          from: from,
          script: script,
          init_params: '"pierre"'
        )
        expect(res).to be_a Hash
        p res
      end
    end

    describe "#get_storage" do
      include_context "contract origination"

      let!(:contract_address) do
        originate_demo_contract
      end

      it "retrieves the current storage" do
        res = subject.get_storage(
          script: script,
          contract_address: contract_address
        )
        expect(res).to be_a String
        p res
      end

      context "multisig.liq contract" do
        let(:script) { File.expand_path("./spec/fixtures/multisig.liq") }
        let(:init_params) { ["Set [#{from}]", "1p"] }
        let(:call_parameters) { ["pay", "()"] }

        let!(:contract_address) { originate_multisig_contract }

        it "gets the initial storage" do
          res = subject.initial_storage(
            from: from,
            script: script,
            init_params: init_params
          )
          p res
          expect(res).to be_a Hash
        end

        it "gets the current storage" do
          res = subject.get_storage(
            script: script,
            contract_address: contract_address
          )
          expect(res).to be_a String
          p res
        end

        it "gets the current params" do
          res = subject.call_parameters(
            script: script,
            parameters: call_parameters
          )
          p res
        end
      end
    end

    describe "#pack_data" do
      let(:data) { '("blah", 12p, edpkuFkrBfbg6La44p5qdWMAUFCgVh6mY3HA7tGFBkixd7GThP4YQZ)' }
      let(:type) { "(string * nat * key)" }

      let(:packed_data) { "0x0507070100000004626c61680707000c0a000000210050ae93c352b148de86b3717e77cfd3c7c372878227cf38010b2faeb3d2aa7460" }

      it "works" do
        expect(subject.pack_data(data: data, type: type)).to eq packed_data
      end
    end
  end
end
