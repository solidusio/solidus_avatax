require 'spec_helper'

describe Spree::ShippingRate do
  let!(:tax_rate) do
    rate = Spree::TaxRate.first
    rate.zone.countries << shipment.order.ship_address.country
    rate
  end

  let(:shipping_rate) do
    shipment.shipping_rates.create!({
      shipping_method: shipping_method,
      cost:            10.00,
      selected:        true
    })
  end

  let(:shipment) { create(:shipment) }
  let(:shipping_method) { create(:shipping_method, tax_category: tax_rate.tax_category) }

  before do
    Spree::Config.shipping_rate_taxer_class.new.tax(shipping_rate)
  end

  it 'calculates shipping rate taxes as 0' do
    expect(shipping_rate.taxes.first.amount).to eq 0
  end
end
