# frozen_string_literal: true

RSpec.describe TezosClient::SmartpyInterface do
  let(:script) { File.expand_path("./spec/fixtures/demo.py") }

  subject { described_class.new }

  describe "#origination_script" do
    context "with empty hash" do
      let(:init_params) { [{}, {}] }

      it "works" do
        origination_script = subject.origination_script(
          script: script,
          init_params: init_params
        )
        file = File.open("demo_script.json", "w")
        file.write JSON.pretty_generate(origination_script)

        expect(origination_script).to be_an Hash
      end
    end
  end

  describe "#json_script" do
    context "with empty hash" do
      let(:init_params) { [{}, {}] }

      it "works" do
        json_init_script, json_contract_script = subject.json_scripts(
            script: script,
            init_params: init_params
          )

        expect(json_init_script).to be_an Hash
        expect(json_contract_script).to be_an Array
      end
    end

    context "with hash set" do
      let(:init_params) { [{ value: 1 }, { value: "2" }] }

      it "works" do
        json_init_script, json_contract_script = subject.json_scripts(
            script: script,
            init_params: init_params
          )

        expect(json_init_script).to be_an Hash
        expect(json_contract_script).to be_an Array
      end

      context "with protocol set" do
        it "works" do
          json_init_script, json_contract_script = subject.json_scripts(
              script: script,
              init_params: init_params,
              smartpy_flags: {
                protocol: "delphi"
              }
            )

          expect(json_init_script).to be_an Hash
          expect(json_contract_script).to be_an Array
        end
      end
    end
  end
end
