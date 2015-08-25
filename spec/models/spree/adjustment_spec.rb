require 'spec_helper'

describe Spree::Adjustment do
  describe 'closed validation' do
    context 'with a tax adjustment' do
      let(:adjustment) { build(:adjustment, finalized: false, source: Spree::TaxRate.first) }

      it 'should trigger' do
        adjustment.valid?
        expect(adjustment.errors[:finalized]).to include("Tax adjustments must always be finalized for Avatax")
      end
    end

    context 'with a non-tax adjustment' do
      let(:adjustment) { build(:adjustment, finalized: false, source: nil) }

      it 'should not trigger' do
        adjustment.valid?
        expect(adjustment.errors[:finalized]).to be_empty
      end
    end
  end
end
