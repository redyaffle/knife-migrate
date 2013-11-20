require 'chef/knife'

module KnifeMigrate
  class EnvironmentMigrate < Chef::Knife
    banner 'knife environment migrate --this [Environment] --from [Environment]'

    option :this,
      short:  '--this',
      long:  '--this',
      description: 'Migrating Environment'

    option :from,
      short: '--from',
      long:  '--from',
      description: 'From Environment'

    def validate
      if name_args.size < 2
        ui.fatal 'You need to supply two environments!'
        show_usage
        exit(1)
      end
    end

    def environment(env)
      rest.get_rest("environments/#{env}")
    end

    def versions(dst_cookbooks, src_cookbooks)
      result = []
      dst_env, src_env = name_args
      src_cookbooks.each do |name, src_version|
        dst_version = dst_cookbooks[name]
        if src_version != dst_version
          result << {
            'name' => name,
            dst_env => dst_version,
            src_env => src_version
          }
        end
      end
      result
    end

    def run
      validate
      dst_env_name = name_args.first
      src_env_name = name_args.last
      dst_env = environment(dst_env_name)
      src_env = environment(src_env_name)
      dst_cookbooks = dst_env.cookbook_versions
      src_cookbooks = src_env.cookbook_versions
      diff_version = versions(dst_cookbooks, src_cookbooks)
      diff_version.each do |value|
        question = "Change cookbook #{value['name']} version from #{value[dst_env_name]} to #{value[src_env_name]}"
        if ui.ask_question?(question) === 'y'
          dst_env.cookbook(value['name'], value[dst_env_name])
        end
      end
      ui.msg(dst_env.to_hash)
    end
  end
end
