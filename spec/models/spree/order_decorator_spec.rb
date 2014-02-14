require 'spec_helper'

describe Spree::Order do
  let(:invoice_tax) { double(Avalara::Response, total_tax: 5.00) }

  let(:order) do
     FactoryGirl.create(:order_with_line_items, ship_address: FactoryGirl.create(:ship_address))
  end

  describe 'doc_type' do
    it 'should return SalesInvoice' do
      order.doc_type.should == 'SalesInvoice'
    end
  end

  describe 'status_field' do
    it 'should return :avatax_invoice_at' do
      order.status_field.should == :avatax_invoice_at 
    end
  end

  describe 'build_line_items' do
    before do
      order.line_items.last.stub(:avataxable?).and_return(true)
    end

    subject { order.build_line_items(order) }

    it 'should return only the last line item' do
      subject.first.should == order.line_items.last
    end

    it 'should return 1 item' do
      subject.size.should == 1
    end
  end

  describe 'commit_avatax_invoice' do
    subject { order.commit_avatax_invoice }

    it 'should call SpreeAvatax::AvataxCalculator.compute_order' do
      SpreeAvatax::AvataxComputer.any_instance.should_receive(:compute_order_with_context).once.with(order, order)
      subject
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
        order.adjustments << Spree::Adjustment.create!(originator_type: "Spree::PromotionAction", eligible: false, amount: -5.0, order: order, label: 'Promo One')
        order.adjustments << Spree::Adjustment.create!(originator_type: "Spree::PromotionAction", eligible: true, amount: -10.99, order: order, label: 'Promo Two')
      end

      it 'should have a promotion_adjustment_total of 10.99' do
        order.promotion_adjustment_total.should == 10.99
      end
    end
  end
end
