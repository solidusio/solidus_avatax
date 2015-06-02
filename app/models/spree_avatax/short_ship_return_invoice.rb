class SpreeAvatax::ShortShipReturnInvoice < ActiveRecord::Base
  DOC_TYPE = 'ReturnInvoice'

  DESTINATION_CODE = "1"

  TAX_OVERRIDE_TYPE = 'TaxAmount'
  TAX_OVERRIDE_REASON = 'Short ship'

  has_many :short_ship_return_invoice_inventory_units, class_name: 'SpreeAvatax::ShortShipReturnInvoiceInventoryUnit', inverse_of: :short_ship_return_invoice
  has_many :inventory_units, through: :short_ship_return_invoice_inventory_units, class_name: 'Spree::InventoryUnit'

  validates :doc_id, presence: true
  validates :doc_code, presence: true
  validates :doc_date, presence: true

  class << self
    # Calls the Avatax API to generate a return invoice for an item that has
    # been short shipped.  It tells Avatax how much tax was refunded rather than
    # asking it how much should be refunded.
    # It is generated in the "committed" state since there is no need for a two-
    # step commit here.
    #
    # On failure it will raise.
    def generate(unit_cancels:)
      inventory_units = unit_cancels.map(&:inventory_unit)

      order_ids = inventory_units.map(&:order_id).uniq
      if order_ids.size > 1
        raise "unit cancels #{unit_cancels.map(&:id)} had more than one order: #{order_ids}"
      end

      success_result = get_tax(unit_cancels: unit_cancels)

      create!(
        inventory_units:       inventory_units,
        committed:             true,
        doc_id:                success_result[:doc_id],
        doc_code:              success_result[:doc_code],
        doc_date:              success_result[:doc_date],
      )
    end

    private

    def get_tax(unit_cancels:)
      params = gettax_params(unit_cancels: unit_cancels)

      logger.info("[avatax] gettax unit_cancel_ids=#{unit_cancels.map(&:id)} doc_type=#{DOC_TYPE}")
      logger.debug("[avatax] params: " + params.to_json)

      response = SpreeAvatax::Shared.tax_svc.gettax(params)
      SpreeAvatax::Shared.require_success!(response)

      response
    end

    # see https://github.com/avadev/AvaTax-Calc-SOAP-Ruby/blob/master/GetTaxTest.rb
    def gettax_params(unit_cancels:)
      # we verified previously that there is only one order
      order = unit_cancels.first.inventory_unit.order

      lines = gettax_line_params(
        unit_cancels: unit_cancels,
        taxed_at: order.avatax_sales_invoice.try!(:doc_date) || order.completed_at
      )

      {
        doccode:       "#{order.number}-short-#{Time.now.to_f}",
        referencecode: order.number,
        customercode:  order.user_id,
        companycode:   SpreeAvatax::Config.company_code,

        doctype: DOC_TYPE,
        docdate: Date.today,

        commit: true,

        addresses: [
          {
            addresscode: DESTINATION_CODE,
            line1:       REXML::Text.normalize(order.ship_address.address1),
            line2:       REXML::Text.normalize(order.ship_address.address2),
            city:        REXML::Text.normalize(order.ship_address.city),
            postalcode:  REXML::Text.normalize(order.ship_address.zipcode),
          },
        ],

        lines: lines,
      }
    end

    def gettax_line_params(unit_cancels:, taxed_at:)
      unit_cancels.sort_by(&:id).map do |unit_cancel|
        inventory_unit = unit_cancel.inventory_unit

        adjustment = unit_cancel.adjustment

        if adjustment
          total = -adjustment.amount # adjustment is stored as a negative amount
          tax = inventory_unit.additional_tax_total
          before_tax = total - tax
        else
          # TODO: Consider removing this case. Are there expected scenarios
          # where there will be no adjustment present?
          total = 0
          tax = 0
          before_tax = 0
        end

        {
          # Required Parameters
          no:                  inventory_unit.id,
          itemcode:            inventory_unit.line_item.variant.sku,
          taxcode:             inventory_unit.line_item.tax_category.code,
          qty:                 1,
          amount:              -before_tax,
          origincodeline:      DESTINATION_CODE, # We don't really send the correct value here
          destinationcodeline: DESTINATION_CODE,

          # We tell Avatax what the amounts were rather than asking Avatax what
          # the amounts should have been.
          taxoverridetypeline: TAX_OVERRIDE_TYPE,
          reasonline:          TAX_OVERRIDE_REASON,
          taxamountline:       -tax,
          taxdateline:         taxed_at.to_date,

          # Best Practice Parameters
          description: REXML::Text.normalize(inventory_unit.line_item.variant.product.description.to_s[0...100]),
        }
      end
    end
  end
end
