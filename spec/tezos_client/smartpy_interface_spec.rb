# frozen_string_literal: true

RSpec.describe TezosClient::SmartpyInterface do
  let(:script) { File.expand_path("./spec/fixtures/demo.py") }
  let(:init_params) { "MyContract(1, 2)" }


  subject { described_class.new }

  describe "#json_script" do
    it "works" do
      json_init_script, json_contract_script = subject.json_scripts(
        script: script,
        init_params: init_params
      )
      expect(json_init_script).to be_an Hash
      expect(json_contract_script).to be_an Array
    end
  end

  describe "#call_parameters" do
    let(:inputs) do
      {
          entry_point: "myEntryPoint",
          params: { int:  "1" }
      }
    end

    it "work" do
      subject.call_parameters(**inputs)
    end
  end
end