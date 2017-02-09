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
      expect(Reins::auth_service).not_to be nil
    end
    it "authenticatorのインスタンス化" do
      expect(Reins::regist_host).not_to be nil
    end
  end

# Auth Class のテスト
  describe "AuthService" do
    describe "#authenticate_key" do
      let(:sha512) { "106a6484291b9778c224731501d2deeb71f2b83558a0e9784fe33646f56182f69de448e92fe83fd4e57d629987f9d0dd79bf1cbca4e83b996e272ba44faa6adb" }
      let(:normal) { Reins::AuthService.new }
      let(:other)  { Reins::AuthService.new(sha512) }

      context "正常に認証された場合" do
        it { expect(normal.authenticate_key('DEMO', '192.168.0.10')).not_to eq(false) }
        it { expect(other.authenticate_key('40ruby', '192.168.0.10')).not_to eq(false) }
      end

      context "異なる認証キーで呼び出された場合" do
        it { expect(normal.authenticate_key('TEST', '192.168.0.10')).to eq(false) }
        it { expect(other.authenticate_key('DEMO', '192.168.0.10')).to eq(false) }
      end
    end

    describe "#is_varid" do
      let(:auth) { Reins::AuthService.new }
      let(:key)  { auth.authenticate_key('DEMO', '192.168.0.10') }

      context "登録済みのコードの場合" do
        it "接続認証キーで、該当のIPアドレスが返る" do
          allow(auth).to receive(:is_varid).and_return('192.168.0.10')
          expect(auth.is_varid(key)).to eq('192.168.0.10')
        end
      end
      context "未登録コードの場合" do
        it "nil" do
          expect(auth.is_varid(key)).to eq(nil)
        end
      end
    end
  end

# HostRegistry Class のテスト
  describe 'HostRegistry' do
    let(:regist_test)    { Reins::HostRegistry.new("test_db.csv") }
    let(:test_key)       { "TestKey" }
    let(:localhost)       { '127.0.0.1' }
    let(:correct_hosts)   { ['192.168.0.10','1.0.0.1','239.255.255.254'] }
    let(:incorrect_hosts) { ['100','[100,100]','1:0:0:1','1/0/0/1','0.0.0.1','1.0.0.0','0.0.0.0','240.0.0.1','240.255.255.254','0.256.0.1','0.0.256.1','239.255.255.255','-1.0.0.0','0.-1.0.0','0.0.-1.0','0.0.0.-1'] }

    before do
      allow(regist_test).to receive(:store).and_return(true)
    end

    describe '#create' do
      subject {regist_test.create(localhost, test_key) }
      it '同じIPを追加すると false' do
       regist_test.create(localhost, test_key)
        is_expected.to eq(false)
      end
    end

    describe '#read_hosts' do
      subject {regist_test.read_hosts }
      context '正常に登録されている場合' do
        it '未登録時に呼び出すと、空の配列' do
          is_expected.to eq([])
        end
        it 'localhost を1つ登録すると、[127.0.0.1]' do
         regist_test.create(localhost, test_key)
          is_expected.to eq([localhost])
        end
        it '複数のアドレスを登録した場合は、複数のアドレス' do
          correct_hosts.each   { |host|regist_test.create(host, test_key) }
          is_expected.to match_array(correct_hosts)
        end
      end
      context '不正なIPアドレスの場合' do
        it '有効範囲外のIPアドレスを登録しても登録されず、空の配列' do
          incorrect_hosts.each { |host|regist_test.create(host, test_key) }
          is_expected.to match_array([])
        end
      end
    end

    describe '#read_hostkeys' do
      it '登録しなければ、空' do
        expect(regist_test.hosts).to eq([])
        expect(regist_test.read_hostkeys).to eq({})
        expect(regist_test.read_hostkeys.size).to eq(0)
      end
      it 'ハッシュ化された接続キーの一覧' do
        correct_hosts.each   { |host|regist_test.create(host, test_key) }
        expect(regist_test.read_hostkeys.size).to eq(3)
      end
    end

    describe '#update' do
      before {regist_test.create(localhost, test_key) }
      it '有効なIPアドレスへ変更すると host が変更' do
        before_host = localhost
        correct_hosts.each do |host|
          expect {regist_test.update(before_host, host) }.to change {regist_test.read_hosts }.from([before_host]).to([host])
          before_host  = host
        end
      end
      it '有効範囲外のIPアドレスへ変更すると false' do
        incorrect_hosts.each do |host|
          expect(regist_test.update(localhost, host)).to eq(false)
        end
      end
      it '未登録のIPアドレスを指定すると false' do
        expect(regist_test.update('192.168.0.1','172.16.0.1')).to eq(false)
      end
      it 'すでに存在するIPアドレスへ変更すると false' do
        expect(regist_test.update('192.168.0.1',localhost)).to eq(false)
      end
    end

    describe '#delete' do
      before {regist_test.create("192.168.0.1", test_key)}
      subject {regist_test.delete(localhost) }
      context '正常に削除できる場合' do
        it '登録済みのアドレスを削除すると、そのアドレス' do
         regist_test.create(localhost, test_key)
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
