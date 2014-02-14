require 'spec_helper'
require 'yaml'

##
# Live test to insure that the Avalara gem is working properly.
#

describe Avalara do
  before do
    # Load the credentials from an external file
    begin
      @avalara_config = YAML.load_file("#{File.dirname(__FILE__)}/avalara_config.yml")
      Avalara.password = @avalara_config['password']
      Avalara.username = @avalara_config['username']
      Avalara.endpoint = 'https://development.avalara.net/'
    rescue => e
      pending("PLEASE PROVIDE AVALARA CONFIGURATIONS TO RUN LIVE TESTS [#{e.to_s}]")
    end
  end

  describe 'geographical_tax' do
    it 'should get result' do
      result = Avalara.geographical_tax('47.627935', '-122.51702', 100)
      result.rate.should == 0
      result.tax.should == 0
    end
  end

  describe 'get_tax' do
    let(:line) do
      Avalara::Request::Line.new({
        line_no: "1",
        destination_code: "1",
        origin_code: "1",
        qty: "1",
        amount: 1000
      })
    end

    context 'with valid addresses' do
      it 'should get tax' do
        address = Avalara::Request::Address.new({
          address_code: 1,
          line_1: "2000 Broadway",
          postal_code: "10023"
        })

        invoice = Avalara::Request::Invoice.new({
          customer_code: 'mister.pants@bonobos.com',
          doc_date: Time.now,
          company_code: @avalara_config['company_code'],
          lines: [line],
          addresses: [address]
        })

        result = Avalara.get_tax(invoice)
        result.result_code.should == 'Success'
        result.total_amount.to_i.should == 1000
        result.total_tax.to_f.should == 88.75
        result.total_tax_calculated.to_f.should == 88.75
      end
    end

    context 'with invalid addresses' do
      it 'should raise error' do
        address = Avalara::Request::Address.new({
          address_code: 1,
          line_1: "Nowhere Land",
          postal_code: "XXXXX"
        })

        invoice = Avalara::Request::Invoice.new({
          customer_code: 'mister.pants@bonobos.com',
          doc_date: Time.now,
          company_code: @avalara_config['company_code'],
          lines: [line],
          addresses: [address]
        })

        lambda {
          Avalara.get_tax(invoice)
        }.should raise_error(Avalara::ApiError)
      end
    end
  end
end
