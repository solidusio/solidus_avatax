require 'spec_helper'

describe SpreeAvatax::Shared do
  describe '.logger' do
    subject { SpreeAvatax::Shared.logger }
    it { should be_a Logger }
  end

  describe '.taxable_order?' do
    subject { SpreeAvatax::Shared.taxable_order?(order) }

    context 'when the order is taxable' do
      let(:order) { create(:shipped_order, line_items_count: 1) }
      it { should be true }
    end

    context 'when the order has no line items' do
      let(:order) { create(:order) }
      it { should be false }
    end

    context 'when the order has no ship address' do
      let(:order) { create(:shipped_order, line_items_count: 1, ship_address: nil) }
      it { should be false }
    end
  end

  describe '.tax_svc' do
    subject { SpreeAvatax::Shared.tax_svc }
    it { should be_a AvaTax::TaxService }
  end

  describe '.require_success!' do
    subject do
      SpreeAvatax::Shared.require_success!(response)
    end

    context 'when the response is a success' do
      let(:response) { {transaction_id: "4315047353885220", result_code: 'Success'} }

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the response if a failure' do
      let(:response) do
        {
          transaction_id: "4315046676197187",
          result_code: 'Error',
          messages: {
            message: {
              summary: 'Something awful happened.',
            },
          },
        }
      end

      it 'raises a FailedApiResponse' do
        expect { subject }.to raise_error(SpreeAvatax::Shared::FailedApiResponse)
      end
    end
  end
end
