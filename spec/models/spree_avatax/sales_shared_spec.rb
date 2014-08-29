require 'spec_helper'

describe SpreeAvatax::SalesShared do

  describe '.reset_tax_attributes' do
    subject do
      SpreeAvatax::SalesShared.send(:reset_tax_attributes, order)
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

    it 'should remove all eligible tax adjustments' do
      subject
      expect(line_item.adjustments.tax.count).to eq 0
    end

    it 'should remove tax adjustments even if they are not reachable through a line item anymore' do
      disassociated_adjustment = order.adjustments.eligible.tax.additional.create!({
        adjustable_type: 'Spree::LineItem',
        adjustable_id: 99999,
        amount: 6.66,
        order: order,
        label: 'Test',
        included: false
      })
      subject
      # make sure this got deleted
      expect { disassociated_adjustment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    [:additional_tax_total, :adjustment_total, :included_tax_total].each do |f|
      it "sets order #{f} to zero" do
        subject
        expect(order.send(f)).to eq 0
      end
    end

    [:additional_tax_total, :adjustment_total, :pre_tax_amount, :included_tax_total].each do |f|
      it "sets line_item #{f} to zero" do
        subject
        expect(order.line_items.sum(f)).to eq 0
      end
    end
  end

end
