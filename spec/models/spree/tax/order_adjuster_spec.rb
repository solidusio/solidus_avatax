require 'spec_helper'

describe Spree::Tax::OrderAdjuster do
  let!(:avatax_zone) { create(:zone, :with_country) }
  let!(:non_avatax_zone) { create(:zone, :with_country) }

  before do
    Spree::TaxRate.destroy_all

    create(:tax_rate, zone: avatax_zone, calculator: create(:avatax_tax_calculator))
    create(:tax_rate, zone: non_avatax_zone, calculator: create(:default_tax_calculator))
  end

  describe "#adjust!" do
    let(:item_adjuster_klass) { double(:item_adjuster_klass) }
    let(:item_adjuster) { double(:item_adjuster) }
    let(:order) { create(:order_ready_to_complete) }

    subject(:adjuster) { described_class.new(order) }

    before do
      stub_const("Spree::Tax::ItemAdjuster", item_adjuster_klass)
      allow(item_adjuster_klass).to receive(:new).and_return(item_adjuster)
      allow(item_adjuster).to receive(:adjust!)
    end

    context "with an order in an Avatax-calculated zone" do
      before do
        allow(order).to receive(:tax_zone).and_return(avatax_zone)
      end

      it "does not invoke the order-adjuster service" do
        expect(item_adjuster).to receive(:adjust!).never

        adjuster.adjust!
      end
    end

    context "with an order not in an Avatax-calculated zone" do
      before do
        allow(order).to receive(:tax_zone).and_return(non_avatax_zone)
      end

      it "invokes the order-adjuster service" do
        expect(item_adjuster).to receive(:adjust!).at_least(:once)

        adjuster.adjust!
      end
    end
  end
end
