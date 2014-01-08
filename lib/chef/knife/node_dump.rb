require 'chef/knife'
require 'knife_migrate/mixins/chef_paths'
require 'json'

module KnifeMigrate
  class NodeDump < Chef::Knife
    include KnifeMigrate::ChefPaths

    banner 'knife node dump [PATTERN]'

    def run
      validate
      pattern = name_args.first
      results = query(pattern)

      results.each do |node|
        ui.msg("Dumping node #{node.name}...")
        path = File.join(node_path, "#{node.name}.json")

        config[:format] = "json"
        config[:long_output] = true

        node = Chef::Node.load(node.name)
        node_json = JSON.parse(ui.presenter.format(format_for_display(node)))
        node_json.delete('automatic')

        File.open(path, 'w') do |f|
          f.puts ::JSON.pretty_generate(node_json)
        end
      end
    end

    def query(pattern)
      escaped_query = URI.escape(pattern, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

      q = Chef::Search::Query.new
      q.search('node', "name:*#{escaped_query}*").first
    end

    def validate
      if name_args.length < 1
        show_usage
        ui.fatal("You must specify a node name pattern")
        exit 1
      end
    end
  end
end
