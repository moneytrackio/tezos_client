RSpec.shared_context 'shared wallet', shared_context: :metadata do

  let(:rich_wallet) { 'rich_wallet' }
  let(:test_wallet) { 'test_wallet' }

  before(:all) do
    import_wallet
  end

  def import_wallet
    rich_wallet_secret_key = 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN'
    test_wallet_secret_key = 'edsk2h7Dx1cDsXuqa4aeYcDSUr47ySyYbq3DC3qVoSh9wx9NFSosLe'

    client = TezosClient.new

    client.import_secret_key('rich_wallet',
                             "unencrypted:#{rich_wallet_secret_key}",
                             force: true)

    client.import_secret_key('test_wallet',
                             "unencrypted:#{test_wallet_secret_key}",
                             force: true)
  end

end
