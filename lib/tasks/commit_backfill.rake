require 'pp'

namespace :spree_avatax do

  desc <<-DESC
    Backfill all existing SalesInvoice records with Commit=true.
    The "start_id" and "end_id" parameters are order ids and are optional.
    Use this if you used spree_avatax prior to Commit=true being passed to Avatax.
    i.e. before this: https://github.com/bonobos/spree_avatax/pull/25
  DESC
  task(:commit_sales_invoices, [:start_id, :end_id] => :environment) do |t, args|

    puts 'Committing SalesInvoices for orders with an "avatax_invoice_at" value'

    # CONFIGURE OPTIONS

    scope = Spree::Order.where.not(avatax_invoice_at: nil)
    batch_options = {}

    if args[:start_id]
      batch_options[:start] = args[:start_id]
      puts "Beginning at order id #{args[:start_id]}"
    end

    if args[:end_id]
      scope = scope.where('spree_orders.id <= ?', args[:end_id])
      puts "Will stop at order id #{args[:end_id]}"
    end

    # PREP TO ITERATE OVER ORDERS

    tax_svc = AvaTax::TaxService.new({
      username:               SpreeAvatax::Config.username,
      password:               SpreeAvatax::Config.password,
      use_production_account: SpreeAvatax::Config.use_production_account,
      clientname:             'Spree::Avatax',
    })

    handle_result_errors = ->(result, order, request_method) do
      puts
      puts "** Error on order id=#{order.id} number=#{order.number} **"
      puts "Avatax #{request_method} result code: #{result[:result_code]}"
      puts 'messages:'
      pp result[:messages]
      puts
    end

    # ITERATE OVER ORDERS

    error_count = 0
    update_count = 0
    skip_count = 0

    scope.find_each(batch_options) do |order|
      puts "processing order id=#{order.id} number=#{order.number}"

      # CHECK CURRENT AVATAX STATUS

      history_request = {
        companycode: SpreeAvatax::Config.company_code,
        doctype:     'SalesInvoice',
        doccode:     order.number,
        detaillevel: 'Tax',
      }

      history_result = tax_svc.gettaxhistory(history_request)

      if history_result[:result_code] != 'Success'
        error_count += 1
        handle_result_errors.call(history_result, order, :gettaxhistory)
        next
      end

      if history_result[:get_tax_result][:doc_status] == 'Committed'
        skip_count += 1
        next # already committed. skip it.
      end

      # POST AND COMMIT

      post_request = {
        companycode: SpreeAvatax::Config.company_code,
        doctype:     'SalesInvoice',
        doccode:     order.number,

        commit:      true,

        docdate:     order.avatax_invoice_at.to_date,
        # sanity checks for avatax
        totalamount: history_result[:get_tax_result][:total_amount],
        totaltax:    history_result[:get_tax_result][:total_tax],
      }

      post_result = tax_svc.posttax(post_request)

      if post_result[:result_code] != 'Success'
        error_count += 1
        handle_result_errors.call(post_result, order, :posttax)
        next
      end

      update_count += 1
    end

    # PRINT RESULTS

    puts
    puts "Update complete."
    puts "Update count: #{update_count}. Skip count: #{skip_count}. Error count: #{error_count}."

    if error_count > 0
      puts
      puts '***********************************************'
      puts "* WARNING: #{error_count} errors encountered"
      puts '***********************************************'
    end
  end

end