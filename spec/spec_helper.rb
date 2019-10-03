# frozen_string_literal: true

require "bundler/setup"
require "tezos_client"
require "securerandom"
require "pry"

require_relative "../lib/tezos_client/string_utils"

Dir["./spec/support/**/*.rb"].each { |f| require f }
Dir["./spec/shared/**/*.rb"].each { |f| require f }


#
# tzalpha client --addr alphanet-node.tzscan.io -P 80 reveal key for tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq
# tzalpha client --addr alphanet-node.tzscan.io -P 80 reveal key for pierre
#

RSpec.configure do |config|
  ENV["TEZOS_CLIENT_CONFIG_FILE"] = "spec/fixtures/client_config"
  ENV["TEZOS_ORIGIN_PKEY"] = "unencrypted:edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
  ENV["TEZOSCLIENT_LOG"] = "stdout"

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
