require 'spec_helper'

describe SpreeAvatax::SalesShared do

  describe '.reset_tax_attributes' do
    subject do
      SpreeAvatax::SalesShared.reset_tax_attributes(order)
    end

    let(:order) { create(:order_with_line_items, additional_tax_total: 1, adjustment_total: 1, included_tax_total: 1, line_items_count: 1) }
    let(:line_item) { order.line_items.first }

    before do
      line_item.adjustments.eligible.tax.additional.create!({
        adjustable: line_item,
        amount: 1.23,
        order: order,
        label: 'Previous Tax',
        included: false,
      })

      line_item.update_attributes!({
        additional_tax_total: 1,
        adjustment_total: 1,
        pre_tax_amount: 1,
        included_tax_total: 1,
      })
    end

    context 'when order is completed' do
      before do
        order.update_attributes!(completed_at: Time.now)
      end

      it 'should leave adjustments in place' do
        subject
        expect(line_item.adjustments.tax.count).to eq 1
      end
    end

    it 'should remove all eligible tax adjustments' do
      subject
      expect(line_item.adjustments.tax.count).to eq 0
    end
  end
end
