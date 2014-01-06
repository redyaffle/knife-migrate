require 'spec_helper'
require 'chef/knife/environment_dump'

describe KnifeMigrate::EnvironmentDump do
  let(:plugin) { described_class.new }
  let(:rest) { double(:rest) }
  let(:args) { [] }

  before do
    allow(plugin).to receive(:name_args).and_return(args)
    allow(plugin).to receive(:environment_path).and_return('./environments')
    allow(plugin).to receive(:rest).and_return(rest)
  end

  it 'sets up banner' do
    banner = 'knife environment dump [ENVIRONMENT]'
    expect(described_class.banner).to eq(banner)
  end

  context 'dump environment' do
    let(:args) { ['unstable'] }

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

  context 'dump all environments' do
    let(:args) {
      { 'test' => 'chef_api',
        'unstable' => 'chef_api' }
    }
    before do
      plugin.config[:all] = true
    end

    it 'dumps all environments to environment path' do
      expect(rest).to receive(:get).with('environments').and_return(args)
      expect(plugin).to receive(:dump_environment).with('test')
      expect(plugin).to receive(:dump_environment).with('unstable')
      plugin.run
    end
  end
end
