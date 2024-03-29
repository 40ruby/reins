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
      @addr = hostname
      @port = port
      @keycode = Reins.regist_host.read_hostkeys[@addr]
    end

    # クライアントとの接続
    # == パラメータ
    # 特になし
    # == 返り値
    # TCPScoket:: TCPのソケット情報
    def connection
      begin
        @s = TCPSocket.open(@addr, @port)
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
    def viability
      connection
      @s.puts(JSON.generate("keycode" => @keycode.to_s, "command" => "watch"))
      raise unless @s.gets.chomp == "OK"
      alive
    rescue => e
      Reins.logger.error("#{e}: クライアントへの接続でエラーが発生しました")
      dead
    ensure
      disconnect
    end

    # ステータスコードを「alive」に変更
    # == パラメータ
    # 特になし
    # == 返り値
    # true:: ステータスの変更に成功
    # false:: ステータスの変更に失敗
    def alive
      if Reins.regist_host.get_status(@addr, @keycode) == "dead"
        Reins.regist_host.set_status(@addr, @keycode, "alive")
      end
    end

    # ステータスコードを「dead」に変更
    # == パラメータ
    # 特になし
    # == 返り値
    # true:: ステータスの変更に成功
    # false:: ステータスの変更に失敗
    def dead
      if Reins.regist_host.get_status(@addr, @keycode) == "alive"
        Reins.regist_host.set_status(@addr, @keycode, "dead")
      end
    end

    # クライアントエージェントとの応答確認
    # == パラメータ
    # 特になし
    # == 返り値
    # 特になし
    def check_agent
      Reins.logger.debug("#{@addr} 宛にチェックを行います...")
      viability
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
