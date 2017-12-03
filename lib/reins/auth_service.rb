# coding: utf-8
require 'digest/sha2'

module Reins
  class AuthService
    # サーバの認証キーを定義する
    # == パラメータ
    # secret_key:: SHA512 でハッシュ化されたキーを指定する
    # == 返り値
    # nil
    def initialize(secret_key = 'ac58c2bedf7c1d4e35136f2ca4f81acdece03fa9e90aeefa0d363488649c7f52d7064285923f814592d53c419f5c4db59ee1a867b4852d18e0fac6efd5874072')
      @secret_key = secret_key
      nil
    end

    # IPアドレスをキーにした専用のキーを発行する
    # == パラメータ
    # ipaddr:: IPアドレス
    # == 返り値
    # キー:: ハッシュ化された識別キー
    def create_key(ipaddr)
      Digest::SHA512.hexdigest("#{ipaddr}:#{Random.new_seed}")
    end

    # クライアント認証を行う
    # 接続元が要求してきたキーが、サーバ側で設定されているハッシュ値と比較する
    # == パラメータ
    # key:: ハッシュ化される前のキー
    # ipaddr:: 接続元のIPアドレス
    # == 返り値
    # キー:: 新規にホスト登録が必要なクライアントキーを発行
    # true:: 認証成功
    # false:: 認証不可 または、新規登録不可
    def authenticate_key(key, ipaddr)
      if @secret_key == Digest::SHA512.hexdigest(key)
        Reins.logger.info("#{ipaddr} : 認証が成功しました")
        if Reins.regist_host.read_hosts.include?(ipaddr)
          Reins.regist_host.read_hostkeys[ipaddr]
        else
          keycode = create_key(ipaddr)
          Reins.regist_host.create(ipaddr, keycode) ? keycode : false
        end
      else
        Reins.logger.fatal("#{ipaddr} : 認証が失敗しました")
        false
      end
    end

    # クライアントの識別を行う
    # 要求されたクライアント固有の識別キーが登録されているものか判断する
    # == パラメータ
    # key:: クライアント固有の識別キー
    # == 返り値
    # 識別された場合:: 登録されているIPアドレス
    # 否認された場合:: nil
    def varid?(keycode)
      Reins.regist_host.read_hostkeys.key(keycode)
    end
  end
end
