# A SalesOrder is not persisted on Avatax's end and is used to calculate tax before reaching the
#   "confirm" step.
# A Spree::Order may have many SpreeAvatax::SalesOrder records if it calculates tax many times.
# Generating a SpreeAvatax::SalesOrder record updates the taxes on the order and its line items.
class SpreeAvatax::SalesOrder < ActiveRecord::Base
  DOC_TYPE = 'SalesOrder'

  belongs_to :order, class_name: "Spree::Order", inverse_of: :avatax_sales_orders

  validates :order, presence: true
  validates :doc_code, presence: true
  validates :doc_date, presence: true

  class << self
    # Calls the Avatax API to generate a sales order and calculate taxes on the line items.
    # On failure it will raise.
    # On success it updates taxes on the order and its line items and create a SalesOrder record.
    #   At this point nothing is saved on Avatax's end.
    def generate(order)
      return if !SpreeAvatax::Shared.taxable_order?(order)

      result = SpreeAvatax::SalesShared.get_tax(order, DOC_TYPE)
      # run this immediately to ensure that everything matches up before modifying the database
      line_item_tax_lines = SpreeAvatax::SalesShared.match_line_items_to_tax_lines(order, result)

      sales_order = order.avatax_sales_orders.create!({
        transaction_id:        result[:transaction_id],
        doc_code:              result[:doc_code],
        doc_date:              result[:doc_date],
        pre_tax_total:         result[:total_amount],
        additional_tax_total:  result[:total_tax],
      })

      SpreeAvatax::SalesShared.update_taxes(order, line_item_tax_lines)

      sales_order
    rescue Exception => e
      SpreeAvatax::Config.error_handler ? SpreeAvatax::Config.error_handler.call(e) : raise
    end
  end
end
