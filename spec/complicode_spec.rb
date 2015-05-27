require 'spec_helper'

describe Complicode::Generate do
  describe '#call' do
    let(:authorization_code) { '29040011007' }
    let(:invoice_number) { '1503' }
    let(:nit) { '4189179011' }
    let(:issue_date) { '20070702' }
    let(:amount) { '2500' }
    let(:key) { '9rCB7Sv4X29d)5k7N%3ab89p-3(5[A' }

    it 'generates a control code for an invoice' do
      input = {
        authorization_code: authorization_code,
        invoice_number: invoice_number,
        nit: nit,
        issue_date: issue_date,
        amount: amount,
        key: key
      }

      output = Complicode::Generate.call(input)
      expect(output).to eq '6A-DC-53-05-14'
    end

    it 'generates the correct control code for all 5000 test scenarios' do
      SmarterCSV.process('spec/fixtures/data.csv', col_sep: '|').each do |row|
        input = {
          authorization_code: row[:authorization_code],
          invoice_number: row[:invoice_number],
          nit: row[:nit],
          issue_date: row[:issue_date].delete('/'),
          amount: row[:amount].to_s.gsub(',', '.').to_f.round,
          key: row[:key]
        }

        output = Complicode::Generate.call(input)
        expect(output).to eq row[:control_code]
      end
    end

    it 'raises an ArgumentError exception' do
      input = {
        authorization_code: nil,
        invoice_number: nil,
        nit: nit,
        key: key
      }

      expect { Complicode::Generate.call(input) }.to raise_error(ArgumentError)
    end

    it 'does not raise an ArgumentError exception' do
      input = {
        authorization_code: authorization_code,
        invoice_number: invoice_number,
        issue_date: issue_date,
        amount: amount,
        key: key
      }

      expect { Complicode::Generate.call(input) }.not_to raise_error
    end
  end
end
