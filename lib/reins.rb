# coding: utf-8

# filename: lib/reins.rb

require "reins/version"
require "reins/dispatcher"
require "reins/auth_service"
require "reins/host_registry"
require "reins/task_control"
require "reins/config"

require "socket"

module Reins
  def start
    server = TCPServer.new(Reins.port)
    Reins.logger.info("Reins #{VERSION} を #{Reins.port} で起動しました")

    loop do
      begin
        Thread.start(server.accept) do |client|
          addr = client.peeraddr[3]
          keycode, command, options = client.gets.chomp.split

          if command == 'auth'
            Reins.logger.debug("#{addr} : 認証を行います")
            @keycode = Reins.auth_service.authenticate_key(keycode, addr)
            Reins.logger.debug("取得したキーコード : #{@keycode}")

            client.puts @keycode
          elsif Reins.auth_service.varid?(keycode) == addr
            Reins.logger.debug("#{command} : 実行します")
            @host = Reins::Dispatch.new(addr, keycode)

            client.puts @host.command(command, options)
          else
            client.puts false
          end
        end
      rescue Interrupt => e
        p e
        Reins.regist_host.store
        server.close
        exit
      end
    end
  end

  module_function :start
end
