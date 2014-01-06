require 'chef/knife'
require 'knife_migrate/mixins/chef_paths'
require 'json'

module KnifeMigrate
  class NodeDump < Chef::Knife
    include KnifeMigrate::ChefPaths

    banner 'knife node dump [PATTERN]'

    AUTOMATIC_ATTRIBUTES = [
      'cpu', 'etc', 'counters', 'ohai_time',
      'filesystem', 'memory', 'uptime', 'uptime_seconds',
      'idletime', 'idletime_seconds', 'arp', 'neighbour_inet6',
      'refcount'
    ]

    def run
      validate

      pattern = name_args.first

      results = query(pattern)

      results.each do |node|
        ui.msg("Dumping node #{node.name}...")
        path = File.join(node_path, "#{node}.json")
        File.open(path, 'w') do |f|
          attributes = remove_automatic_attributes(node.attributes)
          f.puts ::JSON.pretty_generate(attributes)
        end
      end
    end

    def query(pattern)
      escaped_query = URI.escape(pattern, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

      q = Chef::Search::Query.new
      q.search('node', "name:*#{escaped_query}").first
    end

    def validate
      if name_args.length < 1
        show_usage
        ui.fatal("You must specify a node name pattern")
        exit 1
      end
    end

    def remove_automatic_attributes(hash)
      AUTOMATIC_ATTRIBUTES.each do |attr|
        recursive_delete(hash['automatic'], attr)
      end
    end

    def recursive_delete(hash, attr)
      return unless hash.instance_of?(Hash)

      if hash[attr]
        hash.delete(attr)
      else
        hash.each_value do |value|
          recursive_delete(value, attr)
        end
      end
    end
  end
end
