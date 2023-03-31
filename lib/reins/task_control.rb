# filename: task_control.rb
module Reins
  class TaskControl
    # クライアント定義
    # == パラメータ
    # hostname:: 接続先クライアントのホスト名、またはIPアドレス
    # port:: 接続先クライアントのTCPポート番号。通常は 24368
    # == 返り値
    # 特になし
    def initialize(hostname = '127.0.0.1', port = 24368)
      @addr    = hostname
      @port    = port
      @keycode = Reins.regist_host.read_hostkeys[@addr]
    end

    # クライアントとの接続
    # == パラメータ
    # 特になし
    # == 返り値
    # TCPScoket:: TCPのソケット情報
    def connection
      begin
        TCPSocket.open(@addr, @port)
      rescue => e
        Reins.logger.error("#{e}: クライアントへの接続でエラーが発生しました")
        dead
      end
    end

    # クライアントとの死活確認
    # == パラメータ
    # 特になし
    # == 返り値
    # true:: 生存確認
    # false:: クライアントが停止、またはネットワーク上に問題あり
    def viability(s)
      s.puts(JSON.generate("keycode" => @keycode.to_s, "command" => "watch"))
      raise unless s.gets.chomp == "OK"
      disconnect(s)
      alive
    rescue => e
      Reins.logger.error("#{e}: クライアントへの接続でエラーが発生しました")
      dead
    end

    # ステータスコードを「alive」に変更
    # == パラメータ
    # 特になし
    # == 返り値
    # true:: ステータスの変更に成功
    # false:: ステータスの変更に失敗
    def alive
      Reins.regist_host.set_status(@addr, @keycode, "alive") if Reins.regist_host.get_status(@addr, @keycode) == "dead"
    end

    # ステータスコードを「dead」に変更
    # == パラメータ
    # 特になし
    # == 返り値
    # true:: ステータスの変更に成功
    # false:: ステータスの変更に失敗
    def dead
      Reins.regist_host.set_status(@addr, @keycode, "dead") if Reins.regist_host.get_status(@addr, @keycode) == "alive"
    end

    # クライアントエージェントとの応答確認
    # == パラメータ
    # 特になし
    # == 返り値
    # 特になし
    def check_agent
      Reins.logger.debug("#{@addr} 宛にチェックを行います...")
      viability(connection)
    end

    # クライアントとの接続を切断
    # == パラメータ
    # 特になし
    # == 返り値
    # nil:: 正常に切断
    def disconnect(s)
      s.close
    end
  end
end
