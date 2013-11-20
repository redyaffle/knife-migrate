require 'chef/knife'
module KnifeMigrate
  class EnvironmentDiffCookbooks < Chef::Knife
    banner 'knife environment diff cookbooks --e1 [source env] --e2 [destination env]'

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
      validate
      src_env = name_args.first
      dst_env = name_args.last
      src_cookbooks = cookbooks(src_env)
      dst_cookbooks = cookbooks(dst_env)
      diff_versions = versions(src_cookbooks, dst_cookbooks)
      ui.msg("cookbook version differences between #{src_env} and #{dst_env}")
      ui.msg(diff_versions)
    end

    def validate
      if name_args.size < 2
        ui.fatal 'You need to supply at least two environments!'
        show_usage
        exit(1)
      end
    end

    def versions(src_cookbooks, dst_cookbooks)
      result = []
      src_cookbooks.each do |name, src_data|
        src_version = cookbook_version(src_data)
        dst_data = dst_cookbooks[name]
        dst_version = cookbook_version(dst_data)
        if src_version != dst_version
          result << {
            name: name,
            src_version: src_version,
            dst_version: dst_version
          }
        end
      end
      result
    end

    def cookbooks(env)
      rest.get_rest("environments/#{env}/cookbooks")
    end

    def cookbook_version(data)
      if data['versions'].empty?
        'none'
      else
        data['versions'].first['version']
      end
    end
  end
end
