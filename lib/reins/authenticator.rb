# coding: utf-8
require "digest/md5"

module Reins
  class Auth
    # サーバの認証キーを定義する
    # == パラメータ
    # auth_code:: MD5 でハッシュ化されたキーを指定する
    # == 返り値
    # 特になし。@key_list 配列を初期化
    def initialize(auth_code = 'bd6dbd063f5ab7394879e3c08781cd72')
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
      auth_key   = Digest::MD5.hexdigest(key)

      unless @auth_code == auth_key
        Reins::logger.fatal("#{ip} : 認証が失敗しました")
        return false
      end

      Digest::MD5.hexdigest(auth_key+ip)
    end

    # クライアントの識別を行う
    # 要求されたクライアント固有の識別キーが登録されているものか判断する
    # == パラメータ
    # key:: クライアント固有の識別キー
    # == 返り値
    # 識別された場合:: 登録されているIPアドレス
    # 否認された場合:: []
    def varid(key)
      Reins::clients.read_keyhosts.each do |host|
        p host
        return host[key] if host.has_key?(key)
      end
    end
  end
end
