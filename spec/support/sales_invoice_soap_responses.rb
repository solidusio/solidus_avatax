module SalesInvoiceSoapResponses
  def sales_invoice_gettax_response(doc_code, line_item, shipment, time = Time.now)
    {
      transaction_id: "4314427373575624",
      result_code: "Success",
      doc_id: "56879220",
      doc_type: "SalesInvoice",
      doc_code: doc_code,
      doc_date: time.to_date,
      doc_status: "Saved",
      reconciled: false,
      timestamp: time,
      total_amount: "110",
      total_discount: "0",
      total_exemption: "0",
      total_taxable: "110",
      total_tax: "9.77",
      total_tax_calculated: "9.77",
      hash_code: "0",
      tax_lines: {
        tax_line: [
          {
            no: SpreeAvatax::SalesShared.avatax_id(line_item),
            tax_code: "P0000000",
            taxability: true,
            boundary_level: "Zip5",
            exemption: "0",
            discount: "0",
            taxable: "10",
            rate: "0.088750",
            tax: "0.89",
            tax_calculated: "0.89",
            tax_included: false,
            tax_details: {
              tax_detail: [
                {
                  country: "US",
                  region: "NY",
                  juris_type: "State",
                  juris_code: "36",
                  tax_type: "Sales",
                  base: "10",
                  taxable: "10",
                  rate: "0.040000",
                  tax: "0.4",
                  tax_calculated: "0.4",
                  non_taxable: "0",
                  exemption: "0",
                  juris_name: "NEW YORK",
                  tax_name: "NY STATE TAX",
                  tax_authority_type: "45",
                  tax_group: nil,
                  rate_type: "G",
                  state_assigned_no: nil
                },
                {
                  country: "US",
                  region: "NY",
                  juris_type: "City",
                  juris_code: "51000",
                  tax_type: "Sales",
                  base: "10",
                  taxable: "10",
                  rate: "0.045000",
                  tax: "0.45",
                  tax_calculated: "0.45",
                  non_taxable: "0",
                  exemption: "0",
                  juris_name: "NEW YORK CITY",
                  tax_name: "NY CITY TAX",
                  tax_authority_type: "45",
                  tax_group: nil,
                  rate_type: "G",
                  state_assigned_no: "NE 8081"
                },
                {
                  country: "US",
                  region: "NY",
                  juris_type: "Special",
                  juris_code: "359071",
                  tax_type: "Sales",
                  base: "10",
                  taxable: "10",
                  rate: "0.003750",
                  tax: "0.04",
                  tax_calculated: "0.04",
                  non_taxable: "0",
                  exemption: "0",
                  juris_name: "METROPOLITAN COMMUTER TRANSPORTATION DISTRICT",
                  tax_name: "NY SPECIAL TAX",
                  tax_authority_type: "45",
                  tax_group: nil,
                  rate_type: "G",
                  state_assigned_no: "NE 8061"
                }
              ]
            },
            exempt_cert_id: "0",
            tax_date: time.to_date,
            reporting_date: time.to_date,
            accounting_method: "Accrual"
          },
          {
            no: SpreeAvatax::SalesShared.avatax_id(shipment),
            tax_code: "FR020100",
            taxability: true,
            boundary_level: "Zip5",
            exemption: "0",
            discount: "0",
            taxable: "100",
            rate: "0.088750",
            tax: "8.88",
            tax_calculated: "8.88",
            tax_included: false,
            tax_details: {
              tax_detail: [
                {
                  country: "US",
                  region: "NY",
                  juris_type: "State",
                  juris_code: "36",
                  tax_type: "Sales",
                  base: "100",
                  taxable: "100",
                  rate: "0.040000",
                  tax: "4",
                  tax_calculated: "4",
                  non_taxable: "0",
                  exemption: "0",
                  juris_name: "NEW YORK",
                  tax_name: "NY STATE TAX",
                  tax_authority_type: "45",
                  tax_group: nil,
                  rate_type: "G",
                  state_assigned_no: nil
                },
                {
                  country: "US",
                  region: "NY",
                  juris_type: "City",
                  juris_code: "51000",
                  tax_type: "Sales",
                  base: "100",
                  taxable: "100",
                  rate: "0.045000",
                  tax: "4.5",
                  tax_calculated: "4.5",
                  non_taxable: "0",
                  exemption: "0",
                  juris_name: "NEW YORK CITY",
                  tax_name: "NY CITY TAX",
                  tax_authority_type: "45",
                  tax_group: nil,
                  rate_type: "G",
                  state_assigned_no: "NE 8081"
                },
                {
                  country: "US",
                  region: "NY",
                  juris_type: "Special",
                  juris_code: "359071",
                  tax_type: "Sales",
                  base: "100",
                  taxable: "100",
                  rate: "0.003750",
                  tax: "0.38",
                  tax_calculated: "0.38",
                  non_taxable: "0",
                  exemption: "0",
                  juris_name: "METROPOLITAN COMMUTER TRANSPORTATION DISTRICT",
                  tax_name: "NY SPECIAL TAX",
                  tax_authority_type: "45",
                  tax_group: nil,
                  rate_type: "G",
                  state_assigned_no: "NE 8061"
                }
              ]
            },
            exempt_cert_id: "0",
            tax_date: time.to_date,
            reporting_date: time.to_date,
            accounting_method: "Accrual"
          }
        ]
      },
      tax_addresses: {
        tax_address: {
          address: "1234 Way",
          address_code: "1",
          boundary_level: "2",
          city: "New York",
          country: "US",
          postal_code: "10010",
          region: "NY",
          tax_region_id: "2088629",
          juris_code: "3600051000",
          latitude: nil,
          longitude: nil,
          geocode_type: "ZIP5Centroid",
          validate_status: "HouseNotOnStreet",
          distance_to_boundary: "0"
        }
      },
      locked: false,
      adjustment_reason: "0",
      adjustment_description: nil,
      version: "1",
      tax_date: time.to_date,
      tax_summary: nil,
      volatile_tax_rates: false,
      messages: [
        {
          summary: nil,
          details: nil,
          helplink: nil,
          refersto: nil,
          severity: nil,
          source: nil
        }
      ]
    }
  end

  def sales_invoice_posttax_response
    {
      transaction_id: "4314427475194657",
      result_code: "Success",
      doc_id: "56879220",
      messages:[
        {
          summary: nil,
          details: nil,
          helplink: nil,
          refersto: nil,
          severity: nil,
          source: nil,
        },
      ],
    }
  end

  def sales_invoice_canceltax_response
    {
      transaction_id: "4321919394664864",
      result_code: "Success",
      doc_id: "57305344",
      messages: [
        {
          summary:  nil,
          details:  nil,
          helplink: nil,
          refersto: nil,
          severity: nil,
          source:   nil,
        },
      ],
    }
  end
end
