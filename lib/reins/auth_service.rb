# coding: utf-8
require "digest/sha2"

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

    # クライアント認証を行う
    # 接続元が要求してきたキーが、サーバ側で設定されているハッシュ値と比較する
    # == パラメータ
    # key:: ハッシュ化される前のキー
    # ip:: 接続元のIPアドレス
    # == 返り値
    # 新規認証:: ハッシュ化されたクライアント固有識別の接続専用キー
    # IPアドレス登録済み:: true
    # 否認:: false
    def authenticate_key(key, ip)
      unless @secret_key == Digest::SHA512.hexdigest(key)
        Reins::logger.fatal("#{ip} : 認証が失敗しました")
        return false
      end

      unless Reins::regist_host.read_hosts.include?(ip)
        Reins::logger.info("#{ip} : 新たにホストを登録します")
        keycode = Digest::SHA512.hexdigest("#{ip}:#{Random.new_seed}")

        if Reins::regist_host.create(ip, keycode)
          return keycode
        end
        false
      else
        Reins::logger.info("#{ip} : 認証が成功しました")
        true
      end
    end

    # クライアントの識別を行う
    # 要求されたクライアント固有の識別キーが登録されているものか判断する
    # == パラメータ
    # key:: クライアント固有の識別キー
    # == 返り値
    # 識別された場合:: 登録されているIPアドレス
    # 否認された場合:: nil
    def is_varid(keycode)
      Reins::logger.debug("#{keycode} : クライアントの識別を行います")
      Reins::regist_host.read_hostkeys.key(keycode)
    end
  end
end
