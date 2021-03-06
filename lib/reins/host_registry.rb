# coding: utf-8

# filename: host_registry.rb
require 'json'
require 'ipaddr'

module Reins
  class HostRegistry
    attr_reader :hosts

    # データベースの読込・初期化
    # ファイルが存在していれば内容を読込、なければファイルを新規に作成
    # == パラメータ
    # filename:: 読込・または保管先のファイル名
    # == 返り値
    # 特になし。但し、@hosts インスタンス変数へ、データベースの内容を保持
    def initialize(filename)
      @filename = filename
      File.open(@filename) do |file|
        @hosts = JSON.parse(file)
      end
    rescue
      @hosts = {}
    end

    # メモリ上のアドレスリストを、ファイルへ保管する
    # == パラメータ
    # filename:: 保管先ファイル名。指定がない場合は、初期化時に採用したファイル名
    def store(filename = @filename)
      Reins.logger.debug("#{filename} : ホスト一覧を保存します")
      File.open(filename, "w") do |file|
        file.puts(JSON.pretty_generate(@hosts))
      end
      true
    rescue
      Reins.logger.fatal("#{e}: データの保管に失敗しました")
      false
    end

    # 登録可能かどうかを検査する
    # == パラメータ
    # ipaddr:: 検査するIPアドレス
    # == 返り値
    # IPアドレス:: 登録可能な場合 IPアドレスを返す
    # false:: 登録不可
    def varid_ip?(ipaddr)
      addr = IPAddr.new(ipaddr).native.to_s
      @hosts.key?(addr) ? false : addr
    rescue => e
      Reins.logger.error("#{e}: #{ipaddr} は登録可能なIPアドレスではありません")
      false
    end

    # アドレスを新規に登録する。既に登録済みのものであれば登録しない。
    # == パラメータ
    # ipaddr:: 登録するIPアドレス
    # key:: 登録する IPアドレスをキーにした、接続用Keyをもつハッシュデータ
    # == 返り値
    # true::  登録できた
    # false:: 既に同じアドレスまたはIPアドレスではないため、登録せず
    def create(ipaddr, key)
      if (addr = varid_ip?(ipaddr))
        @hosts[addr] = {}
        @hosts[addr]["keycode"]      = key
        @hosts[addr]["created_date"] = @hosts[addr]["updated_date"] = Time.now.getlocal
        @hosts[addr]["status"]       = "alive"
        Reins.logger.info("#{addr} を追加しました")
        key if store
      else
        false
      end
    end

    # 登録されたステータスを変更する
    # == パラメータ
    # ipaddr:: 登録済みIPアドレス
    # key:: 登録する IPアドレスをキーにした、接続用Keyをもつハッシュデータ
    # status:: "alive" 稼働中, "dead" 異常発生し停止
    # == 返り値
    # "alive" or "dead"::  変更したホストのステータス
    # false:: 未登録ホストの場合、または Keyがまちがっている
    def get_status(ipaddr, key)
      @hosts[ipaddr]["keycode"] == key ? @hosts[ipaddr]["status"] : false
    rescue
      false
    end

    # 登録されたステータス情報を得る
    # == パラメータ
    # ipaddr:: 登録済みIPアドレス
    # key:: 登録する IPアドレスをキーにした、接続用Keyをもつハッシュデータ
    # == 返り値
    # "alive" or "dead"::  登録されているホストのステータス
    # false:: 未登録、または停止中、または Keyがまちがっている
    def set_status(ipaddr, key, status)
      if @hosts[ipaddr]["keycode"] == key
        @hosts[ipaddr]["status"]       = status
        @hosts[ipaddr]["updated_date"] = Time.now.getlocal
        store
        status
      else
        false
      end
    rescue
      false
    end

    # 登録済みホスト一覧を、IPアドレスをKey、接続KeyをValueとするハッシュで返す
    # == 返り値
    # hash: hash[ipアドレス] = key を一つの要素とする
    def read_hostkeys
      @hosts.each_key.map do |host|
        [host, @hosts[host]["keycode"]]
      end.to_h
    end

    # 登録済みホスト一覧を配列で返す
    # == 返り値
    # array: 登録済みのIPアドレス一覧
    def read_hosts
      @hosts.each_key.map { |host| host }
    end

    # 登録済みのアドレスを削除する
    # == パラメータ
    # addr: 削除対象のアドレス
    # == 返り値
    # string:: 削除された要素
    # nil::    削除すべき要素が見つからなかったとき
    def delete(addr)
      if @hosts.delete(addr)
        Reins.logger.info("#{addr} を削除しました.")
        store
        addr
      else
        Reins.logger.warn("#{addr} を削除できません.")
        nil
      end
    end

    # まだアドレスが登録されていないかどうか
    # == 返り値
    # true::  アドレス未登録
    # false:: 1つ以上のアドレスが登録済み
    def empty?
      @hosts.empty?
    end
  end
end
