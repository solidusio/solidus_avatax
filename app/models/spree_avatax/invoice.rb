class SpreeAvatax::Invoice
  ADDRESS_CODE = "1"
  DESTINATION_CODE = "1"
  ORIGIN_CODE = "1"

  attr_reader :order, :doc_type, :invoice, :logger

  def initialize(order, doc_type, logger = Logger.new(STDOUT))
    @doc_type = doc_type
    @order = order
    @logger = logger
    build_invoice
  end

  private

  def build_invoice
    invoice = Avalara::Request::Invoice.new(
      :customer_code => order.email, # TODO why are we sending the email here ?!? shouldnt this be an ID instead?
      :doc_date => Date.today,
      :doc_type => doc_type,
      :company_code => SpreeAvatax::Config.company_code,
      :discount => order.promotion_adjustment_total.round(2).to_f,
      :doc_code => order.number
    )
    invoice.addresses = build_invoice_addresses
    invoice.lines = build_invoice_lines
    logger.debug invoice.to_s
    @invoice = invoice
  end

  def build_invoice_addresses
    address = order.ship_address
    [Avalara::Request::Address.new(
      :address_code => ADDRESS_CODE,
      :line_1 => address.address1,
      :line_2 => address.address2,
      :city => address.city,
      :postal_code => address.zipcode
    )]
  end

  def build_invoice_lines
    order.line_items.map do |line_item|
      Avalara::Request::Line.new(
        :line_no => line_item.id,
        :destination_code => DESTINATION_CODE,
        :origin_code => ORIGIN_CODE,
        :qty => line_item.quantity,
        :amount => line_item.discounted_amount.round(2).to_f,
        :item_code => line_item.variant.sku,
        :discounted => order.promotion_adjustment_total > 0.0 # Continue to pass this field if we have an order-level discount so the line item gets discount calculated onto it
      )
    end
  end
end
