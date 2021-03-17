# frozen_string_literal: true

RSpec.describe TezosClient::SmartpyInterface do
  let(:script) { File.expand_path("./spec/fixtures/demo.py") }



  subject { described_class.new }

  describe "#json_script" do
    context "with empty hash" do
      let(:init_params) { [{}, {}] }

      it "works" do
        json_init_script, json_contract_script = subject.json_scripts(
            script: script,
            args: init_params
        )

        expect(json_init_script).to be_an Hash
        expect(json_contract_script).to be_an Array
      end
    end

    context "with hash set" do
      let(:init_params) { [{value: 1}, {value: "2"}] }

      it "works" do
        json_init_script, json_contract_script = subject.json_scripts(
            script: script,
            args: init_params
        )

        expect(json_init_script).to be_an Hash
        expect(json_contract_script).to be_an Array
      end
    end
  end
end
