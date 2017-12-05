# coding: utf-8

# filename: lib/reins.rb

require "reins/version"
require "reins/dispatcher"
require "reins/auth_service"
require "reins/host_registry"
require "reins/task_control"
require "reins/config"

require "json"
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

    #
    def connect_client(server)
      Thread.start(server.accept) do |c|
        client = Reins::Clients.new(c)
        status = {}
        status["keycode"] = client.keycode
        status["result"]  = client.command == 'auth' ? client.run_auth : client.run_command
        c.puts JSON.pretty_generate(status)
        c.close
      end
    rescue Interrupt
      exit_server(server)
    end
  end

  class Clients
    attr_accessor :addr, :keycode, :command, :options

    def initialize(client)
      @message = JSON.parse(client.gets)
      Reins.logger.debug(@message)
      @addr    = IPAddr.new(client.peeraddr[3]).native.to_s
      @keycode = @message["keycode"]
      @command = @message["command"]
      @options = @message["options"]
    end

    # 認証処理を行う
    # == パラメータ
    # 特になし
    # == 返り値
    # key:: 認証が成功した場合は接続用の認証キーを返す
    # false:: 認証が失敗した時は "false" 文字列を返す
    def run_auth
      Reins.logger.debug("#{addr} : 認証を行います")
      if (key = Reins.auth_service.authenticate_key(keycode, addr))
        key
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
      Reins::Dispatch.new(addr, keycode).command(command, options)
    end
  end

  def start
    server = run_server(Reins.port)

    loop do
      connect_client(server)
    end
  end

  module_function :start
end
