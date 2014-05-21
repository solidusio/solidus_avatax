require 'spec_helper'

describe Spree::Address do
  let(:address) { create(:address) }
  before        { Spree::Order.destroy_all }

  describe "#after_save" do
    it "recomputes tax for all non-completed orders for the address" do
      create(:order_with_line_items, ship_address: address)
      expect_any_instance_of(Spree::Order).to receive(:avatax_compute_tax)
      address.save
    end

    it "does not recompute tax for completed orders for the address" do
      create(:completed_order_with_totals, ship_address: address)
      expect_any_instance_of(Spree::Order).not_to receive(:avatax_compute_tax)
      address.save
    end

    it "does not recompute tax for incomplete orders for other addresses" do
      create(:completed_order_with_totals)
      expect_any_instance_of(Spree::Order).not_to receive(:avatax_compute_tax)
      address.save
    end
  end
end
