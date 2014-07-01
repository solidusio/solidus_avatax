require 'spec_helper'

describe "Tax Calculation" do
  let(:address) { create(:address, address1: "35 Crosby St", city: "New York", zipcode: 10013) }
  let(:tax_rate) { create(:tax_rate, calculator: SpreeAvatax::Calculator.new, zone: ZoneSupport.global_zone) }
  let(:order) { create(:order_with_line_items, ship_address: address) }

  before do
    setup_configs
    order.line_items.first.product.tax_category.tax_rates << tax_rate
  end

  context "without discounts" do
    it "computes taxes for a line item" do
      Avalara.should_receive(:get_tax).with do |invoice|
        expect(invoice.DocType).to eq 'SalesOrder'
        expect(invoice.CustomerCode).to eq order.email
        expect(invoice.CompanyCode).to eq "Bonobos"
        expect(invoice.Discount).to eq BigDecimal("0.00")
        expect(invoice.DocCode).to eq order.number
        line = invoice.Lines.first
        line_item = order.line_items.first
        expect(line.LineNo).to eq line_item.id
        expect(line.Qty).to eq 1
        expect(line.Amount).to eq line_item.price
        expect(line.ItemCode).to eq line_item.variant.sku
        expect(line.Discounted).to eq false
      end.and_call_original

      expect do
        VCR.use_cassette('tax_call_without_discounts') do
          SpreeAvatax::TaxComputer.new(order).compute
        end
      end.to change { order.line_items.first.additional_tax_total }
    end
  end

  context "with discounts" do
    let(:order_promotion) do
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
      order.line_items.each { |li| li.update_attribute(:price, 50.0) }
      PromotionSupport.set_order_promotion(order)
      PromotionSupport.set_line_item_promotion(order)
    end

    it "computes taxes for a line item" do
      Avalara.should_receive(:get_tax).with do |invoice|
        expect(invoice.DocType).to eq 'SalesOrder'
        expect(invoice.CustomerCode).to eq order.email
        expect(invoice.CompanyCode).to eq "Bonobos"
        expect(invoice.Discount).to eq 10
        expect(invoice.DocCode).to eq order.number
        line = invoice.Lines.first
        line_item = order.line_items.first
        expect(line.LineNo).to eq line_item.id
        expect(line.Qty).to eq 1
        expect(line.Amount).to eq 40.0
        expect(line.ItemCode).to eq line_item.variant.sku
        expect(line.Discounted).to eq true
      end.and_call_original

      expect do
        VCR.use_cassette('tax_call_with_discounts') do
          SpreeAvatax::TaxComputer.new(order).compute
        end
      end.to change { order.line_items.first.reload.additional_tax_total }
    end
  end

end

def setup_configs
  @avalara_config = YAML.load_file("spec/avalara_config.yml")
  SpreeAvatax::Config.password = @avalara_config['password']
  SpreeAvatax::Config.username = @avalara_config['username']
  SpreeAvatax::Config.endpoint = 'https://development.avalara.net/'
  SpreeAvatax::Config.company_code = 'Bonobos'
rescue => e
  pending("PLEASE PROVIDE AVALARA CONFIGURATIONS TO RUN LIVE TESTS [#{e.to_s}]")
end
