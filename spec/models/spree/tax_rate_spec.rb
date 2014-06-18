require 'spec_helper'

describe Spree::TaxRate do
  let!(:tax_rate) { create(:tax_rate) }

  describe '.match' do
    it { expect(Spree::TaxRate.match(:whatever)).to eq [tax_rate] }
  end

  describe '.avatax_the_one_rate' do
    it 'returns the tax rate' do
      expect(Spree::TaxRate.avatax_the_one_rate).to eq tax_rate
    end
  end

  describe 'tax rate count limitation' do
    let(:tax_rate_2) { build(:tax_rate) }

    it 'limits to a single rate' do
      expect(tax_rate_2).to be_invalid
      expect(tax_rate_2.errors.full_messages).to eq ['only one tax rate is allowed and this would make 2']
    end
  end

  describe '#adjust' do
    it 'raises TaxRateInvalidOperation' do
      lambda {
        tax_rate.adjust(nil, nil)
      }.should raise_error(SpreeAvatax::TaxRateInvalidOperation)
    end
  end

  describe '#compute_amount' do
    it 'raises TaxRateInvalidOperation' do
      lambda {
        tax_rate.compute_amount(nil)
      }.should raise_error(SpreeAvatax::TaxRateInvalidOperation)
    end
  end
end
