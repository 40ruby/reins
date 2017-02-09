# coding: utf-8
require "spec_helper"

RSpec.describe Reins do
  describe "定数/変数の設定" do
    it "Reins::VERSION の指定" do
      expect(Reins::VERSION).not_to be nil
    end
    it "logger の指定" do
      expect(Reins::logger).not_to be nil
    end
    it "data manager のインスタンス化" do
      expect(Reins::clients).not_to be nil
    end
  end

  describe "Auth" do
    describe "#authenticate" do
      let(:sha512) { "106a6484291b9778c224731501d2deeb71f2b83558a0e9784fe33646f56182f69de448e92fe83fd4e57d629987f9d0dd79bf1cbca4e83b996e272ba44faa6adb" }
      let(:normal) { Reins::Auth.new }
      let(:other)  { Reins::Auth.new(sha512) }

      context "正常に認証された場合" do
        it { expect(normal.authenticate('DEMO', '192.168.0.10')).not_to eq(false) }
        it { expect(other.authenticate('40ruby', '192.168.0.10')).not_to eq(false) }
      end

      context "異なる認証キーで呼び出された場合" do
        it { expect(normal.authenticate('TEST', '192.168.0.10')).to eq(false) }
        it { expect(other.authenticate('DEMO', '192.168.0.10')).to eq(false) }
      end
    end

    describe "#varid" do
      let(:auth) { Reins::Auth.new }
      let(:key)  { auth.authenticate('DEMO', '192.168.0.10') }

      context "登録済みのコードの場合" do
        it "接続認証キーで、該当のIPアドレスが返る" do
          allow(auth).to receive(:varid).and_return('192.168.0.10')
          expect(auth.varid(key)).to eq('192.168.0.10')
        end
      end
      context "未登録コードの場合" do
        it "空の配列が返る" do
          expect(auth.varid(key)).to eq([])
        end
      end
    end
  end

  describe 'DataManager' do
    let(:hosts)           { Reins::DataManager.new("test_db.csv") }
    let(:auth)            { Reins::Auth.new }
    let(:localhost)       { '127.0.0.1' }
    let(:correct_hosts)   { ['192.168.0.10','1.0.0.1','239.255.255.254'] }
    let(:correct_keyaddr) { [{"651dca3bac770bbaf7a77a9ef07aaf13"=>"192.168.0.10"}, {"07bec26cc01b80212c915a68e196bf07"=>"1.0.0.1"}, {"5d49a582d7f96dbda44c6d16dfd23c3c"=>"239.255.255.254"}] }
    let(:incorrect_hosts) { ['100','[100,100]','1:0:0:1','1/0/0/1','0.0.0.1','1.0.0.0','0.0.0.0','240.0.0.1','240.255.255.254','0.256.0.1','0.0.256.1','239.255.255.255','-1.0.0.0','0.-1.0.0','0.0.-1.0','0.0.0.-1'] }

    before do
      allow(hosts).to receive(:store).and_return(true)
    end

    describe '#create' do
      let(:key)  { auth.authenticate('DEMO', localhost) }
      subject { hosts.create(localhost, key) }
      it '同じIPを追加すると false' do
        hosts.create(localhost, key)
        is_expected.to eq(false)
      end
    end

    describe '#read_hosts' do
      subject { hosts.read_hosts }
      context '正常に登録されている場合' do
        it '未登録時に呼び出すと、空の配列' do
          is_expected.to eq([])
        end
        it 'localhost を1つ登録すると、[127.0.0.1]' do
          hosts.create(localhost, auth.authenticate('DEMO', localhost))
          is_expected.to eq([localhost])
        end
        it '複数のアドレスを登録した場合は、複数のアドレス' do
          correct_hosts.each   { |host| hosts.create(host, auth.authenticate('DEMO', host)) }
          is_expected.to match_array(correct_hosts)
        end
      end
      context '不正なIPアドレスの場合' do
        it '有効範囲外のIPアドレスを登録しても登録されず、空の配列' do
          incorrect_hosts.each { |host| hosts.create(host, auth.authenticate('DEMO', host)) }
          is_expected.to match_array([])
        end
      end
    end

    describe '#read_keyhosts' do
      it '登録しなければ、空の配列' do
        expect(hosts.addrs).to eq([])
        expect(hosts.read_keyhosts).to eq([])
        expect(hosts.read_keyhosts.size).to eq(0)
      end
      it 'ハッシュ化された接続キーの一覧' do
        correct_hosts.each   { |host| hosts.create(host, auth.authenticate('DEMO', host)) }
        expect(hosts.read_keyhosts.size).to eq(3)
      end
    end

    describe '#update' do
      before { hosts.create(localhost, auth.authenticate('DEMO', localhost)) }
      it '有効なIPアドレスへ変更すると host が変更' do
        before_host = localhost
        correct_hosts.each do |host|
          expect { hosts.update(before_host, host) }.to change { hosts.read_hosts }.from([before_host]).to([host])
          before_host  = host
        end
      end
      it '有効範囲外のIPアドレスへ変更すると false' do
        incorrect_hosts.each do |host|
          expect(hosts.update(localhost, host)).to eq(false)
        end
      end
      it '未登録のIPアドレスを指定すると false' do
        expect(hosts.update('192.168.0.1','172.16.0.1')).to eq(false)
      end
      it 'すでに存在するIPアドレスへ変更すると false' do
        expect(hosts.update('192.168.0.1',localhost)).to eq(false)
      end
    end

    describe '#delete' do
      before { hosts.create("192.168.0.1", auth.authenticate('DEMO', "192.168.0.1"))}
      subject { hosts.delete(localhost) }
      context '正常に削除できる場合' do
        it '登録済みのアドレスを削除すると、そのアドレス' do
          hosts.create(localhost, auth.authenticate('DEMO', localhost))
          is_expected.to eq(localhost)
        end
      end
      context '削除できない場合' do
        it '削除対象がなければ nil' do
          is_expected.to eq(nil)
        end
      end
    end
  end
end
