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

    def missing_attrs(dst_attrs, src_attrs)
      result = []
      src_attrs.keys.each do |cookbook_name|
        unless dst_attrs.has_key?(cookbook_name)
          result << { cookbook_name => src_attrs[cookbook_name] }
        end
      end
      result
    end

    def run
      validate
      load_environments
      cookbook_versions
      update_attrs
    end

    def load_environments
      @dst_env_name ||= name_args.first
      @src_env_name ||= name_args.last
      @dst_env ||= environment(@dst_env_name)
      @src_env ||= environment(@src_env_name)
    end

    private

    def update_attrs
      dst_attrs = @dst_env.default_attributes
      src_attrs = @src_env.default_attributes
      missing_attrs(dst_attrs, src_attrs).each do |cookbook_attr|
        cookbook_name = cookbook_attr.keys.first
        question = "Do you want to update #{cookbook_name}?"
        if ui.ask_question(question) === 'y'
          cookbook_attr[cookbook_name].each do |attr_name, attr_value|
            ui.msg("The value of #{attr_name} is #{attr_value}")
            question = "Change the value of #{attr_name} (y/n): "
            if ui.ask_question(question) === 'y'
              question = "What is the new value of #{attr_name}"
              answer =  ui.ask_question(question)
              attr_value = answer
            end
          end
        end
      end
    end

    def cookbook_versions
      dst_cookbooks = @dst_env.cookbook_versions
      src_cookbooks = @src_env.cookbook_versions
      versions(dst_cookbooks, src_cookbooks).each do |value|
        question = "Change cookbook #{value['name']} version from"
        question += " #{value[@dst_env_name]} to #{value[@src_env_name]} (y/n): "
        if ui.ask_question(question) === 'y'
          @dst_env.cookbook(value['name'], value[@src_env_name])
        end
      end
      ui.msg(@dst_env.to_hash)
    end
  end
end
