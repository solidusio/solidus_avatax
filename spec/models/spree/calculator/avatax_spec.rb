require 'spec_helper'

describe Spree::Calculator::Avatax do
  let(:calculator) { Spree::Calculator::Avatax.new }

  describe '.description' do
    it 'should not be nil' do
      Spree::Calculator::Avatax.description.should_not be_nil
    end
  end

  describe '#compute_shipment' do
    it 'should raise NotImplementedError' do
      lambda {
        calculator.compute_shipment(double(Spree::ShippingRate))
      }.should raise_error(NotImplementedError)
    end
  end

  describe '#compute_shipping_rate' do
    context 'when shipping is zero' do
      it 'should be zero' do
        calculator.compute_shipping_rate(double(Spree::ShippingRate, cost: 0)).should == 0
      end
    end

    context 'when shipping is not zero' do
      it 'should raise NotImplementedError' do
        lambda {
          calculator.compute_shipping_rate(double(Spree::ShippingRate, cost: 10))
        }.should raise_error(NotImplementedError)
      end
    end
  end

  describe '#compute_line_item' do
    let(:line_item) { create :line_item }

    subject { calculator.compute_line_item(line_item) }

    context 'when no adjustments' do
      it 'should return 0' do
        subject.should == 0
      end
    end

    context 'when too many additional eligible tax adjustments' do
      before do
        setup_line_item_adjustments(line_item, 2)
      end

      it 'should raise error' do
        lambda {
          subject
        }.should raise_error(Spree::Calculator::Avatax::TooManyPossibleAdjustments)
      end
    end

    context 'when 1 additional eligible tax adjustment' do
      before do
        setup_line_item_adjustments(line_item, 1)
      end

      it 'should return 1' do
        subject.should == 1
      end
    end

    private

    def setup_line_item_adjustments(line_item, n)
      n.times do
        line_item.adjustments.eligible.tax.additional.create!({
          adjustable: line_item,
          amount: 1,
          order: line_item.order,
          label: 'Test Tax',
          included: false
        })
      end
    end

  end
end
