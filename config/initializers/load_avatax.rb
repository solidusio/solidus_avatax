require 'ostruct'

yaml = File.read(::Rails.root.to_s + "/config/avatax.yml")
config = YAML.load(yaml)[Rails.env]

SpreeAvatax::Config.username = config['username']
SpreeAvatax::Config.password = config['password']
SpreeAvatax::Config.company_code = config['company_code']
SpreeAvatax::Config.suppress_api_errors = true
