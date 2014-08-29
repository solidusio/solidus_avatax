require 'spec_helper'

describe Spree::OrderContents do
  let(:order) { create :order_with_line_items, line_items_count: 1 }
  let(:order_contents) { Spree::OrderContents.new(order) }

  describe 'add_with_avatax' do
    let(:variant) { create :variant }

    subject { order_contents.add_with_avatax(variant) }

    it 'recomputes tax' do
      expect(SpreeAvatax::SalesOrder).to receive(:generate).with(order)
      subject
    end
  end

  describe 'remove_with_avatax' do
    subject { order_contents.remove_with_avatax(order.line_items.first.variant) }

    it 'recomputes tax' do
      expect(SpreeAvatax::SalesOrder).to receive(:generate).with(order)
      subject
    end
  end

  describe 'update_cart_with_avatax' do
    subject { order_contents.update_cart_with_avatax({}) }

    it 'recomputes tax' do
      expect(SpreeAvatax::SalesOrder).to receive(:generate).with(order)
      subject
    end
  end
end
