module Swimmy
  dir = File.dirname(__FILE__) + "/swimmy"

  autoload :App,                  "#{dir}/app.rb"
  autoload :Driver,               "#{dir}/driver.rb"
  autoload :Resource,             "#{dir}/resource.rb"
  autoload :Service,              "#{dir}/service.rb"
  autoload :VERSION,              "#{dir}/version.rb"

  require "#{dir}/command.rb"
end
