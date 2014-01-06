require 'chef/knife'
require 'knife_migrate/mixins/chef_paths'
require 'json'

module KnifeMigrate
  class EnvironmentPush < Chef::Knife::EnvironmentFromFile
    include KnifeMigrate::ChefPaths

    banner 'knife environment push ENVIRONMENT'

    def run
      if @name_args.length < 1
        show_usage
        ui.fatel("You must specify an environment")
        exit 1
      end

      load_environment("#{environment_path}/environment.json")
    end
  end
end
