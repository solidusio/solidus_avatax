require 'spec_helper'

describe Spree::ShippingRate do
  let(:shipping_rate) do
    shipment.shipping_rates.create!({
      tax_rate:        Spree::TaxRate.first,
      shipping_method: shipping_method,
      cost:            10.00,
      selected:        true,
    })
  end

  let(:shipment) { create(:shipment) }
  let(:shipping_method) { create(:shipping_method) }

  it 'calculates shipping rate taxes as 0' do
    expect(shipping_rate.calculate_tax_amount).to eq 0
  end
end
