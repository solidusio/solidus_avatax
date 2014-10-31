require 'spec_helper'

describe Spree::Order do
  subject { order }

  let!(:order) { create(:order_with_line_items, line_items_count: 1) }

  context 'after_save' do
    context 'when something unimportant changes' do
      context 'when in confirm state' do
        before { order.update_columns(state: 'confirm') }

        it 'does not change the order state' do
          expect {
            order.update_attributes!(special_instructions: 'unimportant change')
          }.to_not change { order.state }
        end
      end
    end

    context 'when the ship address changes' do
      def change_address
        order.update_attributes!(ship_address: create(:address))
      end

      context 'when in confirm state' do
        before { order.update_columns(state: 'confirm') }

        it 'sets the order state to payment' do
          expect {
            change_address
          }.to change { order.state }.from('confirm').to('payment')
        end
      end

      context 'when not in confirm state' do
        before { order.update_columns(state: 'address') }

        it 'does not update avatax' do
          expect {
            change_address
          }.to_not change { order.state }
        end
      end
    end
  end

  context "when transitioning from address" do
    before do
      subject.update_attributes!(state: 'address')
    end

    it "generates a sales invoice" do
      expect(SpreeAvatax::SalesOrder).to receive(:generate).with(subject)
      subject.next!
    end
  end

  context "when transitioning to confirm" do
    before do
      subject.update_attributes!(state: 'payment')
      subject.payments.create!(state: 'checkout')
      subject.stub(confirmation_required?: true)
    end

    it "generates the sales invoice" do
      expect(SpreeAvatax::SalesInvoice).to receive(:generate).with(subject)
      subject.next!
    end
  end

  context "when transitioning to complete" do
    before do
      subject.update_attributes!(state: 'confirm')
      subject.payments.create!(state: 'checkout')
    end

    it "commits the sales invoice" do
      expect(SpreeAvatax::SalesInvoice).to receive(:commit).with(subject)
      subject.next!
    end
  end

  describe '#avatax_order_adjustment_total' do
    context 'no adjustments exist' do
      it 'returns 0' do
        expect(subject.avatax_order_adjustment_total).to eq 0
      end
    end

    context 'eligible non-tax adjustments exist' do
      let!(:non_eligible_promo_adjustment) do
        subject.adjustments.create!(source_type: 'Spree::PromotionAction', eligible: false, amount: -1.0, label: 'bad promo')
      end
      let!(:eligible_promo_adjustment) do
        subject.adjustments.create!(source_type: 'Spree::PromotionAction', eligible: true, amount: -10.0, label: 'good promo')
      end
      let!(:eligible_non_promo_adjustment) do
        subject.adjustments.create!(source_type: nil, eligible: true, amount: -100.0, label: 'non-promo')
      end
      let!(:eligible_positive_adjustment) do
        subject.adjustments.create!(source_type: nil, eligible: true, amount: 1000.0, label: 'positive non-promo')
      end
      let(:eligible_total) do
        eligible_promo_adjustment.amount + eligible_non_promo_adjustment.amount + eligible_positive_adjustment.amount
      end

      it 'returns the correct amount' do
        expect(subject.avatax_order_adjustment_total).to eq -eligible_total
      end
    end
  end
end
