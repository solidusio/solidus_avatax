require 'spec_helper'

describe Spree::Order do
  let(:order) do
     FactoryGirl.create(:order, ship_address: FactoryGirl.create(:ship_address))
  end

  describe 'commit_avatax_invoice' do
    subject { order.commit_avatax_invoice }

    before do
      Avalara.should_receive(:get_tax).once
    end

    it 'should call Avatax.get_tax' do
      subject
    end

    it 'should set avatax_response_at' do
      subject
      order.avatax_response_at.should_not be_nil
    end
  end

  describe 'promotion_adjustment_total' do
    context 'when no adjustments' do 
      it 'should return 0' do
        order.promotion_adjustment_total.should == 0
      end
    end

    context 'when there are eligible adjustments' do
      before do
        order.adjustments << Spree::Adjustment.create!(originator_type: "Spree::PromotionAction", amount: -5.0, order: order, label: 'Promo One')
        order.adjustments << Spree::Adjustment.create!(originator_type: "Spree::PromotionAction", amount: -10.99, order: order, label: 'Promo Two')
      end

      it 'should have a promotion_adjustment_total of 10.99' do
        order.promotion_adjustment_total.should == 10.99
      end
    end
  end
end
