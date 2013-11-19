require 'spec_helper'
require 'chef/knife/migrate_environment'

describe 'Migrate::Environment' do

  let(:plugin) { Migrate::Environment.new }

  before do
    # plugin.run
  end

  it 'is knife plugin' do
    expect(Migrate::Environment.banner).to eq('knife migrate --e1 [source env] --e2 [destination env]')
  end

  context 'arguments' do
    it 'exits if no arguments are provided' do
      expect(plugin).to receive(:name_args).and_return([])
      expect(plugin).to receive(:show_usage)
      expect(plugin).to receive(:exit)
      plugin.run
    end

    it 'does not exit if argument is provided' do
      expect(plugin).to receive(:name_args).and_return(['--e1 debug'])
      expect(plugin).not_to receive(:show_usage)
      expect(plugin).not_to receive(:exit)
      plugin.run
    end
  end

  xit 'grabs cookbooks from environment' do

  end
end
