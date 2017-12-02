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
    # 指定されたポートでサーバを起動する
    # == パラメータ
    # port:: 割り当てるポート番号
    # == 返り値
    # Exception:: サーバが起動できなかった場合、例外を発生させ起動させない
    # TCPSocket:: 正常に起動した場合、Socket オブジェクトを返す
    def run_server(port)
      Reins.logger.info("Reins #{VERSION} を #{port} で起動します")
      TCPServer.new(port)
    rescue => e
      Reins.logger.error("Reins が起動できませんでした: #{e}")
      puts(e.to_s)
      exit
    end

    # 起動されているサーバを停止する
    # == パラメータ
    # server:: 起動中のサーバの Socket
    # == 返り値
    # 特になし
    def exit_server(server)
      Reins.logger.info("Reins #{VERSION} を終了します")
      Reins.regist_host.store
      server.close
      exit
    end
  end

  class Clients
    attr_reader :command
    def initialize(client)
      @keycode, @command, @options = client.gets.chomp.split
      @addr = IPAddr.new(client.peeraddr[3]).native.to_s
      Reins.logger.debug("addr = #{@addr}, keycode = #{@keycode}, command = #{@command}, options = #{@options}")
    end

    # 認証処理を行う
    # == パラメータ
    # 特になし
    # == 返り値
    # key:: 認証が成功した場合は接続用の認証キーを返す
    # false:: 認証が失敗した時は "false" 文字列を返す
    def run_auth
      Reins.logger.debug("#{@addr} : 認証を行います")
      if (key = Reins.auth_service.authenticate_key(@keycode, @addr))
        if key == true
          Reins.regist_host.read_hostkeys[@addr]
        else
          Reins.regist_host.create(@addr, key) ? key : "false"
        end
      else
        "false"
      end
    end

    # サーバで実行されるコマンドを受け渡す
    # == パラメータ
    # 特になし
    # == 返り値
    # false:: 実行できなければ "false" 文字列を返す
    # false以外:: 実行された結果を、改行を含む文字列で返す
    def run_command
      if Reins.auth_service.varid?(@keycode) == @addr
        Reins::Dispatch.new(@addr, @keycode).command(@command, @options)
      else
        "false"
      end
    end
  end

  def start
    server = run_server(Reins.port)

    loop do
      begin
        Thread.start(server.accept) do |c|
          client = Reins::Clients.new(c)
          c.puts client.command == 'auth' ? client.run_auth : client.run_command
          c.close
        end
      rescue Interrupt
        exit_server(server)
      end
    end
  end

  module_function :start
end
