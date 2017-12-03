# coding: utf-8

# filename: reins_spec.rb
require "spec_helper"
require "socket"

RSpec.describe Reins do
  describe "定数/変数の設定" do
    it { expect(Reins::VERSION).not_to be nil }
    it { expect(Reins.port).not_to be nil }
    it { expect(Reins.logger).not_to be nil }
    it { expect(Reins.auth_service).not_to be nil }
    it { expect(Reins.regist_host).not_to be nil }
  end

  # AuthService class のテスト
  describe "AuthService" do
    describe "#authenticate_key" do
      let(:sha512) { "106a6484291b9778c224731501d2deeb71f2b83558a0e9784fe33646f56182f69de448e92fe83fd4e57d629987f9d0dd79bf1cbca4e83b996e272ba44faa6adb" }
      let(:normal) { Reins::AuthService.new }
      let(:other)  { Reins::AuthService.new(sha512) }
      before do
        allow(Reins.regist_host).to receive(:store).and_return(true)
      end

      context "ハッシュキーを作成する場合" do
        it { expect(normal.create_key('192.168.0.10')).to match(/[0-9a-f]{128}/) }
      end

      context "正常に認証された場合" do
        it { expect(normal.authenticate_key('DEMO', '192.168.0.10')).not_to eq(false) }
        it { expect(other.authenticate_key('40ruby', '192.168.0.10')).not_to eq(false) }
      end

      context "異なる認証キーで呼び出された場合" do
        it { expect(normal.authenticate_key('TEST', '192.168.0.10')).to eq(false) }
        it { expect(other.authenticate_key('DEMO', '192.168.0.10')).to eq(false) }
      end
    end

    describe "#varid?" do
      let(:auth) { Reins::AuthService.new }
      let(:key)  { auth.authenticate_key('DEMO', '192.168.0.10') }

      it { expect(auth.varid?(key)).to eq('192.168.0.10') }
    end
  end

  # HostRegistry Class のテスト
  describe 'HostRegistry' do
    let(:regist_test)    { Reins::HostRegistry.new("test_db.json") }
    let(:test_key)       { "TestKey" }
    let(:localhost)       { '127.0.0.1' }
    let(:correct_hosts)   { ['192.168.0.10', '1.0.0.1', '239.255.255.254'] }

    before do
      allow(regist_test).to receive(:store).and_return(true)
    end

    describe '#create' do
      subject { regist_test.create(localhost, test_key) }
      before do
        regist_test.create(localhost, test_key)
      end
      it { is_expected.to eq(false) }
    end

    describe '#get_status' do
      subject { regist_test.get_status(localhost, test_key) }
      before do
        regist_test.create(localhost, test_key)
      end
      context '登録直後の場合' do
        it { is_expected.to eq("alive") }
      end
      context 'ステータスを"alive"へ変更した場合' do
        it '#set_status で "alive" をセット' do
          regist_test.set_status(localhost, test_key, "alive")
          is_expected.to eq("alive")
        end
      end
      context 'ステータスが"dead"の場合' do
        it '#set_status で "dead" をセット' do
          regist_test.set_status(localhost, test_key, "dead")
          is_expected.to eq("dead")
        end
      end
      context '未登録のホストの場合' do
        it '登録していないホストのステータスを確認するとfalse' do
          expect(regist_test.get_status("192.168.0.10", test_key)).to eq(false)
        end
        it '未登録のホストステータスを変更するとfalse' do
          expect(regist_test.set_status("192.168.0.10", test_key, "alive")).to eq(false)
          expect(regist_test.get_status("192.168.0.10", test_key)).to eq(false)
        end
      end
    end

    describe '#read_hosts' do
      subject { regist_test.read_hosts }
      context '正常に登録されている場合' do
        it { is_expected.to eq([]) }
        it 'localhost を1つ登録すると、[127.0.0.1]' do
          regist_test.create(localhost, test_key)
          is_expected.to eq([localhost])
        end
        it '複数のアドレスを登録した場合は、複数のアドレス' do
          correct_hosts.each { |host| regist_test.create(host, test_key) }
          is_expected.to match_array(correct_hosts)
        end
      end
    end

    describe '#read_hostkeys' do
      it '登録しなければ、空' do
        expect(regist_test.hosts).to eq({})
        expect(regist_test.read_hostkeys).to eq({})
        expect(regist_test.read_hostkeys.size).to eq(0)
      end
      it 'ハッシュ化された接続キーの一覧' do
        correct_hosts.each { |host| regist_test.create(host, test_key) }
        expect(regist_test.read_hostkeys.size).to eq(3)
      end
    end

    describe '#delete' do
      before { regist_test.create("192.168.0.1", test_key) }
      subject { regist_test.delete(localhost) }
      context '正常に削除できる場合' do
        it '登録済みのアドレスを削除すると、そのアドレス' do
          regist_test.create(localhost, test_key)
          is_expected.to eq(localhost)
        end
      end
      context '削除できない場合' do
        it { is_expected.to eq(nil) }
      end
    end
  end

  # TaskControl class のテスト
  describe 'TaskControl' do
    before { @server = TCPServer.new(24_368) }
    after  { @server.close }
    let(:tasks) { Reins::TaskControl.new }

    describe '#connect' do
      context 'クライアントへ接続できる場合' do
        subject { tasks.connect }
        it 'モックを使って正常接続のコール' do
          allow(tasks).to receive(:connect).and_return(true)
          is_expected.to eq(true)
        end
      end

      context 'クライアントへ接続できない場合' do
        it '接続先が存在しないと Standard Error' do
          # TODO: 実際は Raise ではなく、成否を True/False でもらうこととする
          expect { Reins::TaskControl.new('localhost', 65_000) }.to raise_error 'Not Connect'
        end
        it 'クライアントが停止していたら false' do
          allow(tasks).to receive(:connect).and_return(false)
          expect(tasks.connect).to eq(false)
        end
      end
    end

    describe '#disconnect' do
      context '正常に切断できた場合' do
        subject { tasks.disconnect }
        it 'こちらから、クライアントとの接続を切断して、成功すると nil' do
          is_expected.to eq(nil)
        end
      end
    end
  end

  # Dispatcher class のテスト
  describe 'Dispatch' do
    let(:test_key)       { "TestKey" }
    let(:correct_host)   { Reins::Dispatch.new("192.168.0.10", test_key) }

    describe '#command' do
      context 'ホスト一覧を出力する場合' do
        it 'ホスト一覧が出力された' do
          allow(Reins.regist_host).to receive(:read_hosts).and_return([])
          expect(correct_host.command("list", "")).to eq([])
        end
      end
      context 'アドレスを削除する場合' do
        it 'アドレスを正常に削除' do
          allow(Reins.regist_host).to receive(:delete).and_return("192.168.0.10")
          expect(correct_host.command("delete", "")).to eq("192.168.0.10")
        end
      end
    end
  end
end
