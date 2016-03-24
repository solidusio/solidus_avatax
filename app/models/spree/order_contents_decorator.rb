Spree::OrderContents.class_eval do
  def add_with_avatax(*args)
    add_without_avatax(*args).tap do
      SpreeAvatax::SalesInvoice.reset_tax_attributes(order)
    end
  end

  def remove_with_avatax(*args)
    remove_without_avatax(*args).tap do
      SpreeAvatax::SalesInvoice.reset_tax_attributes(order)
    end
  end

  def update_cart_with_avatax(params)
    if update_cart_without_avatax(params)
      SpreeAvatax::SalesInvoice.reset_tax_attributes(order)
      true
    else
      false
    end
  end

  alias_method_chain :update_cart, :avatax
  alias_method_chain :add, :avatax
  alias_method_chain :remove, :avatax
end
