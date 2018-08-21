
RSpec.describe TezosClient do

  it 'has a version number' do
    expect(TezosClient::VERSION).not_to be nil
  end

  describe '#transfer' do
    it 'works' do
      sleep(1)
      subject.transfer(
        amount: 1,
        from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
        to: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
        secret_key: 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN'
      )
    end

    context 'with parameters' do
      it 'works' do
        sleep(1)
        subject.transfer(
          amount: 5,
          from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
          to: 'KT1MZTrMDPB42P9yvjf7Cy8Lkjxjj4jetbCt',
          secret_key: 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN',
          parameters: '"pro"'
        )
      end
    end
  end

  describe '#monitor_operation' do
    it 'works' do
      sleep(1)
      op_id = subject.transfer(
        amount: 1,
        from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
        to: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
        secret_key: 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN'
      )

      block_id = subject.monitor_operation(op_id)
      expect(block_id).to be_a String
    end
  end


  describe '#originate_contract' do

    let(:script) { File.expand_path('./spec/fixtures/demo.liq') }
    let(:source) { 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq' }
    let(:secret_key) { 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN' }
    let(:amount) { 0 }

    it 'works' do
      res = subject.originate_contract(
        from: source,
        amount: amount,
        script: script,
        secret_key: secret_key,
        init_params: '"test"'
      )

      expect(res).to be_a Hash
      expect(res).to have_key :operation_id
      expect(res).to have_key :originated_contract
      expect(res[:operation_id]).to be_a String
      expect(res[:originated_contract]).to be_a String
    end
  end
end
