require 'spec_helper'

describe Spree::Address do
  let(:address) { create(:address) }
  before        { Spree::Order.destroy_all }

  describe "#after_save" do
    it "recomputes tax for incomplete orders with the address" do
      order = create(:order_with_line_items, ship_address: address, line_items_count: 1)
      expect(SpreeAvatax::SalesOrder).to receive(:generate).with(order)
      address.save
    end

    it "does not recompute tax for completed orders for the address" do
      create(:completed_order_with_totals, ship_address: address)
      expect(SpreeAvatax::SalesOrder).not_to receive(:generate)
      address.save
    end

    it "does not recompute tax for incomplete orders with other addresses" do
      create(:order_with_line_items, line_items_count: 1)
      expect(SpreeAvatax::SalesOrder).not_to receive(:generate)
      address.save
    end
  end
end
