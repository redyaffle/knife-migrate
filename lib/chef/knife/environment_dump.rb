require 'chef/knife'
require 'knife_migrate/mixins/chef_paths'
require 'json'

module KnifeMigrate
  class EnvironmentDump < Chef::Knife
    include KnifeMigrate::ChefPaths

    banner 'knife environment dump [ENVIRONMENT]'

    option :all,
      short: '-a',
      long:  '--all',
      description: 'From Environment'

    def run
      validate

      if !config[:all]
        environment = name_args.first
        dump_environment(environment)
      else
        rest.get('environments').keys.each do |env|
          next if env =~ /^_/
          dump_environment(env)
        end
      end
    end

    def validate
      if name_args.length < 1 && config[:all] == false
        show_usage
        ui.fatal("You must specify an environment")
        exit 1
      end
    end

    def dump_environment(environment)
      ui.msg("Dumping environment #{environment}...")
      attrs = rest.get("environments/#{environment}").to_hash
      path = File.join(environment_path, "#{environment}.json")
      File.open(path, 'w') do |f|
        f.puts ::JSON.pretty_generate(attrs)
      end
    end
  end
end
