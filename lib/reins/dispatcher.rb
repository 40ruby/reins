# coding: utf-8

module Reins
  class Dispatch
    # 対象となるクライアントのIPアドレスを保持
    # == パラメータ
    # ip:: 対象となるクライアントのIPアドレス
    # == 返り値
    # 特になし
    def initialize(ip, key)
      @ip_address = ip
      @keycode    = key
    end

    # コマンドを受け取って、対象の機能へ振り分ける
    # == パラメータ
    # comm:: クライアントからの要求コマンド
    # value:: コマンドの実行に必要な引数
    # == 返り値
    # exception:: 失敗した場合
    # exception以外:: コマンドの実行結果
    def command(comm, value)
      case comm
      when /^(add|create).*/ then
        return true if Reins::regist_host.create(@ip_address, @key)
        false

      when /^list/ then
        Reins::regist_host.read_hosts

      when /^update/ then
        return true if Reins::regist_host.update(@ipaddress, value)
        false

      when /^delete/ then
        return Reins::regist_host.delete(@ipaddress)
      end
    end

  end
end
