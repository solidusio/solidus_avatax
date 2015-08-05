require 'spec_helper'

describe Spree::Adjustment do
  describe 'closed validation' do
    context 'with a tax adjustment' do
      let(:adjustment) { build(:adjustment, state: 'open', source: Spree::TaxRate.first) }

      it 'should trigger' do
        adjustment.valid?
        expect(adjustment.errors[:state]).to include("Tax adjustments must always be closed for Avatax")
      end
    end

    context 'with a non-tax adjustment' do
      let(:adjustment) { build(:adjustment, state: 'open', source: nil) }

      it 'should not trigger' do
        adjustment.valid?
        expect(adjustment.errors[:state]).to be_empty
      end
    end
  end
end
