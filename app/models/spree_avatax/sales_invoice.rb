# A SalesInvoice is persisted by Avatax but it's not recognized as complete until it's "committed".
class SpreeAvatax::SalesInvoice < ActiveRecord::Base
  DOC_TYPE = 'SalesInvoice'
  CANCEL_CODE = 'DocVoided'

  DESTINATION_CODE = "1"
  SHIPPING_TAX_CODE = 'FR020100'
  SHIPPING_DESCRIPTION = 'Shipping Charge'

  class CommitInvoiceNotFound < StandardError; end
  class AlreadyCommittedError < StandardError; end
  class InvalidApiResponse < StandardError; end

  belongs_to :order, class_name: "Spree::Order", inverse_of: :avatax_sales_invoice

  validates :order, presence: true
  validates :doc_id, presence: true
  validates :doc_code, presence: true
  validates :doc_date, presence: true

  class << self
    # Calls the Avatax API to generate a sales invoice and calculate taxes on the line items.
    # On failure it will raise.
    # On success it updates taxes on the order and its line items and create a SalesInvoice record.
    #   At this point the record is saved but uncommitted on Avatax's end.
    # After the order completes the ".commit" method will get called and we'll commit the
    #   sales invoice, which marks it as complete on Avatax's end.
    def generate(order)
      bench_start = Time.now

      if !SpreeAvatax::Config.enabled
        logger.info("Avatax disabled. Skipping SalesInvoice.generate for order #{order.number}")
        return
      end

      return if order.completed? || !SpreeAvatax::Shared.taxable_order?(order)

      result = get_tax(order, DOC_TYPE)
      # run this immediately to ensure that everything matches up before modifying the database
      tax_line_data = build_tax_line_data(order, result)

      if sales_invoice = order.avatax_sales_invoice
        if sales_invoice.committed_at.nil?
          sales_invoice.destroy
        else
          raise AlreadyCommittedError.new("Sales invoice #{sales_invoice.id} is already committed.")
        end
      end

      update_taxes(order, tax_line_data)

      sales_invoice = order.create_avatax_sales_invoice!({
        transaction_id:        result[:transaction_id],
        doc_id:                result[:doc_id],
        doc_code:              result[:doc_code],
        doc_date:              result[:doc_date],
        pre_tax_total:         result[:total_amount],
        additional_tax_total:  result[:total_tax],
      })

      sales_invoice
    rescue Exception => e
      if SpreeAvatax::Config.sales_invoice_generate_error_handler
        SpreeAvatax::Config.sales_invoice_generate_error_handler.call(order, e)
      else
        raise
      end
    ensure
      duration = (Time.now - bench_start).round
      Rails.logger.info "avatax_sales_invoice_generate_duration=#{(duration*1000).round}"
    end

    def commit(order)
      if !SpreeAvatax::Config.enabled
        logger.info("Avatax disabled. Skipping SalesInvoice.commit for order #{order.number}")
        return
      end

      return if !SpreeAvatax::Shared.taxable_order?(order)

      raise CommitInvoiceNotFound.new("No invoice for order #{order.number}") if order.avatax_sales_invoice.nil?

      post_tax(order.avatax_sales_invoice)

      order.avatax_sales_invoice.update!(committed_at: Time.now)

      order.avatax_sales_invoice
    rescue Exception => e
      if SpreeAvatax::Config.sales_invoice_commit_error_handler
        SpreeAvatax::Config.sales_invoice_commit_error_handler.call(order, e)
      else
        raise
      end
    end

    def cancel(order)
      if !SpreeAvatax::Config.enabled
        logger.info("Avatax disabled. Skipping SalesInvoice.cancel for order #{order.number}")
        return
      end

      return if order.avatax_sales_invoice.nil?

      result = cancel_tax(order.avatax_sales_invoice)

      order.avatax_sales_invoice.update!({
        canceled_at:           Time.now,
        cancel_transaction_id: result[:transaction_id],
      })
    rescue Exception => e
      if SpreeAvatax::Config.sales_invoice_cancel_error_handler
        SpreeAvatax::Config.sales_invoice_cancel_error_handler.call(order, e)
      else
        raise
      end
    end

    # Clears previously-set tax attributes from an order, if any, unless the
    # order has already been completed.
    #
    # @api private
    # @param order [Spree::Order] the order
    def reset_tax_attributes(order)
      return if order.completed?

      # Delete the avatax_sales_invoice to avoid accidentally committing it
      # later.
      if invoice = order.avatax_sales_invoice
        if invoice.committed_at
          raise SpreeAvatax::SalesInvoice::AlreadyCommittedError.new(
            "Tried to clear tax attributes for already-committed order #{order.number}"
          )
        else
          invoice.destroy!
        end
      end

      destroyed_adjustments = order.all_adjustments.tax.destroy_all
      return if destroyed_adjustments.empty?

      taxable_records = order.line_items + order.shipments
      taxable_records.each do |taxable_record|
        taxable_record.update_attributes!({
          additional_tax_total: 0,
          adjustment_total: 0,
          included_tax_total: 0,
        })

        Spree::ItemAdjustments.new(taxable_record).update
        taxable_record.save!
      end

      order.update_attributes!({
        additional_tax_total: 0,
        adjustment_total: 0,
        included_tax_total: 0,
      })

      order.update!
      order.save!
    end

    # sometimes we have to store different types of things in a single array (like line items and
    # shipments). this allows us to provide a unique identifier to each record.
    # @api private
    def avatax_id(record)
      "#{record.class.name}-#{record.id}"
    end

    private

    # Queries Avatax for taxes on a specific order using the specified doc_type.
    # SalesOrder doc types are not persisted on Avatax.
    # SalesInvoice doc types do persist an uncommitted record on Avatax.
    def get_tax(order, doc_type)
      params = gettax_params(order, doc_type)

      logger.info "[avatax] gettax order=#{order.id} doc_type=#{doc_type}"
      logger.debug { "[avatax] params: #{params.to_json}" }

      response = SpreeAvatax::Shared.get_tax(params)

      SpreeAvatax::Shared.require_success!(response)

      response
    end

    def update_taxes(order, tax_line_data)
      reset_tax_attributes(order)

      tax_line_data.each do |data|
        record, tax_line = data[:record], data[:tax_line]

        tax = BigDecimal.new(tax_line[:tax]).abs

        record.adjustments.tax.create!({
          adjustable: record,
          amount:     tax,
          order:      order,
          label:      Spree.t(:avatax_label),
          included:   false, # would be true for VAT
          source:     Spree::TaxRate.avatax_the_one_rate,
          finalized:  true, # this tells spree not to automatically recalculate avatax tax adjustments
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
          raise InvalidApiResponse.new("Couldn't find #{avatax_id.inspect} from avatax response in known ids #{data.keys.inspect}")
        end
      end

      missing = data.select { |avatax_id, data| data[:tax_line].nil? }
      if missing.any?
        raise InvalidApiResponse.new("missing tax data for #{missing.keys}")
      end

      data.values
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
            addresscode: DESTINATION_CODE,
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
          origincodeline:      DESTINATION_CODE, # We don't really send the correct value here
          destinationcodeline: DESTINATION_CODE,

          # Best Practice Parameters
          description: REXML::Text.normalize(line_item.variant.product.description.to_s.truncate(100)),

          # Optional Parameters
          itemcode:   line_item.variant.sku,
          taxcode:    line_item.tax_category.tax_code,
          # "discounted" tells avatax to include this item when it distributes order-level discounts
          # across avatax "lines"
          discounted: true,
        }
      end

      shipment_lines = order.shipments.map do |shipment|
        {
          # Required Parameters
          no:                  avatax_id(shipment),
          qty:                 1,
          amount:              shipment.discounted_amount.round(2).to_f,
          origincodeline:      DESTINATION_CODE, # We don't really send the correct value here
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

    def post_tax(sales_invoice)
      params = posttax_params(sales_invoice)

      logger.info "[avatax] posttax sales_invoice=#{sales_invoice.id} order=#{sales_invoice.order_id}"
      logger.debug { "[avatax] params: #{params.to_json}" }

      response = SpreeAvatax::Shared.post_tax(params)
      SpreeAvatax::Shared.require_success!(response)

      response
    end

    def cancel_tax(sales_invoice)
      params = canceltax_params(sales_invoice)

      logger.info "[avatax] canceltax sales_invoice=#{sales_invoice.id}"
      logger.debug { "[avatax] params: #{params.to_json}" }

      response = SpreeAvatax::Shared.cancel_tax(params)
      SpreeAvatax::Shared.require_success!(response)

      response
    end

    # see https://github.com/avadev/AvaTax-Calc-SOAP-Ruby/blob/master/PostTaxTest.rb
    def posttax_params(sales_invoice)
      {
        doccode:     sales_invoice.doc_code,
        companycode: SpreeAvatax::Config.company_code,

        doctype: DOC_TYPE,
        docdate: sales_invoice.doc_date,

        commit: true,

        totalamount: sales_invoice.pre_tax_total,
        totaltax:    sales_invoice.additional_tax_total,
      }
    end

    # see https://github.com/avadev/AvaTax-Calc-SOAP-Ruby/blob/master/CancelTaxTest.rb
    def canceltax_params(sales_invoice)
      {
        # Required Parameters
        doccode:     sales_invoice.doc_code,
        doctype:     DOC_TYPE,
        cancelcode:  CANCEL_CODE,
        companycode: SpreeAvatax::Config.company_code,
      }
    end
  end
end
