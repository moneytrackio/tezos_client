
RSpec.describe TezosClient::RpcInterface do
  describe '#forge_operation' do

    it 'returns a hash' do
      res = subject.forge_operation(
          from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          to: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          amount: 1)
      p res
      signature = TezosClient.new.sign(secret_key: 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN', data: res)
      p signature

      res = subject.run_operations(
          from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          to: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          amount: 1,
          signature: signature)
      pp res
    end
  end

  describe '#run_operations' do

    it 'returns a hash' do
      res = subject.run_operations(
          from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          to: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          amount: 1)
      p res
    end
  end


end
