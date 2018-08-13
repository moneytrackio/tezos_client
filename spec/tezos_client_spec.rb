
RSpec.describe TezosClient do
  it "has a version number" do
    expect(TezosClient::VERSION).not_to be nil
  end

  describe '#transfer' do

    it 'works' do
      subject.transfer(amount: 1,
                       from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
                       to: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
                       secret_key: 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN')
    end

    context 'with parameters' do

      it 'works' do
        subject.transfer(amount: 0,
                         from: 'tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq',
                         to: 'KT1DYhtwokM5SX1V8UfqnDe2cMBXA4mS5MFr',
                         secret_key: 'edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN',
                         parameters: '"pierre"')
      end
    end
  end


  describe '#sexp2mic' do

    it 'works with a string' do
      res = subject.sexp2mic('"test"')
      expect(res).to eq('string' => 'test')
    end

    it 'works with a Pair' do
      res = subject.sexp2mic('Pair 82 37')
      expect(res).to eq(prim: 'Pair', args: [{'int' => '82'}, {'int' => '37' }])
    end

    it 'works with recursive pair' do
      res = subject.sexp2mic('Pair (Pair 0 (Pair 0 255))')
      expect(res).to eq(
        prim: 'Pair',
        args: [
          { 'int' => '0' },
          {
            'prim' => 'Pair',
            args: [{ 'int' => '0' }, { 'int' => '255' }]
          }
        ]
      )
    end

    it 'works with 3 pairs' do
      p subject.sexp2mic('Pair 3 (Pair 0 (Pair 0 255))')
    end

    it 'works with a pair of pairs' do
      p subject.sexp2mic('Pair (Pair 82 37) (Pair 0 255)')
    end

    context 'unfinished string' do
      it 'raises an exception' do
        expect{subject.sexp2mic('"test')}.to raise_error(ArgumentError, /test/)
      end
    end
  end

end
