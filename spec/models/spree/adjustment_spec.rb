require 'spec_helper'

describe Spree::Adjustment do
  describe 'closed validation' do
    context 'with a tax adjustment' do
      let(:adjustment) { build(:adjustment, finalized: false, source: Spree::TaxRate.first) }

      it 'should trigger' do
        adjustment.valid?
        expect(adjustment.errors[:finalized]).to include("Tax adjustments must always be finalized for Avatax")
      end

      context "without a source" do
        let(:adjustment) { build(:adjustment, finalized: false, source: nil) }

        it "is valid" do
          expect(adjustment).to be_valid
        end
      end
    end

    context "with a tax adjustment not calculated by Avatax" do
      let(:non_avatax_tax_rate) { create(:tax_rate, calculator: create(:default_tax_calculator)) }

      let(:adjustment) { build(:adjustment, finalized: false, source: non_avatax_tax_rate) }

      it "is valid" do
        expect(adjustment).to be_valid
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
