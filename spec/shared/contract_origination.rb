# frozen_string_literal: true

RSpec.shared_context "contract origination", shared_context: :metadata do
  include_context "public rpc interface"

  FROM ||= "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq"
  SECRET_KEY ||= "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"

  def originate_demo_contract
    res = tezos_client.originate_contract(
      from: FROM,
      amount: 0,
      script: File.expand_path("./spec/fixtures/demo.py"),
      secret_key: SECRET_KEY,
      init_params: [{}, {}]
    )
    monitor_operation(res[:operation_id])
    res[:originated_contract]
  end
end
