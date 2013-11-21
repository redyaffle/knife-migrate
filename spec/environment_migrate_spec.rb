require 'spec_helper'
require 'chef/knife/environment_migrate'

describe KnifeMigrate::EnvironmentMigrate do
  let(:plugin) { described_class.new }

  it 'sets up banner' do
    banner = 'knife environment migrate --this [Environment] --from [Environment]'
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
      allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
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

  context 'cookbooks versions migration' do
    let(:dst_env) { double('environment') }
    let(:src_env) { double('environment') }
    let(:ui_object) {  double('ui') }

    before do
      expect(plugin).to receive(:config)
      expect(Chef::Config).to receive(:merge!)
      expect(plugin).to receive(:name_args).and_return(['debug', 'unstable']).
        exactly(3).times
      expect(plugin).to receive(:environment).with('debug').and_return(dst_env)
      expect(plugin).to receive(:environment).with('unstable').and_return(src_env)
      expect(src_env).to receive(:cookbook_versions)
      expect(dst_env).to receive(:cookbook_versions)
      expect(plugin).to receive(:versions).and_return([
        { 'name' => 'cc_logrotate', 'debug' => '= 1.1.2', 'unstable' => '= 1.1.3' }
      ])
      expect(dst_env).to receive(:cookbook).with('cc_logrotate', '= 1.1.3')
      expect(ui_object).to receive(:msg)
      expect(dst_env).to receive(:to_hash)
      expect(dst_env).to receive(:default_attributes)
      expect(src_env).to receive(:default_attributes)
    end

    it 'sets up cookbook versions' do
      expect(plugin).to receive(:ui).and_return(ui_object).twice
      expect(ui_object).to receive(:ask_question).and_return('y')
      expect(plugin).to receive(:missing_attrs).and_return([])
      expect(plugin).to receive(:cookbook_versions).and_call_original
      plugin.run
    end

    it 'sets up missing default attributes' do
      expect(plugin).to receive(:missing_attrs).and_return(
         [{
           "cc_nginx"=> {
             "app_server_name"=>"greenfield.in.mycasebook.org",
             "app_name"=>"casebook2"
           }}]
      )
      expect(plugin).to receive(:ui).and_return(ui_object).exactly(9).times
      expect(ui_object).to receive(:msg).twice
      expect(ui_object).to receive(:ask_question).exactly(6).times.and_return('y')
      expect(plugin).to receive(:update_attrs).and_call_original
      plugin.run
    end
  end
end
