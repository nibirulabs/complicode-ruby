# Complicode

Control code generator for invoices inside the Bolivian national tax service.

### Usage

```ruby
require 'complicode'

control_code = Complicode::Generate.call authorization_code: '29040011007',
                                         invoice_number: '1503',
                                         nit: '4189179011',
                                         issue_date: '20070702',
                                         amount: '2500',
                                         key: '9rCB7Sv4X29d)5k7N%3ab89p-3(5[A'

# If ignored, 'nit' defaults to '0'

control_code = Complicode::Generate.call authorization_code: '29040011007',
                                         invoice_number: '1503',
                                         issue_date: '20070702',
                                         amount: '2500',
                                         key: '9rCB7Sv4X29d)5k7N%3ab89p-3(5[A'
```
