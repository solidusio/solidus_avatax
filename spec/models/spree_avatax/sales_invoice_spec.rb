require 'spec_helper'

describe SpreeAvatax::SalesInvoice do
  describe '.generate' do
    subject do
      SpreeAvatax::SalesInvoice.generate(order)
    end

    let(:order) do
      create(:shipped_order, {
        line_items_count: 1,
        ship_address: create(:address, {
          address1: "1234 Way",
          address2: "",
          city: "New York",
          state: state,
          country: country,
          zipcode: "10010",
          phone: "111-111-1111",
        })
      })
    end

    let(:line_item) { order.line_items.first }
    let(:shipment) { order.shipments.first }

    let(:country) { create(:country) }
    let(:state) { create(:state, country: country, name: 'New York', abbr: 'NY') }

    let(:expected_gettax_params) do
      {
        doccode:       order.number,
        customercode:  order.email,
        companycode:   SpreeAvatax::Config.company_code,

        doctype: SpreeAvatax::SalesInvoice::DOC_TYPE,
        docdate: Date.today,

        commit: false,

        discount: order.avatax_order_adjustment_total.round(2).to_f,

        addresses: [
          {
            addresscode: SpreeAvatax::SalesShared::ADDRESS_CODE,
            line1:       REXML::Text.normalize(order.ship_address.address1),
            line2:       REXML::Text.normalize(order.ship_address.address2),
            city:        REXML::Text.normalize(order.ship_address.city),
            postalcode:  REXML::Text.normalize(order.ship_address.zipcode),
          },
        ],

        lines: [
          { # line item
            no:                  "Spree::LineItem-#{line_item.id}",
            qty:                 line_item.quantity,
            amount:              line_item.discounted_amount.round(2).to_f,
            origincodeline:      SpreeAvatax::SalesShared::ORIGIN_CODE,
            destinationcodeline: SpreeAvatax::SalesShared::DESTINATION_CODE,

            description: expected_truncated_description,

            itemcode:   line_item.variant.sku,
            discounted: order.avatax_order_adjustment_total > 0.0,
          },
          { # shipping charge
            no:                  "Spree::Shipment-#{shipment.id}",
            qty:                 1,
            amount:              shipment.discounted_amount.round(2).to_f,
            origincodeline:      SpreeAvatax::SalesShared::ORIGIN_CODE,
            destinationcodeline: SpreeAvatax::SalesShared::DESTINATION_CODE,

            description: SpreeAvatax::SalesShared::SHIPPING_DESCRIPTION,

            taxcode:    SpreeAvatax::SalesShared::SHIPPING_TAX_CODE,
            discounted: false,
          },
        ],
      }
    end

    let(:expected_truncated_description) { line_item.variant.product.description.truncate(100) }
    let(:gettax_response) { sales_invoice_gettax_response(order.number, line_item, shipment) }
    let(:gettax_response_line_item_tax_line) { Array.wrap(gettax_response[:tax_lines][:tax_line]).first }
    let(:gettax_response_shipment_tax_line) { Array.wrap(gettax_response[:tax_lines][:tax_line]).last }
    let(:order_calculated_tax) do
      BigDecimal.new(gettax_response[:total_tax])
    end
    let(:line_item_calculated_tax) do
      BigDecimal.new(gettax_response_line_item_tax_line[:tax]).abs
    end
    let(:shipment_calculated_tax) do
      BigDecimal.new(gettax_response_shipment_tax_line[:tax]).abs
    end

    let!(:gettax_stub) do
      SpreeAvatax::Shared.tax_svc
        .should_receive(:gettax)
        .with(expected_gettax_params)
        .and_return(gettax_response)
    end

    it 'creates a sales invoice' do
      expect {
        subject
      }.to change { SpreeAvatax::SalesInvoice.count }.by(1)
      expect(order.avatax_sales_invoice).to eq SpreeAvatax::SalesInvoice.last
      expect(order.avatax_sales_invoice.attributes).to include({
        "transaction_id"        => gettax_response[:transaction_id],
        "doc_id"                => gettax_response[:doc_id],
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

    it 'persists the results to the shipments' do
      expect {
        subject
      }.to change { shipment.reload.additional_tax_total }.from(0).to(shipment_calculated_tax)
    end

    it "creates a line item adjustment" do
      subject
      expect(line_item.adjustments.tax.count).to eq 1
      adjustment = line_item.adjustments.first
      expect(adjustment.amount).to eq line_item_calculated_tax
      expect(adjustment.source).to eq Spree::TaxRate.first
      expect(adjustment.state).to eq 'closed'
    end

    it "creates a shipment adjustment" do
      subject
      expect(shipment.adjustments.tax.count).to eq 1
      adjustment = shipment.adjustments.first
      expect(adjustment.amount).to eq shipment_calculated_tax
      expect(adjustment.source).to eq Spree::TaxRate.first
      expect(adjustment.state).to eq 'closed'
    end

    context 'user input contains XML characters' do
      let(:line1) { "<&line1>" }
      let(:line2) { "<&line2>" }
      let(:city) { "<&city>" }
      let(:zipcode) { "<12345>" }
      let(:email) { "test&@test.com" }
      let(:description) { "A description <wi>&/th xml characters" }

      before(:each) do
        ship_address = order.ship_address
        ship_address.update_columns(address1: line1, address2: line2, city: city, zipcode: zipcode)
        order.update_columns(email: email)
        line_item.variant.product.update_columns(description: description)
      end

      let(:expected_gettax_params) do
        super().tap do |params|
          params[:addresses].first.merge!(line1: REXML::Text.normalize(line1), line2: REXML::Text.normalize(line2), city: REXML::Text.normalize(city), postalcode: REXML::Text.normalize(zipcode))
          params[:customercode] = REXML::Text.normalize(email)
          params[:lines][0][:description] = REXML::Text.normalize(description)
        end
      end

      it 'succeeds' do
        subject
      end
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
        let(:handler) { -> (o, e) { raise new_error } }
        let(:new_error) { StandardError.new('just testing 2') }

        before do
          SpreeAvatax::Config.stub(sales_invoice_generate_error_handler: handler)
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

    context 'when an invoice already exists' do
      context 'when the existing invoice is not committed' do
        let!(:previous_sales_invoice) { create(:avatax_sales_invoice, order: order) }

        it 'deletes the previous invoice' do
          subject
          expect(SpreeAvatax::SalesInvoice.find_by(id: previous_sales_invoice.id)).to be_nil
        end
      end

      context 'when the existing invoice is committed' do
        let!(:previous_sales_invoice) { create(:avatax_sales_invoice, order: order, committed_at: order.completed_at) }

        it 'raises an AlreadyCommittedError' do
          expect {
            subject
          }.to raise_error(SpreeAvatax::SalesInvoice::AlreadyCommittedError)
        end
      end
    end

    describe 'when the description is too long' do
      let(:description) { 'a'*1000 }
      let(:expected_truncated_description) { description.truncate(100) }

      before do
        line_item.variant.product.update!(description: description)
      end

      it 'succeeds' do
        subject # method expectation will fail if date isn't right
      end
    end

    context 'when the order is not taxable' do
      let(:order) { create(:order_with_line_items, ship_address: nil, line_items_count: 1) }

      let!(:gettax_stub) { }

      it 'does not create a sales invoice' do
        expect {
          subject
        }.not_to change { SpreeAvatax::SalesInvoice.count }
        expect(order.avatax_sales_invoice).to eq nil
      end

      it 'does not call avatax' do
        SpreeAvatax::Shared.tax_svc.should_receive(:gettax).never
        subject
      end
    end
  end

  describe '.commit' do
    subject do
      SpreeAvatax::SalesInvoice.commit(order)
    end

    let!(:order) { sales_invoice.order }
    let(:sales_invoice) { create(:avatax_sales_invoice) }

    let(:expected_posttax_params) do
      {
        doccode:     sales_invoice.doc_code,
        companycode: SpreeAvatax::Config.company_code,

        doctype: SpreeAvatax::SalesInvoice::DOC_TYPE,
        docdate: sales_invoice.doc_date,

        commit: true,

        totalamount: sales_invoice.pre_tax_total,
        totaltax:    sales_invoice.additional_tax_total,
      }
    end

    context 'when the order is taxable' do
      let!(:posttax_stub) do
        SpreeAvatax::Shared.tax_svc
          .should_receive(:posttax)
          .with(expected_posttax_params)
          .and_return(
            sales_invoice_posttax_response
          )
      end

      it 'marks the sales invoice as committed' do
        expect {
          subject
        }.to change { sales_invoice.reload.committed_at? }.from(false).to(true)
      end
    end

    context 'when the order is not taxable' do
      before do
        SpreeAvatax::Shared.should_receive(:taxable_order?).with(sales_invoice.order).and_return(false)
      end

      it 'does not call avatax' do
        SpreeAvatax::Shared.tax_svc.should_receive(:posttax).never
        subject
      end
    end

    context 'when the sales_invoice does not exist' do
      let(:sales_invoice) { nil }
      let(:order) { create(:shipped_order, line_items_count: 1) }

      it 'raises a SalesInvoiceNotFound error' do
        expect {
          subject
        }.to raise_error(SpreeAvatax::SalesInvoice::CommitInvoiceNotFound)
      end
    end

    context 'when an error occurs' do
      let(:error) { StandardError.new('just testing') }
      let!(:posttax_stub) { }

      before do
        SpreeAvatax::SalesInvoice
          .should_receive(:post_tax)
          .and_raise(error)
      end

      context 'when an error_handler is not defined' do
        it 'raises the original error' do
          expect {
            subject
          }.to raise_error(error)
        end
      end

      context 'when an error_handler is defined' do
        let(:handler) { -> (o, e) { raise new_error } }
        let(:new_error) { StandardError.new('just testing 2') }

        before do
          SpreeAvatax::Config.stub(sales_invoice_commit_error_handler: handler)
        end

        it 'calls the handler instead of raising the original error' do
          expect {
            subject
          }.to raise_error(new_error)
        end
      end
    end
  end

  describe '.cancel' do
    subject do
      SpreeAvatax::SalesInvoice.cancel(order)
    end

    context 'when the sales invoice exists' do
      let(:order) { sales_invoice.order }
      let(:sales_invoice) { create(:avatax_sales_invoice, committed_at: Time.now) }

      let(:expected_canceltax_params) do
        {
          doccode:     sales_invoice.doc_code,
          doctype:     SpreeAvatax::SalesInvoice::DOC_TYPE,
          cancelcode:  SpreeAvatax::SalesInvoice::CANCEL_CODE,
          companycode: SpreeAvatax::Config.company_code,
        }
      end

      let(:canceltax_response) { sales_invoice_canceltax_response }

      let!(:canceltax_stub) do
        SpreeAvatax::Shared.tax_svc
          .should_receive(:canceltax)
          .with(expected_canceltax_params)
          .and_return(canceltax_response)
      end

      it 'should update the sales invoice' do
        expect {
          subject
        }.to change { sales_invoice.canceled_at }.from(nil)
        expect(sales_invoice.cancel_transaction_id).to eq canceltax_response[:transaction_id]
      end

      context 'when an error occurs' do
        let(:error) { StandardError.new('just testing') }
        let!(:canceltax_stub) { }

        before do
          SpreeAvatax::SalesInvoice
            .should_receive(:cancel_tax)
            .and_raise(error)
        end

        context 'when an error_handler is not defined' do
          it 'raises the original error' do
            expect {
              subject
            }.to raise_error(error)
          end
        end

        context 'when an error_handler is defined' do
          let(:handler) { -> (o, e) { raise new_error } }
          let(:new_error) { StandardError.new('just testing 2') }

          before do
            SpreeAvatax::Config.stub(sales_invoice_cancel_error_handler: handler)
          end

          it 'calls the handler instead of raising the original error' do
            expect {
              subject
            }.to raise_error(new_error)
          end
        end
      end
    end
  end
end
