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

  context '#versions' do
    it 'diffs two environments cookbooks versions' do
      allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
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

  it 'sets up knife plugin' do
    env_object = double('environment')
    ui_object = double('ui')
    expect(plugin).to receive(:name_args).and_return(['debug', 'unstable']).
      exactly(3).times
    expect(plugin).to receive(:environment).and_return(env_object).twice
    expect(env_object).to receive(:cookbook_versions).and_return({}).twice
    expect(plugin).to receive(:versions).and_return([
      { name: 'cc_logrotate', debug: '= 1.1.2', unstable: '= 1.1.3' }
    ])
    expect(plugin).to receive(:ui).and_return(ui_object).twice
    expect(ui_object).to receive(:ask_question?).and_return('y')
    expect(env_object).to receive(:cookbook)
    expect(ui_object).to receive(:msg)
    expect(env_object).to receive(:to_hash)
    plugin.run
  end
end
