
RSpec.describe TezosClient::LiquidityInterface do
  let(:script) { File.expand_path('./spec/fixtures/demo.liq') }
  let(:from) { 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq' }

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
end
