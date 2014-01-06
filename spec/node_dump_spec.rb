require 'spec_helper'
require 'chef/knife/node_dump'

describe KnifeMigrate::NodeDump do
  let(:plugin) { described_class.new }
  let(:nodes) { [
    double('node', {
      name: 'node1',
      attributes: {
        'automatic' => {
          'cpu' => 'super_cpu'
        }
      }
    })
  ] }

  it 'sets up banner' do
    banner = 'knife node dump [PATTERN]'
    expect(described_class.banner).to eq(banner)
  end

  context '#run' do
    before do
      allow(plugin).to receive(:query)
        .and_return([nodes])
      expect(plugin).to receive(:environment_path)
        .and_return('./environments')
    end
  end
end
