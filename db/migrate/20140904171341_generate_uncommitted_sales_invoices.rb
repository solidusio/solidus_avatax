class GenerateUncommittedSalesInvoices < ActiveRecord::Migration
  def up
    scope = Spree::Order.
      where(state: 'confirm').
      joins('left join spree_avatax_sales_invoices on spree_orders.id = spree_avatax_sales_invoices.order_id').
      where(:spree_avatax_sales_invoices => {id: nil}).
      readonly(false)

    say "Orders to migrate: #{scope.count}"

    # batch size of 1 to avoid grabbing stale rows
    scope.find_each(batch_size: 1) do |order|
      say "generating an uncommitted sales invoice for order id=#{order.id} number=#{order.number} created_at=#{order.created_at.to_s(:db).inspect}"

      begin
        SpreeAvatax::SalesInvoice.generate(order)
      rescue => e
        say ""
        say "************************ ERROR on Order #{order.number} ***************************"
        say "ERROR: #{e.class} #{e.message}"
        say e.backtrace.join("\n")
        say "***********************************************************************************"
        say ""
      end
    end
  end

  def down
    # not reversible
  end
end
