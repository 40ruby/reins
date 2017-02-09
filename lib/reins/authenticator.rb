# coding: utf-8
# require "digest/md5"
require "digest/sha2"

module Reins
  class Auth
    # サーバの認証キーを定義する
    # == パラメータ
    # auth_code:: SHA512 でハッシュ化されたキーを指定する
    # == 返り値
    # 特になし。@key_list 配列を初期化
    def initialize(auth_code = 'ac58c2bedf7c1d4e35136f2ca4f81acdece03fa9e90aeefa0d363488649c7f52d7064285923f814592d53c419f5c4db59ee1a867b4852d18e0fac6efd5874072')
      @auth_code = auth_code
    end

    # クライアント認証を行う
    # 接続元が要求してきたキーが、サーバ側で設定されているハッシュ値と比較する
    # == パラメータ
    # key:: ハッシュ化される前のキー
    # ip:: 接続元のIPアドレス
    # == 返り値
    # 認証:: ハッシュ化されたクライアント固有の識別キー
    # 否認:: false
    def authenticate(key, ip)
      auth_key   = Digest::SHA512.hexdigest(key)

      unless @auth_code == auth_key
        Reins::logger.fatal("#{ip} : 認証が失敗しました")
        return false
      end

      Digest::SHA512.hexdigest(auth_key+ip)
    end

    # クライアントの識別を行う
    # 要求されたクライアント固有の識別キーが登録されているものか判断する
    # == パラメータ
    # key:: クライアント固有の識別キー
    # == 返り値
    # 識別された場合:: 登録されているIPアドレス
    # 否認された場合:: nil
    def varid(keycode)
      Reins::clients.read_keyhosts.key(keycode)
    end
  end
end
