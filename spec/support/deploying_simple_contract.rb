# frozen_string_literal: true

module DeployingSimpleContract
  extend RSpec::SharedContext

  let(:address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
  let(:public_key) { "edpkugJHjEZLNyTuX3wW2dT4P7PY5crLqq3zeDFvXohAs3tnRAaZKR" }
  let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }

  let!(:contract) do
    contract = tezos_client.originate_contract(
      from: address,
      amount: 0,
      secret_key: secret_key,
      script: "./spec/fixtures/demo.py",
      init_params: "MyContract()",
      dry_run: false,
      gas_limit: 0.7
    )
    monitor_operation(contract[:operation_id])
    contract
  end
  let(:contract_address) { contract[:originated_contract] }
end

RSpec.configure do |config|
  config.include DeployingSimpleContract, :deploying_simple_contract
end
