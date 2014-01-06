require 'spec_helper'
require 'chef/knife/environment_push'

describe KnifeMigrate::EnvironmentPush do
  let(:plugin) { described_class.new }
  let(:rest) { double(:rest) }

  it 'sets up banner' do
    banner = 'knife environment push [ENVIRONMENT]'
    expect(described_class.banner).to eq(banner)
  end

  context '#run' do
    before do
      allow(plugin).to receive(:name_args)
        .and_return(['unstable'])
      expect(plugin).to receive(:environment_path)
        .and_return('./environments')
    end

    it 'push environment' do
      expect(plugin).to receive(:load_environment)
        .with('./environments/unstable.json')
      plugin.run
    end
  end
end
