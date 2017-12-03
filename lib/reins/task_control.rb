# encoding: utf-8

# filename: task_control.rb
module Reins
  class TaskControl
    # クライアントとの接続
    # == パラメータ
    # hostname:: 接続先クライアントのホスト名、またはIPアドレス
    # port:: 接続先クライアントのTCPポート番号。通常は 24368
    # == 返り値
    # 接続された通信用のソケットオブジェクト
    def initialize(hostname = '127.0.0.1', port = 24_368)
      @s       = TCPSocket.open(hostname, port)
      @addr    = hostname
      @keycode = Reins.regist_host.read_hostkeys[@addr]
    rescue => e
      Reins.logger.error("#{e}: クライアントへの接続でエラーが発生しました")
      false
    end

    # クライアントとの死活確認
    # == パラメータ
    # 特になし
    # == 返り値
    # true:: 生存確認
    # false:: クライアントが停止、またはネットワーク上に問題あり
    def connect
      message = JSON.generate("keycode" => keycode.to_s, "command" => "watch")
      @s.puts(message)
      Reins.regist_host.set_status(@addr, @keycode, "dead") unless @s.gets == "OK"
    rescue => e
      Reins.logger.error("#{e}: クライアントへの接続でエラーが発生しました")
      Reins.regist_host.set_status(@addr, @keycode, "dead")
      false
    end

    # クライアントとの接続を切断
    # == パラメータ
    # 特になし
    # == 返り値
    # nil:: 正常に切断
    def disconnect
      @s.close
    end
  end
end
