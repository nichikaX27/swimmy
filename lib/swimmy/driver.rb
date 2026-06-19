module Swimmy
  module Driver
    dir = File.dirname(__FILE__) + "/driver"

    autoload :RaskCliDriver, "#{dir}/rask_cli_driver.rb"
  end
end
