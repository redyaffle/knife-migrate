require 'chef/knife'
require 'knife_migrate/mixins/validations'
require 'knife_migrate/mixins/default_attributes'
require 'knife_migrate/mixins/environments'

module KnifeMigrate
  class EnvironmentMissingAttributes < Chef::Knife
    include KnifeMigrate::Validations
    include KnifeMigrate::DefaultAttributes
    include KnifeMigrate::Environments

    banner 'knife environment missing attributes -e1 [Env] -e2 [Env]'

    option :env1,
      short:  '-e1',
      long:  '--env1',
      description: 'Environment'

    option :env2,
      short: '-e2',
      long:  '--env2',
      description: 'Environment'

    def run
      validate
      load_environments
      dst_attrs = @dst_env.default_attributes
      src_attrs = @src_env.default_attributes
      ui.msg(missing_attrs(dst_attrs, src_attrs))
    end
  end
end
