module SpreeAvatax::SalesShared
  ADDRESS_CODE = "1"
  DESTINATION_CODE = "1"
  ORIGIN_CODE = "1"

  SHIPPING_TAX_CODE = 'FR020100' # docs: http://goo.gl/KuIuxc

  SHIPPING_DESCRIPTION = 'Shipping Charge'

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

    def update_taxes(order, tax_line_data)
      reset_tax_attributes(order)

      tax_line_data.each do |data|
        record, tax_line = data[:record], data[:tax_line]

        record.update_column(:pre_tax_amount, record.discounted_amount)

        tax = BigDecimal.new(tax_line[:tax]).abs

        record.adjustments.tax.create!({
          adjustable: record,
          amount:     tax,
          order:      order,
          label:      Spree.t(:avatax_label),
          included:   false, # would be true for VAT
          source:     Spree::TaxRate.avatax_the_one_rate,
          state:      'closed', # this tells spree not to automatically recalculate avatax tax adjustments
        })

        Spree::ItemAdjustments.new(record).update
        record.save!
      end

      Spree::OrderUpdater.new(order).update
      order.save!
    end

    # returns an array like:
    # [
    #   {tax_line: {...}, record: #<Spree::LineItem id=111>},
    #   {tax_line: {...}, record: #<Spree::LineItem id=222>},
    #   {tax_line: {...}, record: #<Spree::Shipment id=111>},
    # ]
    def build_tax_line_data(order, avatax_result)
      # Array.wrap is required because the XML engine the Avatax gem uses turns child nodes into
      #   {...} instead of [{...}] when there is only one child.
      tax_lines = Array.wrap(avatax_result[:tax_lines][:tax_line])

      # builds a hash like: {"L-111": {record: #<Spree::LineItem ...>}, ...}
      data = (order.line_items + order.shipments).map { |r| [avatax_id(r), {record: r}] }.to_h

      # adds :tax_line to each entry in the data
      tax_lines.each do |tax_line|
        avatax_id = tax_line[:no]
        if data[avatax_id]
          data[avatax_id][:tax_line] = tax_line
        else
          raise InvalidApiResponse.new("Couldn't find #{avatax_id.inspect}")
        end
      end

      missing = data.select { |avatax_id, data| data[:tax_line].nil? }
      if missing.any?
        raise InvalidApiResponse.new("missing tax data for #{missing.keys}")
      end

      data.values
    end

    # sometimes we have to store different types of things in a single array (like line items and
    # shipments). this allows us to provide a unique identifier to each record.
    def avatax_id(record)
      "#{record.class.name}-#{record.id}"
    end

    private

    def logger
      SpreeAvatax::Shared.logger
    end

    # see https://github.com/avadev/AvaTax-Calc-SOAP-Ruby/blob/master/GetTaxTest.rb
    def gettax_params(order, doc_type)
      {
        doccode:       order.number,
        customercode:  REXML::Text.normalize(order.email),
        companycode:   SpreeAvatax::Config.company_code,

        doctype: doc_type,
        docdate: Date.today,

        commit: false, # we commit separately after the order completes

        # NOTE: we only want order-level adjustments here. not line item or shipping adjustments.
        #       avatax distributes order-level discounts across all "lineitem" entries that have
        #       "discounted:true"
        #       Also, the "discount" can be negative and Avatax handles that OK. A negative number
        #       would mean that *charges* were added to the order via an order-level adjustment.
        discount: order.avatax_order_adjustment_total.round(2).to_f,

        addresses: [
          {
            addresscode: ADDRESS_CODE,
            line1:       REXML::Text.normalize(order.ship_address.address1),
            line2:       REXML::Text.normalize(order.ship_address.address2),
            city:        REXML::Text.normalize(order.ship_address.city),
            postalcode:  REXML::Text.normalize(order.ship_address.zipcode),
          },
        ],

        lines: gettax_lines_params(order),
      }
    end

    def gettax_lines_params(order)
      line_items = order.line_items.includes(variant: :product)

      line_item_lines = line_items.map do |line_item|
        {
          # Required Parameters
          no:                  avatax_id(line_item),
          qty:                 line_item.quantity,
          amount:              line_item.discounted_amount.round(2).to_f,
          origincodeline:      ORIGIN_CODE,
          destinationcodeline: DESTINATION_CODE,

          # Best Practice Parameters
          description: REXML::Text.normalize(line_item.variant.product.description.to_s.truncate(100)),

          # Optional Parameters
          itemcode:   line_item.variant.sku,
          # "discounted" tells avatax to include this item when it distributes order-level discounts
          # across avatax "lines"
          discounted: order.avatax_order_adjustment_total != 0,
        }
      end

      shipment_lines = order.shipments.map do |shipment|
        {
          # Required Parameters
          no:                  avatax_id(shipment),
          qty:                 1,
          amount:              shipment.discounted_amount.round(2).to_f,
          origincodeline:      ORIGIN_CODE,
          destinationcodeline: DESTINATION_CODE,

          # Best Practice Parameters
          description: SHIPPING_DESCRIPTION,

          # Optional Parameters
          taxcode:    SHIPPING_TAX_CODE,
          # order-level discounts do not apply to shipments
          discounted: false,
        }
      end

      line_item_lines + shipment_lines
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
