Spree::LineItem.class_eval do

  def taxable?
    product.tax_category.tax_rates.any?
  end
end
