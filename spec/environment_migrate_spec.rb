require 'spec_helper'
require 'chef/knife/environment_migrate'

describe KnifeMigrate::EnvironmentMigrate do
  let(:plugin) { described_class.new }

  it 'sets up banner' do
    banner = 'knife environment migrate -from [Environment] -to [Environment]'
    expect(described_class.banner).to eq(banner)
  end

  it 'sets up options' do
    expect(described_class.options).not_to be_empty
  end

  context '#validate' do
    it 'displays usage if no arguments are provided' do
      expect(plugin).to receive(:name_args).and_return([])
      expect(plugin).to receive(:show_usage)
      expect(plugin).to receive(:exit)
      plugin.validate
    end

    it 'displays usage if only one environment is provided' do
      expect(plugin).to receive(:name_args).and_return(['debug'])
      expect(plugin).to receive(:show_usage)
      expect(plugin).to receive(:exit)
      plugin.validate
    end

    it 'does not exit if argument is provided' do
      expect(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
      expect(plugin).not_to receive(:show_usage)
      expect(plugin).not_to receive(:exit)
      plugin.validate
    end
  end

  it 'gets environment json from the chef server' do
    rest_object = double(:rest)
    expect(plugin).to receive(:rest).and_return(rest_object)
    expect(rest_object).to receive(:get_rest).with('environments/debug')
    plugin.environment('debug')
  end

  context "#load environment" do
    let(:name_args_obj) do
      double('name_args', first: 'debug', last: 'unstable')
    end

    before do
      allow(plugin).to receive(:name_args).and_return(name_args_obj)
      allow(plugin).to receive(:environment)
    end

    it 'sets up environment names and environments from chef server' do
      plugin.load_environments

      expect(name_args_obj).to have_received(:first)
      expect(name_args_obj).to have_received(:last)
      expect(plugin).to have_received(:environment).with('debug')
      expect(plugin).to have_received(:environment).with('unstable')
    end
  end

  context '#versions' do
    before do
      allow(plugin).to receive(:name_args).and_return(['unstable', 'debug'])
      allow(plugin).to receive(:environment)
      plugin.load_environments
    end

    it 'diffs two environments cookbooks versions' do

      debug_cookbook_versions = {
        "apt"=>"= 2.0.0",
        "ark"=>"= 0.3.0",
        "cc_logrotate"=>"= 1.1.2"
      }
      unstable_cookbook_versions = {
        "apt"=>"= 2.0.1",
        "ark"=>"= 0.3.1",
        "cc_logrotate"=>"= 1.1.3"
      }

      expect(plugin.versions(debug_cookbook_versions, unstable_cookbook_versions)).to match_array(
        [
          { 'name' => 'apt', 'debug' => '= 2.0.0', 'unstable' => '= 2.0.1' },
          { 'name' => 'ark', 'debug' => '= 0.3.0', 'unstable' => '= 0.3.1' },
          { 'name' => 'cc_logrotate', 'debug' => '= 1.1.2', 'unstable' => '= 1.1.3' },
        ]
      )
    end

    it 'returns versions diff if versions are not same' do
      allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
      debug_cookbook_versions = {
        "apt"=>"= 2.0.0",
        "ark"=>"= 0.3.0",
        "cc_logrotate"=>"= 1.1.2"
      }
      unstable_cookbook_versions = {
        "apt"=>"= 2.0.0",
        "ark"=>"= 0.3.0",
        "cc_logrotate"=>"= 1.1.3"
      }

      expect(plugin.versions(debug_cookbook_versions, unstable_cookbook_versions)).to match_array(
        [
          { 'name' => 'cc_logrotate', 'debug' => '= 1.1.2', 'unstable' => '= 1.1.3' },
        ]
      )
    end
  end

  context '#confirm_update?' do
    let(:ui_object) { double('ui') }

    before do
      allow(plugin).to receive(:ui).and_return(ui_object)
    end

    it 'take y/Y as true' do
      allow(ui_object).to receive(:ask_question).and_return 'Y'
      expect(plugin.confirm_update?('this is a question')).to be_true

      allow(ui_object).to receive(:ask_question).and_return 'y'
      expect(plugin.confirm_update?('this is a question')).to be_true
    end

    it 'take n/N as false' do
      allow(ui_object).to receive(:ask_question).and_return 'n'
      expect(plugin.confirm_update?('this is a question')).to be_false

      allow(ui_object).to receive(:ask_question).and_return 'N'
      expect(plugin.confirm_update?('this is a question')).to be_false
    end

    it 'repeats the question if it is not y/Y/n/N' do
      allow(ui_object).to receive(:ask_question).and_return('value', 'n')
      expect(ui_object).to receive(:msg)
      expect(plugin.confirm_update?('question')).to be_false
    end
  end

  context '#update_versions' do
    let(:dst_env) do
      env = ::Chef::Environment.new
      env.name('debug')
      env.cookbook_versions({ "apt"=>"= 2.0.0", "ark"=>"= 0.3.0" })
      env
    end

    let(:src_env) do
      env = ::Chef::Environment.new
      env.name('stable')
      env.cookbook_versions({ "apt"=>"= 2.0.1", "ark"=>"= 0.3.2" })
      env
    end

    before do
      allow(plugin).to receive(:name_args).and_return(['stable', 'debug'])
      allow(plugin).to receive(:environment).with('debug').and_return(dst_env)
      allow(plugin).to receive(:environment).with('stable').and_return(src_env)

      plugin.load_environments

      allow(plugin).to receive(:confirm_update?).and_return(true)
    end

    it 'updates cookbook version' do
      plugin.update_versions
      expect(dst_env.cookbook_versions['apt']).to eq('= 2.0.1')
      expect(dst_env.cookbook_versions['ark']).to eq('= 0.3.2')
    end
  end

  context '#missing_attrs' do
    it 'returns missing attributes' do
       src_attrs = {
         "newrelic"=>{ "apdex_t"=>"1.0" },
         "repo_list"=> [
           "casebook/casebook2",
           "casebook/in-assets",
           "casebook/casebook_ssh_config",
           "Casecommons/casebook2_deploy"
         ],
         "cc_nginx"=> {
           "app_server_name"=>"greenfield.in.mycasebook.org",
           "app_name"=>"casebook2"
         },
         "cc_monit_conf"=> {
           "email_from"=>"devnull+monit@pivotallabs.com",
           "mmonit_server"=>"67.214.209.148"
         },
       }

       dst_attrs = {
         "newrelic"=>{ "apdex_t"=>"1.0" },
         "repo_list"=> [
           "casebook/casebook2",
           "casebook/in-assets",
           "casebook/casebook_ssh_config",
           "Casecommons/casebook2_deploy"]
       }

       expect(plugin.missing_attrs(dst_attrs, src_attrs)).to eq([
         {
           "cc_nginx"=> {
             "app_server_name"=>"greenfield.in.mycasebook.org",
             "app_name"=>"casebook2"
           }},
           {
           "cc_monit_conf"=> {
             "email_from"=>"devnull+monit@pivotallabs.com",
             "mmonit_server"=>"67.214.209.148"
           }},
       ])
    end
  end

  context '#update_attrs' do
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

    let(:ui_obj) { double('ui') }
    before do
      allow(plugin).to receive(:name_args).and_return(['stable', 'debug'])
      allow(plugin).to receive(:environment).with('debug').and_return(dst_env)
      allow(plugin).to receive(:environment).with('stable').and_return(src_env)

      plugin.load_environments

      allow(plugin).to receive(:ui).and_return(ui_obj)
      allow(ui_obj).to receive(:color).with('cc_nginx', :magenta).
        and_return('cc_nginx')
      allow(ui_obj).to receive(:color).with('debug', :yellow).
        and_return('debug')
      allow(ui_obj).to receive(:color).with('stable', :yellow).
        and_return('stable')
      allow(ui_obj).to receive(:color).with('app_server_name', :blue).
        and_return('app_server_name')
      allow(ui_obj).to receive(:color).with('stable.in.mycasebook.org', :blue).
        and_return('stable.in.mycasebook.org')
      allow(ui_obj).to receive(:color).with('app_name', :blue).
        and_return('app_name')
      allow(ui_obj).to receive(:color).with('casebook2', :blue).
        and_return('casebook2')
      allow(ui_obj).to receive(:color).with('(y/n): ', :bold)
    end

    it 'returns updated attributes' do
      allow(ui_obj).to receive(:msg)
      allow(plugin).to receive(:confirm_update?).and_return(true, true, false)
      expect(ui_obj).to receive(:ask_question).with(
        'What is the new value of cc_nginx.app_server_name on debug: ').
        and_return('debug.in.mycasebook.org')
      plugin.update_attrs
      expect(dst_env.default_attributes['cc_nginx']).to eq({
        'app_server_name'=>'debug.in.mycasebook.org',
        'app_name'=>'casebook2'
      })
    end
  end

  context '#environment_path' do
    let(:expected_env_path) do
      '/Users/test/workspace/organizations/in/environments'
    end

    it 'sets environment path based on cookbook path' do
      expect(Chef::Config).to receive(:[]).with(:cookbook_path).and_return(
        ['/Users/test/workspace/.chef/../organizations/in/cookbooks']
      )
      expect(plugin.environment_path).to eq(expected_env_path)
    end

    it 'sets handles cookbook path ending with /' do
      expect(Chef::Config).to receive(:[]).with(:cookbook_path).and_return(
        ['/Users/test/workspace/.chef/../organizations/in/cookbooks/']
      )
      expect(plugin.environment_path).to eq(expected_env_path)
    end
  end

  context '#remove_cookbook' do
    let(:dst_env) do
      env = ::Chef::Environment.new
      env.name('debug')
      env.cookbook_versions({ "apt"=>"= 2.0.0", "logrotate"=>"= 1.1.3" })
      env
    end

    let(:src_env) do
      env = ::Chef::Environment.new
      env.name('stable')
      env.cookbook_versions({ "apt"=>"= 2.0.1", "ark"=>"= 0.3.2" })
      env
    end

    before do
      allow(plugin).to receive(:name_args).and_return(['stable', 'debug'])
      allow(plugin).to receive(:environment).with('debug').and_return(dst_env)
      allow(plugin).to receive(:environment).with('stable').and_return(src_env)

      plugin.load_environments
    end

    it 'removes cookbook from the environment' do
      plugin.remove_cookbook('logrotate')
      expect(dst_env.cookbook_versions).not_to have_key('logrotate')
    end

    it 'remove only existing cookbook' do
      expect { plugin.remove_cookbook('awesome_cookbook') }.not_to raise_error
    end
  end

  describe 'interactive removing cookbooks' do
    let(:dst_env) do
      env = ::Chef::Environment.new
      env.name('debug')
      env.cookbook_versions({ "apt"=>"= 2.0.0", "logrotate"=>"= 1.1.3" })
      env
    end

    let(:src_env) do
      env = ::Chef::Environment.new
      env.name('stable')
      env.cookbook_versions({ "apt"=>"= 2.0.1", "ark"=>"= 0.3.2" })
      env
    end

    before do
      allow(plugin).to receive(:name_args).and_return(['stable', 'debug'])
      allow(plugin).to receive(:environment).with('debug').and_return(dst_env)
      allow(plugin).to receive(:environment).with('stable').and_return(src_env)

      plugin.load_environments
    end

    context 'removing existing cookbook from environment' do
      it 'prompts the user to remove cookbooks' do
        question = 'Do you want to remove any cookbook from debug environment'
        expect(plugin).to receive(:confirm_update?).with(question).
          and_return(true, false)
        question1 = 'which cookbook do you want to remove? :  '
        expect(plugin.ui).to receive(:ask_question).with(question1).
          and_return('apt')
        expect(plugin.ui).to receive(:msg).with('Removed cookbook apt = 2.0.0')
        plugin.remove_cookbooks
        expect(dst_env.cookbook_versions).not_to have_key('apt')
      end
    end

    context 'removing non existent cookbook from environment' do
      it 'should say cookbook exists' do
        question = 'Do you want to remove any cookbook from debug environment'
        expect(plugin).to receive(:confirm_update?).with(question).
          and_return(true, false)
        question1 = 'which cookbook do you want to remove? :  '
        expect(plugin.ui).to receive(:ask_question).with(question1).
          and_return('test')
        expect(plugin.ui).to receive(:msg).
          with('Trying to remove cookbook test that does not exist in debug environment!')
        plugin.remove_cookbooks
      end
    end

    context 'removing multiple cookbooks' do
      before do
        question = 'Do you want to remove any cookbook from debug environment'
        expect(plugin).to receive(:confirm_update?).with(question).
          and_return(true, true, false)
        question1 = 'which cookbook do you want to remove? :  '
        expect(plugin.ui).to receive(:ask_question).with(question1).
          and_return('apt', 'logrotate').twice
      end

      it 'allows for multiple cookbook removal from environment' do
        plugin.remove_cookbooks
        expect(dst_env.cookbook_versions).to be_empty
      end
    end
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

    let(:environment_path) do
      '/Users/test/workspace/organizations/in/environments'
    end

    let(:ui_obj) { double('ui') }

    before do
      allow(plugin).to receive(:name_args).and_return(['stable', 'debug'])
      allow(plugin).to receive(:environment).with('debug').and_return(dst_env)
      allow(plugin).to receive(:environment).with('stable').and_return(src_env)
      allow(plugin).to receive(:ui).and_return(ui_obj)
      expect(Chef::Config).to receive(:[]).with(:cookbook_path).and_return(
        ['/Users/test/workspace/.chef/../organizations/in/cookbooks']
      )
    end

    it 'sets up run method' do
      expect(plugin).to receive(:validate)
      expect(plugin).to receive(:load_environments).and_call_original
      expect(plugin).to receive(:update_versions)
      expect(plugin).to receive(:remove_cookbooks)
      expect(plugin).to receive(:update_attrs)
      expect(JSON).to receive(:pretty_generate).with(dst_env.to_hash)
      allow(ui_obj).to receive(:msg)
      expect(::File).to receive(:open).with("#{environment_path}/debug.json", 'w')
      plugin.run
    end
  end
end
