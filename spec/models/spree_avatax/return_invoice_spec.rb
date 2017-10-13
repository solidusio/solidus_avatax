require 'spec_helper'

describe SpreeAvatax::ReturnInvoice do

  describe '.generate' do
    let(:reimbursement) { create(:reimbursement) }
    let(:order) { reimbursement.order }
    let(:return_item) { reimbursement.return_items.first }

    let(:expected_gettax_params) do
      {
        doccode:       reimbursement.number,
        referencecode: reimbursement.order.number,
        customercode:  reimbursement.order.user.email,
        companycode:   SpreeAvatax::Config.company_code,

        doctype: SpreeAvatax::ReturnInvoice::DOC_TYPE,
        docdate: Date.today,

        commit: false,

        taxoverridetype: SpreeAvatax::ReturnInvoice::TAX_OVERRIDE_TYPE,
        reason:          SpreeAvatax::ReturnInvoice::TAX_OVERRIDE_REASON,
        taxdate:         expected_tax_override_date,

        addresses: [
          {
            addresscode: SpreeAvatax::ReturnInvoice::DESTINATION_CODE,
            line1:       REXML::Text.normalize(reimbursement.order.ship_address.address1),
            line2:       REXML::Text.normalize(reimbursement.order.ship_address.address2),
            city:        REXML::Text.normalize(reimbursement.order.ship_address.city),
            postalcode:  REXML::Text.normalize(reimbursement.order.ship_address.zipcode),
          },
        ],
        lines: [
          {
            no:                  return_item.id,
            itemcode:            return_item.inventory_unit.line_item.variant.sku,
            taxcode:             return_item.inventory_unit.line_item.tax_category.tax_code,
            qty:                 1,
            amount:              -return_item.amount,
            origincodeline:      SpreeAvatax::ReturnInvoice::DESTINATION_CODE,
            destinationcodeline: SpreeAvatax::ReturnInvoice::DESTINATION_CODE,

            description: REXML::Text.normalize(expected_truncated_description),
          },
        ],
      }
    end

    let(:expected_tax_override_date) { Date.today }
    let(:expected_truncated_description) { return_item.inventory_unit.line_item.variant.product.description[0...100] }
    let(:gettax_response) { return_invoice_gettax_response(reimbursement.number, return_item.id) }
    let(:gettax_response_return_item_tax_line) { Array.wrap(gettax_response[:tax_lines][:tax_line]).first }
    let(:return_item_calculated_tax) do
      BigDecimal.new(gettax_response_return_item_tax_line[:tax]).abs
    end

    let!(:tax_svc_expectation) do
      expect(SpreeAvatax::Shared.tax_svc)
        .to receive(:gettax)
        .with(expected_gettax_params)
        .and_return(gettax_response)
    end

    subject do
      SpreeAvatax::ReturnInvoice.generate(reimbursement)
    end

    it 'creates a return invoice' do
      expect {
        subject
      }.to change { SpreeAvatax::ReturnInvoice.count }.by(1)
      expect(reimbursement.return_invoice).to eq SpreeAvatax::ReturnInvoice.last
    end

    it 'persists the results to the return items' do
      expect {
        subject
      }.to change { return_item.reload.additional_tax_total }.from(0).to(return_item_calculated_tax)
    end

    context 'when the response for a return item is missing' do
      before do
        gettax_response_return_item_tax_line[:no] = (return_item.id + 1).to_s
      end

      it 'raises ReturnItemResponseMissing' do
        expect {
          subject
        }.to raise_error(SpreeAvatax::ReturnInvoice::ReturnItemResponseMissing)
      end
    end

    context 'when an invoice already exists' do
      let!(:previous_return_invoice) { create(:return_invoice, reimbursement: reimbursement) }

      it 'deletes the previous invoice' do
        subject
        expect(SpreeAvatax::ReturnInvoice.find_by(id: previous_return_invoice.id)).to be_nil
      end
    end

    describe 'when avatax_invoice_at is present' do
      let(:expected_tax_override_date) { 2.days.ago.to_date }

      before do
        reimbursement.order.update_attributes!(avatax_invoice_at: expected_tax_override_date)
      end

      it 'succeeds' do
        subject # method expectation will fail if date isn't right
      end
    end

    describe 'when the description is too long' do
      let(:description) { 'a'*1000 }
      let(:expected_truncated_description) { 'a'*100 }

      before do
        return_item.inventory_unit.line_item.variant.product.update!(description: description)
      end

      it 'succeeds' do
        subject # method expectation will fail if date isn't right
      end
    end

    context 'user input contains XML characters' do
      let(:line1) { "<&line1>" }
      let(:line2) { "<&line2>" }
      let(:city) { "<&city>" }
      let(:zipcode) { "<12345>" }
      let(:description) { "A description <wi>&/th xml characters" }

      before(:each) do
        ship_address = order.ship_address
        ship_address.update_columns(address1: line1, address2: line2, city: city, zipcode: zipcode)
        return_item.inventory_unit.line_item.variant.product.update_columns(description: description)
      end

      let(:expected_gettax_params) do
        super().tap do |params|
          params[:addresses].first.merge!(line1: REXML::Text.normalize(line1), line2: REXML::Text.normalize(line2), city: REXML::Text.normalize(city), postalcode: REXML::Text.normalize(zipcode))
          params[:lines][0][:description] = REXML::Text.normalize(description)
        end
      end

      it 'succeeds' do
        subject
      end
    end

    context 'when avatax is disabled' do
      let!(:config) { create(:avatax_config, enabled: false) }
      let!(:tax_svc_expectation) { expect(SpreeAvatax::Shared).to_not receive(:tax_svc) }

      it 'does nothing' do
        expect {
          subject
        }.to_not change { SpreeAvatax::ReturnInvoice.count }
      end
    end
  end

  describe '.finalize' do
    let(:return_invoice) { create(:return_invoice) }

    let(:expected_posttax_params) do
      {
        doccode:     return_invoice.doc_code,
        companycode: SpreeAvatax::Config.company_code,

        doctype: SpreeAvatax::ReturnInvoice::DOC_TYPE,
        docdate: return_invoice.doc_date,

        commit: true,

        totalamount: return_invoice.pre_tax_total,
        totaltax:    return_invoice.additional_tax_total,
      }
    end

    let!(:tax_svc_expectation) do
      expect(SpreeAvatax::Shared.tax_svc)
        .to receive(:posttax)
        .with(expected_posttax_params)
        .and_return(
          return_invoice_posttax_response
        )
    end

    subject do
      SpreeAvatax::ReturnInvoice.finalize(return_invoice.reimbursement)
    end

    it 'marks the return invoice as committed' do
      expect {
        subject
      }.to change { return_invoice.reload.committed? }.from(false).to(true)
    end

    context 'when avatax is disabled' do
      let!(:config) { create(:avatax_config, enabled: false) }
      let!(:tax_svc_expectation) { expect(SpreeAvatax::Shared).to_not receive(:tax_svc) }

      it 'does nothing' do
        subject
        expect(return_invoice.reload.committed?).to be_falsey
      end
    end
  end

end
