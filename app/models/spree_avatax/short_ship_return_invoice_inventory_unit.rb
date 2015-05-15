class SpreeAvatax::ShortShipReturnInvoiceInventoryUnit < ActiveRecord::Base
  belongs_to(
    :short_ship_return_invoice,
    class_name: 'SpreeAvatax::ShortShipReturnInvoice',
    inverse_of: :short_ship_return_invoice_inventory_units,
  )
  belongs_to :inventory_unit, class_name: 'Spree::InventoryUnit'

  validates :short_ship_return_invoice, presence: true
  validates :inventory_unit, presence: true
end
