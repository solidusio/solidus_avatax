module SpreeAvatax::SalesShared
  ADDRESS_CODE = "1"
  DESTINATION_CODE = "1"
  ORIGIN_CODE = "1"

  class InvalidApiResponse < StandardError; end

  class << self
    # Queries Avatax for taxes on a specific order using the specified doc_type.
    # SalesOrder doc types are not persisted on Avatax.
    # SalesInvoice doc types do persist an uncommitted record on Avatax.
    def get_tax(order, doc_type)
      params = gettax_params(order, doc_type)

      logger.info "[avatax] gettax order=#{order.id} doc_type=#{doc_type}"
      logger.debug { "[avatax] params: #{params.to_json}" }

      response = SpreeAvatax::Shared.tax_svc.gettax(params)
      SpreeAvatax::Shared.require_success!(response)

      response
    end

    def update_taxes(order, line_item_tax_lines)
      reset_tax_attributes(order)

      line_item_tax_lines.each do |line_item, tax_line|
        line_item.update_column(:pre_tax_amount, line_item.discounted_amount)

        tax = BigDecimal.new(tax_line[:tax]).abs

        line_item.adjustments.tax.create!({
          adjustable: line_item,
          amount:     tax,
          order:      order,
          label:      Spree.t(:avatax_label),
          included:   false, # would be true for VAT
          source:     Spree::TaxRate.avatax_the_one_rate,
          state:      'closed', # this tells spree not to automatically recalculate avatax tax adjustments
        })

        Spree::ItemAdjustments.new(line_item).update
        line_item.save!
      end

      Spree::OrderUpdater.new(order).update
      order.save!
    end

    def match_line_items_to_tax_lines(order, avatax_result)
      # Array.wrap is required because the XML engine the Avatax gem uses turns child nodes into
      #   {...} instead of [{...}] when there is only one child.
      tax_lines = Array.wrap(avatax_result[:tax_lines][:tax_line])

      if tax_lines.size != order.line_items.size
        raise InvalidApiResponse.new("Avatax response has #{tax_lines.size} items which does not match the supplied #{order.line_items.size} line items.")
      end

      order.line_items.inject({}) do |hash, line_item|
        tax_line = tax_lines.detect { |l| l[:no] == line_item.id.to_s }
        if tax_line.nil?
          raise InvalidApiResponse.new("Couldn't find tax line for line item #{line_item.id}")
        end
        hash[line_item] = tax_line
        hash
      end
    end

    private

    def logger
      SpreeAvatax::Shared.logger
    end

    # see https://github.com/avadev/AvaTax-Calc-SOAP-Ruby/blob/master/GetTaxTest.rb
    def gettax_params(order, doc_type)
      {
        doccode:       order.number,
        customercode:  order.email,
        companycode:   SpreeAvatax::Config.company_code,

        doctype: doc_type,
        docdate: Date.today,

        commit: false, # we commit separately after the order completes

        discount: order.promotion_adjustment_total.round(2).to_f,

        addresses: [
          {
            addresscode: ADDRESS_CODE,
            line1:       order.ship_address.address1,
            line2:       order.ship_address.address2,
            city:        order.ship_address.city,
            postalcode:  order.ship_address.zipcode,
          },
        ],

        lines: gettax_lines_params(order),
      }
    end

    def gettax_lines_params(order)
      line_items = order.line_items.includes(variant: :product)

      line_items.map do |line_item|
        {
          # Required Parameters
          no:                  line_item.id,
          item_code:           line_item.variant.sku,
          qty:                 line_item.quantity,
          amount:              line_item.discounted_amount.round(2).to_f,
          origincodeline:      ORIGIN_CODE,
          destinationcodeline: DESTINATION_CODE,

          # Best Practice Parameters
          description: line_item.variant.product.description.to_s[0...100],

          # Optional Parameters (required for our context)
          discounted: order.promotion_adjustment_total > 0.0, # Continue to pass this field if we have an order-level discount so the line item gets discount calculated onto it
        }
      end
    end

    def reset_tax_attributes(order)
      order.all_adjustments.tax.destroy_all

      order.line_items.each do |line_item|
        line_item.update_attributes!({
          additional_tax_total: 0,
          adjustment_total: 0,
          pre_tax_amount: 0,
          included_tax_total: 0,
        })

        Spree::ItemAdjustments.new(line_item).update
        line_item.save!
      end

      order.update_attributes!({
        additional_tax_total: 0,
        adjustment_total: 0,
        included_tax_total: 0,
      })

      Spree::OrderUpdater.new(order).update
      order.save!
    end
  end
end
