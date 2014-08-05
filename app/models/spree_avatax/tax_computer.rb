class SpreeAvatax::TaxComputer
  DEFAULT_DOC_TYPE = 'SalesOrder'
  DEFAULT_STATUS_FIELD = :avatax_response_at

  class MissingTaxAmountError < StandardError; end

  attr_reader :order, :doc_type, :status_field

  def initialize(order, options = {})
    @doc_type     = options[:doc_type]     || DEFAULT_DOC_TYPE
    @status_field = options[:status_field] || DEFAULT_STATUS_FIELD

    @order = order
  end

  def compute
    return unless order.avataxable?

    reset_tax_attributes(order)

    tax_response = Avalara.get_tax(invoice_for_order)
    logger.debug(tax_response)

    order.line_items.each do |line_item|
      tax_amount = tax_response.tax_lines.detect { |tl| tl.line_no == line_item.id.to_s }.try(:tax_calculated)
      raise MissingTaxAmountError if tax_amount.nil?

      line_item.update_column(:pre_tax_amount, line_item.discounted_amount)

      line_item.adjustments.tax.create!({
        :adjustable => line_item,
        :amount => tax_amount,
        :order => @order,
        :label => Spree.t(:avatax_label),
        :included => false, # true for VAT
        :source => Spree::TaxRate.avatax_the_one_rate,
        :state => 'closed', # this tells spree not to automatically recalculate avatax tax adjustments
      })
      Spree::ItemAdjustments.new(line_item).update
      line_item.save!
    end

    Spree::OrderUpdater.new(order).update
    order[status_field] = Time.now
    order.save!
  rescue Avalara::ApiError, Avalara::TimeoutError, Avalara::Error => e
    handle_avalara_error(e)
  end

  ##
  # Need to clean out old taxes and update to prevent the 10 to 1 "Jordan" bug.
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

  def invoice_for_order
    SpreeAvatax::Invoice.new(order, doc_type, logger).invoice
  end

  def handle_avalara_error(e)
    logger.error(e)
    Honeybadger.notify(e) if defined?(Honeybadger)
    order.update_column(status_field, nil)
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/avatax.log")
  end
end
