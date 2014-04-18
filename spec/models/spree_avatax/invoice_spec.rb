require 'spec_helper'

describe SpreeAvatax::Invoice do

  # TODO, turns this calculator into a NOOP
  let(:calculator) { Spree::Calculator::DefaultTax.new }
  let(:doc_type) { "SalesOrder" }
  let(:params) { {doc_type: doc_type} }
  let(:order) { create(:order_with_line_items) }
  let(:tax_rate) { create(:tax_rate, calculator: calculator, zone: ZoneSupport.global_zone) }
  let(:invoice_instance) { SpreeAvatax::Invoice.new(order, doc_type, Logger.new("/dev/null")) }

  describe "#new" do
    before do
      SpreeAvatax::Config.company_code = "foo"
      order.line_items.first.product.tax_category.tax_rates << tax_rate
    end

    context "invoice object" do
      subject            { invoice_instance.invoice }
      it                 { should be_a Avalara::Request::Invoice }
      its(:CustomerCode) { should eq order.email }
      its(:DocDate)      { should eq Date.today.iso8601 }
      its(:DocType)      { should eq doc_type }
      its(:CompanyCode)  { should eq "foo" }
      its(:Discount)     { should eq order.promotion_adjustment_total }
      its(:DocCode)      { should eq order.number }
    end

    it { invoice_instance.invoice.Addresses.size.should eq 1 }

    context "invoice address" do
      subject           { invoice_instance.invoice.Addresses.first }
      it                { should be_a Avalara::Request::Address }
      its(:AddressCode) { should eq SpreeAvatax::Invoice::ADDRESS_CODE }
      its(:Line1)       { should eq order.ship_address.address1 }
      its(:Line2)       { should eq order.ship_address.address2 }
      its(:Line2)       { should eq order.ship_address.address2 }
      its(:City)        { should eq order.ship_address.city }
      its(:PostalCode)  { should eq order.ship_address.zipcode }
    end

    it { invoice_instance.invoice.Lines.size.should eq order.line_items.size }

    context "invoice lines" do
      let(:line_item) { order.line_items.first }
      context "without a discount" do
        subject               { invoice_instance.invoice.Lines.first }
        it                    { should be_a Avalara::Request::Line }
        its(:LineNo)          { should eq line_item.id  }
        its(:DestinationCode) { should eq SpreeAvatax::Invoice::DESTINATION_CODE}
        its(:OriginCode)      { should eq SpreeAvatax::Invoice::ORIGIN_CODE }
        its(:Qty)             { should eq 1 }
        its(:ItemCode)        { should eq line_item.variant.sku }
        its(:Amount)          { should eq line_item.price }
        its(:Discounted)      { should be_false }
      end

      context "with a line item discount" do
        before do
          line_item.update_attribute(:price, 50.0)
          PromotionSupport.set_line_item_promotion(order)
        end

        subject               { invoice_instance.invoice.Lines.first }
        its(:Amount)          { should eq 40.0 }
        its(:Discounted)      { should be_false }
      end

      context "with an order discount" do
        before { PromotionSupport.set_order_promotion(order) }

        subject               { invoice_instance.invoice.Lines.first }
        its(:Discounted)      { should be_true }
      end
    end
  end

end
