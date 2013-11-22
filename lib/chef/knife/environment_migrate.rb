require 'chef/knife'

module KnifeMigrate
  class EnvironmentMigrate < Chef::Knife
    banner 'knife environment migrate --from [Environment] --to [Environment]'

    option :from,
      short: '--from',
      long:  '--from',
      description: 'From Environment'

    option :to,
      short:  '--to',
      long:  '--to',
      description: 'To Environment'

    def validate
      self.config = Chef::Config.merge!(config)
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
      src_cookbooks.each do |name, src_version|
        dst_version = dst_cookbooks[name]
        if src_version != dst_version
          result << {
            'name' => name,
            @dst_env_name => dst_version,
            @src_env_name => src_version
          }
        end
      end
      result
    end

    def confirm_update?(question)
      case ui.ask_question(question)
      when 'y', 'Y'
        true
      when 'n', 'N'
        false
      else
        ui.msg('Just say y or n.')
        confirm_update?(question)
      end
    end

    def missing_attrs(dst_attrs, src_attrs)
      result = []
      src_attrs.keys.each do |cookbook_name|
        unless dst_attrs.has_key?(cookbook_name)
          result << { cookbook_name => src_attrs[cookbook_name] }
        end
      end
      result
    end

    def load_environments
      @dst_env_name ||= name_args.last
      @src_env_name ||= name_args.first
      @dst_env ||= environment(@dst_env_name)
      @src_env ||= environment(@src_env_name)
    end

    def update_versions
      dst_cookbooks = @dst_env.cookbook_versions
      src_cookbooks = @src_env.cookbook_versions
      versions(dst_cookbooks, src_cookbooks).each do |value|
        question = "Change cookbook #{value['name']} version from"
        question += " #{value[@dst_env_name]} to #{value[@src_env_name]} (y/n): "
        if confirm_update?(question)
          @dst_env.cookbook(value['name'], value[@src_env_name])
        end
      end
    end

    def update_attrs
      dst_attrs = @dst_env.default_attributes
      src_attrs = @src_env.default_attributes
      missing_attrs(dst_attrs, src_attrs).each do |cookbook_attr|
        cookbook_name = cookbook_attr.keys.first
        ui.msg("Attributes #{cookbook_name} is missing")
        question = "Do you want this #{cookbook_name} attributes? (y/n): "
        if confirm_update?(question)
          dst_attrs[cookbook_name] = cookbook_attr[cookbook_name]
          cookbook_attr[cookbook_name].each do |attr_name, attr_value|
            ui.msg("The value of #{attr_name} is #{attr_value}")
            if confirm_update?("Change the value of #{attr_name} (y/n): ")
              question = "What is the new value of #{attr_name}: "
              answer =  ui.ask_question(question)
              dst_attrs[cookbook_name][attr_name] = answer
            end
          end
        end
      end
    end

    def environment_path
      cookbook_path = Chef::Config[:cookbook_path].first
      cookbook_path.chomp('/')
      organization_path = ::File.split(cookbook_path).first
      ::File.absolute_path "#{organization_path}/environments"
    end

    def run
      validate
      load_environments
      update_versions
      update_attrs
      updated_env = ::JSON.pretty_generate(@dst_env.to_hash)
      begin
        env_file = "#{environment_path}/#{@dst_env_name}.json"
        ::File.open(env_file, 'w') do |f|
          f.write(updated_env)
        end
        ui.msg("Completed updated to #{env_file}")
      rescue Exception => e
        ui.msg("Error: #{e.message}")
        ui.msg(updated_env)
      end
    end
  end
end
