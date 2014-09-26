require 'spec_helper'

describe Spree::ShippingRate do
  subject do
    shipping_rate.calculate_tax_amount
  end

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

  it 'foo' do
    expect(subject).to eq 0
  end
end
