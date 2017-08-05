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
  def start
    server = TCPServer.new(Reins.port)
    Reins.logger.info("Reins #{VERSION} を #{Reins.port} で起動しました")

    loop do
      begin
        Thread.start(server.accept) do |client|
          addr = IPAddr.new(client.peeraddr[3]).native.to_s
          keycode, command, options = client.gets.chomp.split
          Reins.logger.debug("addr = #{addr}, keycode = #{keycode}, command = #{command}, options = #{options}")

          if command == 'auth'
            Reins.logger.debug("#{addr} : 認証を行います")
            if (@keycode = Reins.auth_service.authenticate_key(keycode, addr))
              if @keycode == true
                client.puts Reins.regist_host.read_hostkeys[addr]
              else
                Reins.logger.debug("取得したキーコード : #{@keycode}")
                client.puts Reins.regist_host.create(addr, @keycode) ? @keycode : "NG: ホスト登録失敗"
              end
            else
              client.puts "NG: 認証ミス"
            end

          elsif Reins.auth_service.varid?(keycode) == addr
            Reins.logger.debug("#{command} : 実行します")
            @host = Reins::Dispatch.new(addr, keycode)

            client.puts @host.command(command, options)
          else
            Reins.logger.warn("#{command} : 実行できませんでした")
            client.puts "NG: コマンドが実行できませんでした"
          end

          client.close
        end
      rescue Interrupt => e
        Reins.logger.info(e.to_s)
        Reins.regist_host.store
        server.close
        exit
      end
    end
  end

  module_function :start
end
