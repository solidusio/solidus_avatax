require 'spec_helper'

describe "Tax Calculation" do
  let(:order) { create(:order_with_line_items, ship_address: address, line_items_count: 2) }
  let(:address) { create(:address, address1: "35 Crosby St", city: "New York", zipcode: 10013) }
  let(:line_item_1) { order.line_items.first }
  let(:line_item_2) { order.line_items.last }
  let(:shipment) { order.shipments.first }

  before do
    # Set up Avatax (just in case we don't have a cassette)
    SpreeAvatax::Config.password = ENV["AVATAX_PASSWORD"]
    SpreeAvatax::Config.username = ENV["AVATAX_USERNAME"]
    SpreeAvatax::Config.service_url = "https://development.avalara.net"
    SpreeAvatax::Config.company_code = ENV["AVATAX_COMPANY_CODE"]

    order.line_items.first.product.tax_category.tax_rates << Spree::TaxRate.first

    expect(SpreeAvatax::SalesInvoice).to(
      receive(:avatax_id).
        with(line_item_1).
        at_least(:once).
        and_return('Spree::LineItem-1')
    )
    expect(SpreeAvatax::SalesInvoice).to(
      receive(:avatax_id).
        with(line_item_2).
        at_least(:once).
        and_return('Spree::LineItem-2')
    )
    expect(SpreeAvatax::SalesInvoice).to(
      receive(:avatax_id).
        with(shipment).
        at_least(:once).
        and_return('Spree::Shipment-1')
    )
  end

  context "without discounts" do
    subject do
      VCR.use_cassette('sales_invoice_gettax_without_discounts') do
        SpreeAvatax::SalesInvoice.generate(order)
      end
    end

    it "computes taxes for a line item" do
      expect {
        subject
      }.to change { order.line_items.first.additional_tax_total }
    end
  end

  context "with discounts" do
    subject do
      VCR.use_cassette('sales_invoice_gettax_with_discounts') do
        SpreeAvatax::SalesInvoice.generate(order)
      end
    end

    let(:promotion) do
      FactoryGirl.create(
        :promotion,
        code: "order_promotion",
        promotion_actions: [
          Spree::Promotion::Actions::CreateAdjustment.new(
            calculator: Spree::Calculator::FlatRate.new(preferred_amount: 10),
          ),
        ],
      )
    end

    let(:line_item_promotion) do
      FactoryGirl.create(
        :promotion_with_item_total_rule,
        code: 'line_item_promotion'
      )
    end

    before do
      order.line_items.each { |li| li.update_attributes!(price: 50.0) }

      order.coupon_code = promotion.codes.first.value
      Spree::PromotionHandler::Coupon.new(order).apply

      order.coupon_code = line_item_promotion.codes.first.value
      Spree::PromotionHandler::Coupon.new(order).apply
    end

    it "computes taxes for a line item" do
      expect do
        subject
      end.to change { order.line_items.first.reload.additional_tax_total }
    end
  end
end
