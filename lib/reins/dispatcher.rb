# coding: utf-8

# filename: dispatcher.rb
module Reins
  class Dispatch
    # 対象となるクライアントのIPアドレスを保持
    # == パラメータ
    # ip:: 対象となるクライアントのIPアドレス
    # == 返り値
    # 特になし
    def initialize(addr, keycode)
      @addr    = addr
      @keycode = keycode
    end

    def varidate
      return true if Reins.regist_host.read_hostkeys[@addr] == @keycode

      Reins.logger.error("認可されていないコマンドです")
      false
    end

    # コマンドを受け取って、対象の機能へ振り分ける
    # == パラメータ
    # comm:: クライアントからの要求コマンド
    # value:: コマンドの実行に必要な引数
    # == 返り値
    # exception:: 失敗した場合
    # exception以外:: コマンドの実行結果
    def command(comm, value)
      Reins.logger.debug("#{comm}(#{value}) : 指定のコマンドへディスパッチします")
      return "false" unless varidate
      case comm
      when /^list/
        Reins.regist_host.read_hosts
      when /^delete/
        Reins.regist_host.delete(@addr)
      end
    end
  end
end
