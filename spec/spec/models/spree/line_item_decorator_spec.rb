require 'spec_helper'

describe Spree::LineItem do
  describe 'avataxable?' do
    let(:address) {  FactoryGirl.create(:address) }

    let(:tax_rate) do
      tax_rate = FactoryGirl.create(:tax_rate, calculator: Spree::Calculator::Avatax.new, zone: zone)
    end

    let(:line_item) do
      line_item = FactoryGirl.create(:line_item)
      line_item.product.tax_category.tax_rates << tax_rate
      line_item.order.ship_address = address
      line_item.order.bill_address = address
      line_item
    end
    
    subject { line_item.avataxable? }

    context 'when the tax rate zone includes the address' do
      let(:zone) { FactoryGirl.create(:global_zone) }

      it 'should return true' do
        subject.should be_true
      end
    end

    context 'when the tax rate zone does not include the address' do
      let(:zone) { FactoryGirl.create(:zone) }

      it 'should return false' do
        subject.should be_false
      end
    end

    context 'when there are no addresses' do
      let(:zone)    { FactoryGirl.create(:global_zone) }
      let(:address) { nil }
      it 'should return false' do
        subject.should be_false
      end
    end
  end
end
