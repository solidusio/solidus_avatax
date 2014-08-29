namespace :spree_avatax do

  desc <<-DESC
    Generate SalesInvoice records for all orders that have an avatax_invoice_at value.
    i.e. orders that were processed under the old REST system that used that field.
    Nullify the order's avatax_invoice_at field after generating the SalesInvoice record.
  DESC

  task backfill_sales_invoices: :environment do

    scope = Spree::Order.where.not(avatax_invoice_at: nil)

    # batch size of one to avoid stale data since these are slow iterations
    scope.find_each(batch_size: 1) do |order|
      puts "Processing order id=#{order.id} number=#{order.number} avatax_invoice_at=#{order.avatax_invoice_at.inspect}"

      history_request = {
        companycode: SpreeAvatax::Config.company_code,
        doctype:     'SalesInvoice',
        doccode:     order.number,
        detaillevel: 'Tax',
      }

      response = SpreeAvatax::Shared.tax_svc.gettaxhistory(history_request)

      if response[:result_code] != 'Success'
        raise "History request error on order id=#{order.id}: #{response[:messages]}"
      end

      get_tax_result = response[:get_tax_result]

      order.create_avatax_sales_invoice!({
        doc_id:                get_tax_result[:doc_id],
        doc_code:              get_tax_result[:doc_code],
        doc_date:              get_tax_result[:doc_date],
        pre_tax_total:         get_tax_result[:total_amount],
        additional_tax_total:  get_tax_result[:total_tax],
      })

      order.update_columns(avatax_invoice_at: nil)
    end
  end
end
