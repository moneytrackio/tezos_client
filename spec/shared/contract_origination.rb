# frozen_string_literal: true

RSpec.shared_context "contract origination", shared_context: :metadata do
  include_context "public rpc interface"

  FROM ||= "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq"
  SECRET_KEY ||= "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"

  def originate_demo_contract
    res = tezos_client.originate_contract(
      from: FROM,
      amount: 0,
      script: File.expand_path("./spec/fixtures/demo.liq"),
      secret_key: SECRET_KEY,
      init_params: '"test"'
    )
    disabling_vcr { tezos_client.monitor_operation(res[:operation_id], timeout: 120) }
    res[:originated_contract]
  end

  def originate_multisig_contract
    res = tezos_client.originate_contract(
      from: FROM,
      amount: 0,
      script: File.expand_path("./spec/fixtures/multisig.liq"),
      secret_key: SECRET_KEY,
      init_params: ["Set [#{FROM}]", "1p"]
    )
    disabling_vcr { tezos_client.monitor_operation(res[:operation_id], timeout: 120) }
    res[:originated_contract]
  end
end
