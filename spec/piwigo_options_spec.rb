require 'rspec'

require_relative '../lib/piwigo_options'

describe PiwigoOptions do
  describe '#to_h' do
    subject { uut.to_h }

    let(:uut) do
      described_class.new.tap do |uut|
        uut.authorization = 'authorization'
      end
    end

    it { is_expected.to be_a(Hash) }

    it 'has the correct attributes' do
      expect(subject[:authorization]).to eq('authorization')
    end
  end

  describe '#from_h' do
    subject { uut.from_h(args) }

    let(:uut) { described_class.new }
    let(:args) { { authorization: 'authorization' } }

    it 'overwrites the input fields' do
      subject
      expect(uut.authorization).to eq('authorization')
    end
  end
end
