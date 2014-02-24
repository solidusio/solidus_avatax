Spree Avatax
===========

This is an update to the original Spree Avatax gem (https://github.com/markalinn/Spree-Avatax) to work with Spree 2.1.x.

App Configuration
-----------------

Unlike the old gem which used a Rails installation generator, the new Avatax calculator can be integrated via the prescribed Spree 2.1.x method of adding to the calculators array in your configuration file, http://guides.spreecommerce.com/developer/calculators.html.

```
# inside config/initializers/spree.rb
config = Rails.application.config
config.spree.calculators.tax_rates << Spree::Calculator::Avatax
config.spree.calculators.shipping_methods << Spree::Calculator::Avatax
config.spree.calculators.promotion_actions_create_adjustments << Spree::Calculator::Avatax
```

You will also need to initialize a config object with your Avatax credentials as such:

```
SpreeAvatax::Config.username = 'YOUR USERNAME'
SpreeAvatax::Config.password = 'YOUR PASSWORD'
SpreeAvatax::Config.company_code = 'YOUR COMPANY'
SpreeAvatax::Config.endpoint = 'PROD OR DEV ENDPOINT'
SpreeAvatax::Config.suppress_api_errors = true/false
```

It is left to for you to decide how this gets set, either as an environment initializer or via a Spree preference.

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
