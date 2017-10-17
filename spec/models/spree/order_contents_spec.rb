require 'spec_helper'

describe Spree::OrderContents do
  let(:order) { create :order_with_line_items, line_items_count: 1 }
  let(:order_contents) { Spree::OrderContents.new(order) }

  describe 'add' do
    let(:variant) { create :variant }

    subject { order_contents.add(variant) }

    it 'clears tax' do
      expect(SpreeAvatax::SalesShared).to receive(:reset_tax_attributes).with(order)
      subject
    end
  end

  describe 'remove' do
    subject { order_contents.remove(order.line_items.first.variant) }

    it 'recomputes tax' do
      expect(SpreeAvatax::SalesShared).to receive(:reset_tax_attributes).with(order)
      subject
    end
  end

  describe 'update_cart' do
    subject { order_contents.update_cart({}) }

    it 'recomputes tax' do
      expect(SpreeAvatax::SalesShared).to receive(:reset_tax_attributes).with(order)
      subject
    end
  end
end
