require 'spec_helper'
require 'chef/knife/environment_missing_attributes'

module KnifeMigrate
  describe EnvironmentMissingAttributes do
    let(:plugin) { described_class.new }

    it 'sets up banner' do
      banner = 'knife environment missing attributes -e1 [Env] -e2 [Env]'
      expect(described_class.banner).to eq(banner)
    end

    it 'sets up options' do
      expect(described_class.options).not_to be_empty
    end

    context '#run' do
      let(:dst_env) do
        env = ::Chef::Environment.new
        env.name('debug')
        env.default_attributes({
          "cc_monit_conf"=> {
            "email_from"=>"devnull+monit@pivotallabs.com",
            "mmonit_server"=>"67.214.209.148"
          }
        })
        env
      end

      let(:src_env) do
        env = ::Chef::Environment.new
        env.name('stable')
        env.default_attributes({
          "cc_nginx"=> {
            "app_server_name"=>"stable.in.mycasebook.org",
            "app_name"=>"casebook2"
          },
          "cc_monit_conf"=> {
            "email_from"=>"devnull+monit@pivotallabs.com",
            "mmonit_server"=>"67.214.209.148"
          }
        })
        env
      end

      before do
        allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
        allow(plugin).to receive(:environment).with('debug').
          and_return(dst_env)
        allow(plugin).to receive(:environment).with('unstable').
          and_return(src_env)
      end

      it 'validates the user input' do
        expect(plugin).to receive(:validate)
        plugin.run
      end

      it 'gets missing default attributes' do
        expect(plugin).to receive(:missing_attrs)
        plugin.run
      end
    end
  end
end
