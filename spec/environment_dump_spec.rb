require 'spec_helper'
require 'chef/knife/environment_dump'

describe KnifeMigrate::EnvironmentDump do
  let(:plugin) { described_class.new }
  let(:rest) { double(:rest) }

  it 'sets up banner' do
    banner = 'knife environment dump [ENVIRONMENT]'
    expect(described_class.banner).to eq(banner)
  end

  context '#run' do
    before do
      allow(plugin).to receive(:name_args)
        .and_return(['unstable'])
      expect(plugin).to receive(:environment_path)
        .and_return('./environments')
      expect(plugin).to receive(:rest)
        .and_return(rest)
    end

    it 'loads current environment' do
      expect(rest).to receive(:get)
        .with('environments/unstable')
        .and_return({ hash: 'data'})
      allow(File).to receive(:open)
      plugin.run
    end

    it 'saves environment to environment path' do
      expect(rest).to receive(:get)
        .and_return({ hash: 'data'})
      expect(File).to receive(:open)
        .with('./environments/unstable.json', 'w')
      plugin.run
    end
  end
end
