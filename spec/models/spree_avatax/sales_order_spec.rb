require 'spec_helper'

describe SpreeAvatax::SalesOrder do

  describe '.generate' do
    subject do
      SpreeAvatax::SalesOrder.generate(order)
    end

    let(:order) { create(:order_with_line_items, line_items_count: 1) }
    let(:line_item) { order.line_items.first }

    let!(:tax_rate) { create :tax_rate, name: 'Avatax No Op', calculator: create(:avatax_tax_calculator) }

    let(:expected_gettax_params) do
      {
        doccode:       order.number,
        customercode:  order.email,
        companycode:   SpreeAvatax::Config.company_code,

        doctype: SpreeAvatax::SalesOrder::DOC_TYPE,
        docdate: Date.today,

        commit: false,

        discount: order.promotion_adjustment_total.round(2).to_f,

        addresses: [
          {
            addresscode: SpreeAvatax::SalesShared::ADDRESS_CODE,
            line1:       order.ship_address.address1,
            line2:       order.ship_address.address2,
            city:        order.ship_address.city,
            postalcode:  order.ship_address.zipcode,
          },
        ],

        lines: [
          {
            no:                  line_item.id,
            item_code:           line_item.variant.sku,
            qty:                 line_item.quantity,
            amount:              line_item.discounted_amount.round(2).to_f,
            origincodeline:      SpreeAvatax::SalesShared::ORIGIN_CODE,
            destinationcodeline: SpreeAvatax::SalesShared::DESTINATION_CODE,

            description: expected_truncated_description,

            discounted: order.promotion_adjustment_total > 0.0,
          },
        ]
      }
    end

    let(:expected_truncated_description) { line_item.variant.product.description[0...100] }
    let(:gettax_response) { sales_order_gettax_response(order.number, line_item.id) }
    let(:gettax_response_line_item_tax_line) { Array.wrap(gettax_response[:tax_lines][:tax_line]).first }
    let(:order_calculated_tax) do
      BigDecimal.new(gettax_response[:total_tax])
    end
    let(:line_item_calculated_tax) do
      BigDecimal.new(gettax_response_line_item_tax_line[:tax]).abs
    end

    let!(:gettax_stub) do
      SpreeAvatax::Shared.tax_svc
        .should_receive(:gettax)
        .with(expected_gettax_params)
        .and_return(gettax_response)
    end

    it 'creates a sales order' do
      expect {
        subject
      }.to change { SpreeAvatax::SalesOrder.count }.by(1)
      expect(order.avatax_sales_orders).to eq [SpreeAvatax::SalesOrder.last]
      expect(order.avatax_sales_orders.last.attributes).to include({
        "transaction_id"        => gettax_response[:transaction_id],
        "doc_code"              => gettax_response[:doc_code],
        "doc_date"              => gettax_response[:doc_date],
        "pre_tax_total"         => BigDecimal.new(gettax_response[:total_amount]),
        "additional_tax_total"  => BigDecimal.new(gettax_response[:total_tax]),
      })
    end

    it 'persists the results to the order' do
      expect {
        subject
      }.to change { order.reload.additional_tax_total }.from(0).to(order_calculated_tax)
    end

    it 'persists the results to the line items' do
      expect {
        subject
      }.to change { line_item.reload.additional_tax_total }.from(0).to(line_item_calculated_tax)
    end

    it "creates a line item adjustment" do
      subject
      expect(line_item.adjustments.tax.count).to eq 1
      adjustment = line_item.adjustments.first
      expect(adjustment.amount).to eq line_item_calculated_tax
      expect(adjustment.source).to eq tax_rate
      expect(adjustment.state).to eq 'closed'
    end

    context 'when an error occurs' do
      let(:error) { StandardError.new('just testing') }
      let!(:gettax_stub) { }

      before do
        SpreeAvatax::SalesShared
          .should_receive(:get_tax)
          .and_raise(error)
      end

      context 'when an error_handler is not defined' do
        it 'calls the handler instead of raising the original error' do
          expect {
            subject
          }.to raise_error(error)
        end
      end

      context 'when an error_handler is defined' do
        let(:handler) { -> (e) { raise new_error } }
        let(:new_error) { StandardError.new('just testing 2') }

        before do
          SpreeAvatax::Config.stub(error_handler: handler)
        end

        it 'calls the handler instead of raising the original error' do
          expect {
            subject
          }.to raise_error(new_error)
        end
      end
    end

    context 'when the response for a line item is missing' do
      before do
        gettax_response_line_item_tax_line[:no] = (line_item.id + 1).to_s
      end

      it 'raises InvalidApiResponse' do
        expect {
          subject
        }.to raise_error(SpreeAvatax::SalesShared::InvalidApiResponse)
      end
    end

    context 'when a sales order already exists' do
      let!(:previous_sales_order) { create(:avatax_sales_order, order: order) }

      it 'creates another sales order' do
        expect {
          subject
        }.to change { order.avatax_sales_orders.count }.from(1).to(2)
      end
    end

    describe 'when the description is too long' do
      let(:description) { 'a'*1000 }
      let(:expected_truncated_description) { 'a'*100 }

      before do
        line_item.variant.product.update!(description: description)
      end

      it 'succeeds' do
        subject # method expectation will fail if date isn't right
      end
    end

    context 'when the order is not taxable' do
      let(:order) { create(:order_with_line_items, ship_address: nil) }

      let!(:gettax_stub) { }

      it 'does not create a sales order' do
        expect {
          subject
        }.not_to change { SpreeAvatax::SalesOrder.count }
        expect(order.avatax_sales_orders.count).to eq 0
      end

      it 'does not call avatax' do
        SpreeAvatax::Shared.tax_svc.should_receive(:gettax).never
        subject
      end
    end
  end

end
