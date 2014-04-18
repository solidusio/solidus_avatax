require 'spec_helper'

describe Spree::OrderContents do
  let(:order) { create :order_with_line_items }
  let(:order_contents) { Spree::OrderContents.new(order) }

  describe 'add_with_avatax' do
    let(:variant) { create :variant }

    subject { order_contents.add_with_avatax(variant) }

    it 'should call avatax_compute_tax' do
      order_contents.should_receive(:avatax_compute_tax).once
      subject
    end
  end

  describe 'remove_with_avatax' do
    subject { order_contents.remove_with_avatax(order.line_items.first.variant) }

    it 'should call avatax_compute_tax' do
      order_contents.should_receive(:avatax_compute_tax).once
      subject
    end
  end

  describe 'update_cart_with_avatax' do
    subject { order_contents.update_cart_with_avatax({}) }

    it 'should call avatax_compute_tax' do
      order_contents.should_receive(:avatax_compute_tax).once
      subject
    end
  end

  describe '#avatax_compute_tax' do
    subject { order_contents.avatax_compute_tax }

    it 'should call compute on SpreeAvatax::TaxCalculator' do
      SpreeAvatax::TaxComputer.should_receive(:new).with do |o|
        o.id.should == order.id
      end.and_call_original
      SpreeAvatax::TaxComputer.any_instance.should_receive(:compute).once
      subject
    end
  end
end
