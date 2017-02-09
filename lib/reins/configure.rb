# coding: utf-8
require 'logger'

module Reins
  class << self
    attr_accessor :logger, :clients

    def configure
      yield self
    end
  end
end

Reins.configure do |config|
  config.logger  = Logger.new(ENV['REINS_LOGGER'] || "/tmp/reins.log")
  config.clients = Reins::DataManager.new(ENV['REINS_DATABASE'] || "./40ruby.csv")
end

Reins::logger.level = ENV['REINS_LOGLEVEL'] ? eval("Logger::#{ENV['REINS_LOGLEVEL']}") : Logger::WARN
