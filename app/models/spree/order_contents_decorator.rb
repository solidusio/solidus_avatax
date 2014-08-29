Spree::OrderContents.class_eval do
  def add_with_avatax(variant, quantity = 1, currency = nil, shipment = nil)
    add_without_avatax(variant, quantity, currency, shipment).tap do
      SpreeAvatax::SalesOrder.generate(order)
    end
  end

  def remove_with_avatax(variant, quantity = 1, shipment = nil)
    remove_without_avatax(variant, quantity, shipment).tap do
      SpreeAvatax::SalesOrder.generate(order)
    end
  end

  def update_cart_with_avatax(params)
    if update_cart_without_avatax(params)
      SpreeAvatax::SalesOrder.generate(order)
      true
    else
      false
    end
  end

  alias_method_chain :update_cart, :avatax
  alias_method_chain :add, :avatax
  alias_method_chain :remove, :avatax
end
