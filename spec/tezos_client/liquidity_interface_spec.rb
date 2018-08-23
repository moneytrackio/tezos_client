
RSpec.describe TezosClient::LiquidityInterface do
  let(:script) { File.expand_path('./spec/fixtures/demo.liq') }
  let(:from) { 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq' }
  let(:contract_address) { 'KT1MZTrMDPB42P9yvjf7Cy8Lkjxjj4jetbCt' }

  describe '#forge_deploy' do

    it 'works' do
      res = subject.forge_deploy(
        from: from,
        script: script,
        init_params: '"pierre"'
      )
      p res
    end
  end

  describe '#initial_storage' do
    it 'works' do
      res = subject.initial_storage(
        from: from,
        script: script,
        init_params: '"pierre"'
      )
      expect(res).to be_an Array
    end
  end

  describe '#json_script' do
    it 'works' do
      json_init_script, json_contract_script = subject.json_scripts(
        script: script
      )
      expect(json_init_script).to be_an Array
      expect(json_contract_script).to be_an Array
    end
  end

  describe '#origination_script' do
    it 'works' do
      res = subject.origination_script(
        from: from,
        script: script,
        init_params: '"pierre"'
      )
      expect(res).to be_a Hash
      p res
    end
  end

  describe '#get_storage' do
    it 'retrieves the current storage' do
      res = subject.get_storage(
        script: script,
        contract_address: contract_address
      )
      expect(res).to be_a String
      p res
    end

    context 'multisig.liq contract' do
      let(:script) { File.expand_path('./spec/fixtures/multisig.liq') }
      let(:contract_address) { 'KT19tZPx3so7n2bQLfzDTUGTLYNhgVxBMGe1' }
      let(:init_params) { ["Set [#{from}]", '1p'] }
      let(:call_parameters) { 'Pay' }

      it 'gets the initial storage' do
        res = subject.initial_storage(
          from: from,
          script: script,
          init_params: init_params
        )
        p res
        expect(res).to be_a Hash
      end

      it 'gets the current storage' do
        res = subject.get_storage(
          script: script,
          contract_address: contract_address
        )
        expect(res).to be_a String
        p res
      end

      it 'gets the current params' do
        storage = subject.get_storage(
          script: script,
          contract_address: contract_address
        )

        res = subject.call_parameters(
          script: script,
          parameters: call_parameters,
          storage: storage
        )
        p res
      end

    end
  end
end
