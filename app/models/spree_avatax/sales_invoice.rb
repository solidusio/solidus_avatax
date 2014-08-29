# A SalesInvoice is persisted by Avatax but it's not recognized as complete until it's "committed".
class SpreeAvatax::SalesInvoice < ActiveRecord::Base
  DOC_TYPE = 'SalesInvoice'

  class CommitInvoiceNotFound < StandardError; end
  class AlreadyCommittedError < StandardError; end

  belongs_to :order, class_name: "Spree::Order"

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
      return if !SpreeAvatax::Shared.taxable_order?(order)

      result = SpreeAvatax::SalesShared.get_tax(order, DOC_TYPE)
      # run this immediately to ensure that everything matches up before modifying the database
      line_item_tax_lines = SpreeAvatax::SalesShared.match_line_items_to_tax_lines(order, result)

      if sales_invoice = order.avatax_sales_invoice
        if sales_invoice.committed_at.nil?
          sales_invoice.destroy
        else
          raise AlreadyCommittedError.new("Sales invoice #{sales_invoice.id} is already committed.")
        end
      end

      sales_invoice = order.create_avatax_sales_invoice!({
        doc_id:                result[:doc_id],
        doc_code:              result[:doc_code],
        doc_date:              result[:doc_date],
        pre_tax_total:         result[:total_amount],
        additional_tax_total:  result[:total_tax],
      })

      SpreeAvatax::SalesShared.update_taxes(order, line_item_tax_lines)

      sales_invoice
    rescue Exception => e
      SpreeAvatax::Config.error_handler ? SpreeAvatax::Config.error_handler.call(e) : raise
    end

    def commit(order)
      return if !SpreeAvatax::Shared.taxable_order?(order)

      raise CommitInvoiceNotFound if order.avatax_sales_invoice.nil?

      post_tax(order.avatax_sales_invoice)

      order.avatax_sales_invoice.update!(committed_at: Time.now)

      order.avatax_sales_invoice
    rescue Exception => e
      SpreeAvatax::Config.error_handler ? SpreeAvatax::Config.error_handler.call(e) : raise
    end

    private

    def post_tax(sales_invoice)
      params = posttax_params(sales_invoice)

      logger.info "[avatax] posttax sales_invoice=#{sales_invoice.id} order=#{sales_invoice.order_id}"
      logger.debug { "[avatax] params: #{params.to_json}" }

      response = SpreeAvatax::Shared.tax_svc.posttax(params)
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

  end
end
