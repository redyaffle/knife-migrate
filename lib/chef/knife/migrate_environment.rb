require 'chef/knife'

module Migrate
  class Environment < Chef::Knife
    banner 'knife migrate --e1 [source env] --e2 [destination env]'

    option :env1,
      short:  '--e1',
      long:  '--env1',
      description: 'Source Environment'

    option :env2,
      short: '--e2',
      long:  '--env2',
      description: 'Destination Environment'

    def run
      self.config = Chef::Config.merge!(config)
      if name_args.empty?
        ui.fatal 'You need to supply at least two environments!'
        show_usage
        exit(1)
      end
    end
  end
end
