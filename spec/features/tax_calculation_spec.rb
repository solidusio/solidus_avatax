require 'spec_helper'

describe "Tax Calculation" do
  let(:order) { create(:order_with_line_items, ship_address: address, line_items_count: 2) }
  let(:address) { create(:address, address1: "35 Crosby St", city: "New York", zipcode: 10013) }
  let(:line_item_1) { order.line_items.first }
  let(:line_item_2) { order.line_items.last }

  before do
    setup_configs
    order.line_items.first.product.tax_category.tax_rates << Spree::TaxRate.first
  end

  context "without discounts" do
    subject do
      VCR.use_cassette('sales_order_gettax_without_discounts') do
        SpreeAvatax::SalesOrder.generate(order)
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
      VCR.use_cassette('sales_order_gettax_with_discounts') do
        SpreeAvatax::SalesOrder.generate(order)
      end
    end

    let(:promotion) do
      promo = create(:promotion, code: "order_promotion")
      calculator = Spree::Calculator::FlatRate.new
      calculator.preferred_amount = 10
      Spree::Promotion::Actions::CreateAdjustment.create!(calculator: calculator, promotion: promo)
      promo
    end

    let(:line_item_promotion) do
      promo = create(:promotion_with_item_adjustment, code: 'line_item_promotion')
      promo.rules << Spree::Promotion::Rules::Product.create!(preferred_match_policy: 'any', product_ids_string: order.line_items.first.product.id.to_s)
      promo
    end

    before do
      order.line_items.each { |li| li.update_attributes!(price: 50.0) }
      PromotionSupport.set_order_promotion(order)
      PromotionSupport.set_line_item_promotion(order)
    end

    it "computes taxes for a line item" do
      expect do
        subject
      end.to change { order.line_items.first.reload.additional_tax_total }
    end
  end

end

def setup_configs
  @avalara_config = YAML.load_file("spec/avalara_config.yml")
  SpreeAvatax::Config.password = @avalara_config['password']
  SpreeAvatax::Config.username = @avalara_config['username']
  SpreeAvatax::Config.use_production_account = false
  SpreeAvatax::Config.company_code = 'Bonobos'
rescue => e
  skip("PLEASE PROVIDE AVALARA CONFIGURATIONS TO RUN LIVE TESTS [#{e.to_s}]")
end
