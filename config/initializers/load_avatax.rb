require 'ostruct'

raw_config = File.read(::Rails.root.to_s + "/config/avatax.yml")
AvataxConfig = OpenStruct.new(YAML.load(raw_config)[Rails.env])
