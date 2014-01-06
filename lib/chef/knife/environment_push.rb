require 'chef/knife'
require 'chef/knife/environment_from_file'
require 'knife_migrate/mixins/chef_paths'
require 'json'

module KnifeMigrate
  class EnvironmentPush < ::Chef::Knife::EnvironmentFromFile
    include KnifeMigrate::ChefPaths

    banner 'knife environment push [ENVIRONMENT]'

    def run
      validate

      environment = name_args.first

      load_environment("#{environment_path}/#{environment}.json")
    end

    def validate
      if name_args.length < 1
        show_usage
        ui.fatel("You must specify an environment")
        exit 1
      end
    end
  end
end
