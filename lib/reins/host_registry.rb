# coding: utf-8
require 'csv'

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
      @hosts    =  File.exists?(@filename) ? CSV.read(@filename) : []
    end

    # IPアドレスのチェック
    # IPアドレスとおぼしき文字列を検査し、IPアドレスっぽいかどうかを調査
    # == パラメータ
    # ip:: チェックしたいIPアドレス文字列
    # == 返り値
    # true:: IPアドレスと思われる場合
    # false:: IPアドレスではないと思われる場合

    def check_ip(ip)
      Reins::logger.debug("#{ip} : アドレスチェックを行います")
      # 引数は文字列のみを受け付けることとする
      return false unless ip.is_a?(String)

      # 正規表現で、各数値を入手
      /^([0-9]*)\.([0-9]*)\.([0-9]*)\.([0-9]*)$/ =~ ip

      return false unless (1..239).cover?($1.to_i)
      return false unless (0..255).cover?($2.to_i)
      return false unless (0..255).cover?($3.to_i)
      return false unless (1..254).cover?($4.to_i)

      Reins::logger.debug("#{ip} : アドレスに問題がありませんでした")
      return true
    end

    # メモリ上のアドレスリストを、ファイルへ保管する
    # == パラメータ
    # filename:: 保管先ファイル名。指定がない場合は、初期化時に採用したファイル名
    def store(filename = @filename)
      Reins::logger.debug("#{filename} : ホスト一覧を保存します")
      CSV.open(filename, "w") do |csv|
        @hosts.each do |addr|
          Reins::logger.debug("保管中... > #{addr}")
          csv << addr
        end
      end
    end

    # アドレスを新規に登録する。既に登録済みのものであれば登録しない。
    # == パラメータ
    # keyaddr:: 登録する IPアドレスをキーにした、接続用Keyをもつハッシュデータ
    # == 返り値
    # true::  登録できた
    # false:: 既に同じアドレスまたはIPアドレスではないため、登録せず
    def create(addr, key)
      Reins.logger.debug("#{addr} : ホスト登録処理を行います")
      if check_ip(addr) then
        unless read_hosts.include?(addr) then
          @hosts << [addr, key, Time.now]
          Reins::logger.info("#{addr} を追加しました")
          store
          return true
        else
          Reins::logger.error("#{addr} は既に登録されています.")
        end
      else
        Reins::logger.error("#{addr} は登録可能なIPアドレスではありません.")
        false
      end
      false
    end

    # 登録済みホスト一覧を、IPアドレスをKey、接続KeyをValueとするハッシュで返す
    # == 返り値
    # hash: hash[ipアドレス] = key を一つの要素とする
    def read_hostkeys
      @hosts.each.map { |addr, key| [addr, key] }.to_h
    end

    # 登録済みホスト一覧を配列で返す
    # == 返り値
    # array: 登録済みのIPアドレス一覧
    def read_hosts
      read_hostkeys.keys
    end

    # 登録済みのアドレスを、他のアドレスへ変更する
    # ただし、変更後のアドレスが既に登録されている場合や、登録済みアドレスが見つからない場合はエラーを返す
    # == パラメータ
    # before:: 既に登録済みのアドレス
    # after::  変更後のアドレス
    def update(before, after)
      if read_hosts.include?(after) || !check_ip(after)
        Reins::logger.error("#{after} は既に登録済みか、有効なIPアドレスではありません.")
        return false
      elsif i = read_hosts.index(before)
        @hosts[i][0] = after
        Reins::logger.info("#{before} から #{after} へ変更しました.")
        return true
      else
        Reins::logger.error("変更元の #{before} が見つかりません.")
        return false
      end
    end

    # 登録済みのアドレスを削除する
    # == パラメータ
    # addr: 削除対象のアドレス
    # == 返り値
    # string:: 削除された要素
    # nil::    削除すべき要素が見つからなかったとき
    def delete(addr)
      if i = read_hosts.index(addr)
        @hosts.delete_at(i)
        Reins::logger.info("#{addr} を削除しました.")
        store
        return addr
      else
        Reins::logger.warn("#{addr} が見つかりません.")
        return nil
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
