require 'spec_helper'

describe Spree::Address do
  let(:address) { create(:address) }
  before        { Spree::Order.destroy_all }

  describe "#after_save" do
    it "clears tax for incomplete orders with the address" do
      order = create(:order_with_line_items, ship_address: address, line_items_count: 1)
      expect(SpreeAvatax::SalesShared).to receive(:reset_tax_attributes).with(order)
      address.save
    end

    it "does not clear tax for completed orders for the address" do
      create(:completed_order_with_totals, ship_address: address)
      expect(SpreeAvatax::SalesShared).not_to receive(:reset_tax_attributes)
      address.save
    end

    it "does not recompute tax for incomplete orders with other addresses" do
      create(:order_with_line_items, line_items_count: 1)
      expect(SpreeAvatax::SalesShared).not_to receive(:reset_tax_attributes)
      address.save
    end
  end
end
