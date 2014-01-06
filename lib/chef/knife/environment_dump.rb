require 'chef/knife'
require 'knife_migrate/mixins/chef_paths'
require 'json'

module KnifeMigrate
  class EnvironmentDump < Chef::Knife
    include KnifeMigrate::ChefPaths

    banner 'knife environment dump [ENVIRONMENT]'

    def run
      validate

      environment = name_args.first

      ui.msg("Dumping environment #{environment}...")

      attrs = load(environment)

      save_environment(environment, attrs)
    end

    def validate
      if name_args.length < 1
        show_usage
        ui.fatal("You must specify an environment")
        exit 1
      end
    end

    def load(environment)
      rest.get("environments/#{environment}")
    end

    def save_environment(environment, attrs)
      path = File.join(environment_path, "#{environment}.json")
      File.open(path, 'w') do |f|
        f.puts JSON.pretty_generate(JSON.parse(attrs))
      end
    end
  end
end
