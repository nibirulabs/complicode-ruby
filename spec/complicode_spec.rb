require 'spec_helper'

describe Complicode::Generate do
  describe '#call' do
    let(:authorization_code) { '29040011007' }
    let(:number) { '1503' }
    let(:nit_code) { '4189179011' }
    let(:issue_date) { '20070702' }
    let(:amount) { '2500' }
    let(:key) { '9rCB7Sv4X29d)5k7N%3ab89p-3(5[A' }

    it 'generates a control code for an invoice' do
      input = {
        authorization_code: authorization_code,
        number: number,
        nit_code: nit_code,
        issue_date: issue_date,
        amount: amount,
        key: key
      }
      output = Complicode::Generate.call(input)
      expect(output).to eq '6A-DC-53-05-14'
    end
  end
end
