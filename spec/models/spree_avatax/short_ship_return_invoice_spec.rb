require 'spec_helper'

describe SpreeAvatax::ShortShipReturnInvoice do
  include ShortShipReturnInvoiceSoapResponses

  describe '.generate' do
    before do
      # disable avatax tax calculation. we're not testing calculating tax.
      allow(SpreeAvatax::Shared).to receive(:taxable_order?).and_return(false)
      allow(SpreeAvatax::SalesShared).to receive(:reset_tax_attributes)
    end

    let(:order) do
      create(
        :order_with_line_items,
        line_items_price: 10,
        line_items_count: 2,
      )
    end

    def line_item_1
      order.line_items.first
    end

    def line_item_2
      order.line_items.last
    end

    def inventory_unit_1
      line_item_1.inventory_units.first
    end

    def inventory_unit_2
      line_item_2.inventory_units.first
    end

    # add some tax and complete the order
    before do
      line_item_1.adjustments.create!(
        amount: 1,
        label: 'fake tax',
        order: order,
        source: Spree::TaxRate.avatax_the_one_rate,
        state: 'closed',
      )
      order.contents.advance
      create(:payment, amount: order.total, order: order)
      order.complete!
      order.reload
    end

    describe 'gettax params' do
      let(:now) { Time.now }

      around do |example|
        Timecop.freeze(now) do
          example.run
        end
      end

      def expected_gettax_params
        {
          doccode:       "#{order.number}-short-#{now.to_f}",
          referencecode: order.number,
          customercode:  order.user_id,
          companycode:   SpreeAvatax::Config.company_code,

          doctype: SpreeAvatax::ShortShipReturnInvoice::DOC_TYPE,
          docdate: now.to_date,

          commit: true,

          addresses: [
            {
              addresscode: SpreeAvatax::ShortShipReturnInvoice::DESTINATION_CODE,
              line1:       REXML::Text.normalize(order.ship_address.address1),
              line2:       REXML::Text.normalize(order.ship_address.address2),
              city:        REXML::Text.normalize(order.ship_address.city),
              postalcode:  REXML::Text.normalize(order.ship_address.zipcode),
            },
          ],

          lines: [
            {
              no:                  inventory_unit_1.id,
              itemcode:            inventory_unit_1.line_item.variant.sku,
              taxcode:             inventory_unit_1.line_item.tax_category.tax_code,
              qty:                 1,
              amount:              -10.to_d,
              origincodeline:      SpreeAvatax::ShortShipReturnInvoice::DESTINATION_CODE,
              destinationcodeline: SpreeAvatax::ShortShipReturnInvoice::DESTINATION_CODE,

              taxoverridetypeline: SpreeAvatax::ShortShipReturnInvoice::TAX_OVERRIDE_TYPE,
              reasonline:          SpreeAvatax::ShortShipReturnInvoice::TAX_OVERRIDE_REASON,
              taxamountline:       -1.to_d,
              taxdateline:         now.to_date,

              description: REXML::Text.normalize(inventory_unit_1.line_item.variant.product.description[0...100]),
            },
            {
              no:                  inventory_unit_2.id,
              itemcode:            inventory_unit_2.line_item.variant.sku,
              taxcode:             inventory_unit_2.line_item.tax_category.tax_code,
              qty:                 1,
              amount:              -10.to_d,
              origincodeline:      SpreeAvatax::ShortShipReturnInvoice::DESTINATION_CODE,
              destinationcodeline: SpreeAvatax::ShortShipReturnInvoice::DESTINATION_CODE,

              taxoverridetypeline: SpreeAvatax::ShortShipReturnInvoice::TAX_OVERRIDE_TYPE,
              reasonline:          SpreeAvatax::ShortShipReturnInvoice::TAX_OVERRIDE_REASON,
              taxamountline:       0.to_d,
              taxdateline:         now.to_date,

              description: REXML::Text.normalize(inventory_unit_2.line_item.variant.product.description[0...100]),
            },
          ],
        }
      end

      let(:unit_cancels) do
        Spree::OrderCancellations.new(order).short_ship(order.inventory_units)
      end

      it 'generates the expected params for avatax' do
        expect(SpreeAvatax::Shared.tax_svc).to(
          receive(:gettax).
          with(expected_gettax_params).
          and_return(short_ship_return_invoice_gettax_response)
        )

        SpreeAvatax::ShortShipReturnInvoice.generate(unit_cancels: unit_cancels)
      end
    end

    context 'with a successful response' do
      let(:unit_cancels) do
        Spree::OrderCancellations.new(order).short_ship(order.inventory_units)
      end

      before do
        expect(SpreeAvatax::Shared.tax_svc).to(
          receive(:gettax).
          and_return(short_ship_return_invoice_gettax_response)
        )
      end

      it 'creates a return invoice with the correct inventory units' do
        expect {
          SpreeAvatax::ShortShipReturnInvoice.generate(unit_cancels: unit_cancels)
        }.to change { SpreeAvatax::ShortShipReturnInvoice.count }.by(1)

        short_ship_return_invoice = SpreeAvatax::ShortShipReturnInvoice.last

        expect(short_ship_return_invoice.inventory_units).to eq(
          [inventory_unit_1, inventory_unit_2]
        )
      end
    end

    context 'with inventory units from multiple orders' do
      let(:order2) { create(:order_ready_to_ship) }

      let(:unit_cancels1) do
        Spree::OrderCancellations.new(order).short_ship([inventory_unit_1])
      end
      let(:unit_cancels2) do
        Spree::OrderCancellations.new(order2).short_ship(order2.inventory_units)
      end

      it 'fails' do
        expect {
          SpreeAvatax::ShortShipReturnInvoice.generate(
            unit_cancels: unit_cancels1 + unit_cancels2
          )
        }.to raise_error(/more than one order/)
      end
    end

  end
end
