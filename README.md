Spree Avatax
===========

[![Build Status](https://travis-ci.org/bonobos/spree_avatax.svg?branch=2-2-stable)](https://travis-ci.org/bonobos/spree_avatax)

This is an update to the original Spree Avatax gem (https://github.com/markalinn/Spree-Avatax) to work with Spree 2.2.x.

App Configuration
-----------------

Running `spree_avatax:install` (see "Installation") will generate [an initializer](https://github.com/bonobos/spree_avatax/blob/2-2-stable/lib/generators/spree_avatax/install/templates/config/initializers/avatax.rb) for your Rails app which you need to modify with your Avatax credentials.

Known Issues
------------

1. "Additional tax" (e.g. US taxes) *is* supported but "included tax" (e.g. VAT) is *not*.  This feature is not on the roadmap but we'd be willing to look at pull requests for it.
2. Returns/Refunds/Exchanges are not currently being sent to Avatax.  This is on the todo list and will be worked during or soon after the returns & exchanges refactor that we're working on with Spree for Spree 2.4.
3. Note for future development: There is currently a bug in Spree where the "open all adjustments" admin button doesn't work for line item adjustments. See [here](https://github.com/spree/spree/blob/v2.2.2/backend/app/controllers/spree/admin/orders_controller.rb#L103). If that bug were ever fixed, we'd want to monkey patch the controller action to prevent tax adjustments from ever being re-opened. We always want tax adjustments to be "closed", which tells Spree not to try to recalculate them automatically.

Admin Configuration
-------------------

Once Avatax is configured, you should be able to select Avatax as a calculator for all tax rules. This can be done in the Spree Admin, http://localhost:3000/admin/tax_rates/ and editing each existing rule.

Testing
-------

The app tries to follow the test setup recommended by Spree Extensions, http://guides.spreecommerce.com/developer/extensions_tutorial.html.

To test, you will need a test application, then you can run the tests.

```
bundle exec rake test_app
```

Run tests!

```
bundle exec rake spec
```

Live tests are provided to insure that the Avalara gem works as promised. The credentials must be provided under spec/live to run them successfully. See the example .yml for guidance.

```
username: 'USERNAME'
password: 'PASSWORD'
company_code: 'COMPANY'
```

These tests will communicate against the test Avatax API.

Installation
------------

Add spree_avatax to your Gemfile:

```ruby
gem 'spree_avatax'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_avatax:install
```

Copyright (c) 2014 [HoyaBoya], released under the New BSD License
