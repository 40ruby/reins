# coding: utf-8

# filename: lib/reins.rb

require "reins/version"
require "reins/dispatcher"
require "reins/auth_service"
require "reins/host_registry"
require "reins/task_control"
require "reins/config"

require "socket"
require "ipaddr"

module Reins
  class << self
    def run_server(port)
      Reins.logger.info("Reins #{VERSION} を #{Reins.port} で起動します")
      @server = TCPServer.new(port)
    rescue => e
      Reins.logger.error("Reins が起動できませんでした: #{e}")
      exit
    end

    def define_value(client)
      @addr = IPAddr.new(client.peeraddr[3]).native.to_s
      @keycode, @command, @options = client.gets.chomp.split
      Reins.logger.debug("addr = #{@addr}, keycode = #{@keycode}, command = #{@command}, options = #{@options}")
    end

    def run_auth
      Reins.logger.debug("#{@addr} : 認証を行います")
      if (key = Reins.auth_service.authenticate_key(@keycode, @addr))
        if key == true
          Reins.regist_host.read_hostkeys[@addr]
        else
          Reins.regist_host.create(@addr, key) ? key : "false"
        end
      else
        false
      end
    end

    def run_command
      if Reins.auth_service.varid?(@keycode) == @addr
        Reins::Dispatch.new(@addr, @keycode).command(@command, @options)
      else
        "false"
      end
    end

    def exit_server
      Reins.logger.info("Reins #{VERSION} を終了します")
      Reins.regist_host.store
      @server.close
      exit
    end
  end

  def start
    run_server(Reins.port)

    loop do
      begin
        Thread.start(@server.accept) do |client|
          define_value(client)
          client.puts @command == 'auth' ? run_auth : run_command
          client.close
        end
      rescue Interrupt
        exit_server
      end
    end
  end

  module_function :start
end
