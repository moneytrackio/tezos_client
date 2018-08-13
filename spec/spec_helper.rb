require 'bundler/setup'
require 'tezos_client'
require 'securerandom'

Dir['./spec/shared/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  ENV['TEZOS_CLIENT_CONFIG_FILE'] = 'spec/fixtures/client_config'
  ENV['TEZOS_ORIGIN_PKEY'] = 'unencrypted:edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN'

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
