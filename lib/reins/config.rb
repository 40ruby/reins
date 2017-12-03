# coding: utf-8

# filename: config.rb
require 'logger'

module Reins
  class << self
    attr_accessor :logger, :auth_service, :regist_host, :port

    def configure
      yield self
    end
  end
end

Reins.configure do |config|
  config.logger       = Logger.new(ENV['REINS_LOGGER'] || "/tmp/reins.log")
  config.auth_service = Reins::AuthService.new(ENV['REINS_KEY'] || "106a6484291b9778c224731501d2deeb71f2b83558a0e9784fe33646f56182f69de448e92fe83fd4e57d629987f9d0dd79bf1cbca4e83b996e272ba44faa6adb")
  config.regist_host  = Reins::HostRegistry.new(ENV['REINS_DATABASE'] || "./40ruby.json")
  config.port         = ENV['REINS_PORT'] || 16_383
end

Reins.logger.level = ENV['REINS_LOGLEVEL'] ? eval("Logger::#{ENV['REINS_LOGLEVEL']}") : Logger::WARN
