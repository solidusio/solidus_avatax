require 'spec_helper'

describe Spree::TaxRate do
  let(:tax_rate) { Spree::TaxRate.first }

  describe '.match' do
    it { expect(Spree::TaxRate.match(:whatever)).to eq [tax_rate] }
  end

  describe '.avatax_the_one_rate' do
    it 'returns the tax rate' do
      expect(Spree::TaxRate.avatax_the_one_rate).to eq tax_rate
    end
  end

  describe 'tax-rate count limitation' do
    let(:tax_rate_2) { build(:tax_rate, calculator: calculator) }

    context "when attempting to create a second Avalara-calculated rate" do
      let(:calculator) { create(:avatax_tax_calculator) }

      it 'limits to a single rate' do
        expect(tax_rate_2).to be_invalid
        expect(tax_rate_2.errors.full_messages).to eq ['only one tax rate is allowed and this would make 2']
      end
    end

    context "when attempting to create a second rate not calculated by Avalara" do
      let(:calculator) { create(:default_tax_calculator) }

      it "doesn't invalidate the tax-rate" do
        expect(tax_rate_2).to be_valid
        expect(tax_rate_2.errors.full_messages).to be_empty
      end
    end
  end

  describe '#adjust' do
    context "when the only tax-rate is calculated by Avatax" do
      subject(:adjust!) { tax_rate.adjust(nil, nil) }

      it 'raises TaxRateInvalidOperation' do
        expect { adjust! }.to raise_error(SpreeAvatax::TaxRateInvalidOperation)
      end
    end

    context "with another tax-rate not calculated by Avalara" do
      let(:order) { create(:order_with_line_items) }
      let(:line_item) { order.line_items.first }

      let(:tax_rate_2) { create(:tax_rate, calculator: create(:default_tax_calculator)) }

      subject(:adjust!) { tax_rate_2.adjust(order.tax_zone, line_item) }

      it "doesn't raise an error" do
        expect { adjust! }.to_not raise_error
      end
    end
  end
end
