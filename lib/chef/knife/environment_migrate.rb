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
      versions(dst_cookbooks, src_cookbooks).each do |cookbook|
        update_version(cookbook)
      end
    end

    def update_attrs
      dst_attrs = @dst_env.default_attributes
      src_attrs = @src_env.default_attributes

      missing_attrs(dst_attrs, src_attrs).each do |missing_attr|
        cookbook_name = missing_attr.keys.first
        if import_missing_attr?(cookbook_name)
          dst_attrs[cookbook_name] = missing_attr[cookbook_name]
          update(missing_attr, cookbook_name)
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
      download_env(::JSON.pretty_generate(@dst_env.to_hash))
    end

    private

    def download_env(updated_env)
      begin
        env_file = "#{environment_path}/#{@dst_env_name}.json"
        ::File.open(env_file, 'w') do |f|
          f.write(updated_env)
        end
        ui.msg("Completed updated to #{env_file}")
      rescue Exception => e
        ui.error("Error: #{e.message}")
        ui.color(updated_env, :yellow)
      end
    end

    def import_missing_attr?(cookbook_name)
      cookbook_name = _color_cookbook_name(cookbook_name)
      dst_env_name = _color_environment_names.first
      ui.msg("Attribute #{cookbook_name} is missing on #{dst_env_name}")
      question = "Import #{cookbook_name} attribute on to #{dst_env_name}? #{_color_yes_no}"
      confirm_update?(question)
    end

    def new_attr(cookbook_name, attr_name, attr_value)
      cookbook_name = _color_cookbook_name(cookbook_name)
      dst_env_name, src_env_name = _color_environment_names
      c_attr_name, c_attr_value = _color_attributes(attr_name, attr_value)

      ui.msg("The value of #{cookbook_name}.#{c_attr_name} is #{c_attr_value} on #{src_env_name}")
      question = "Change the value of #{cookbook_name}.#{c_attr_name} on #{dst_env_name} #{_color_yes_no}"
      if confirm_update?(question)
        question = "What is the new value of #{cookbook_name}.#{c_attr_name} on #{dst_env_name}: "
        ui.ask_question(question)
      end
    end

    def update(missing_attr, cookbook)
      missing_attr[cookbook].each do |attr_name, attr_value|
        new_attr_value = new_attr(cookbook, attr_name, attr_value)
        if new_attr_value
          dst_attrs = @dst_env.default_attributes
          dst_attrs[cookbook][attr_name] = new_attr_value
        end
      end
    end

    def update_version(cookbook)
      cookbook_name = _color_cookbook_name(cookbook['name'])
      dst_ver, src_ver = _color_cookbook_versions(cookbook)
      dst_env_name = _color_environment_names.first

      question = "Change cookbook #{cookbook_name} version from #{dst_ver} to"
      question += " #{src_ver} on #{dst_env_name} #{_color_yes_no}"

      if confirm_update?(question)
        @dst_env.cookbook(cookbook['name'], cookbook[@src_env_name])
      end
    end

    def _color_yes_no
      ui.color('(y/n): ', :bold)
    end

    def _color_attributes(attr_name, attr_value)
      [ui.color(attr_name, :blue), ui.color(attr_value, :blue)]
    end

    def _color_cookbook_name(cookbook_name)
      ui.color(cookbook_name, :magenta)
    end

    def _color_environment_names
      [ui.color(@dst_env_name, :yellow), ui.color(@src_env_name, :yellow)]
    end

    def _color_cookbook_versions(cookbook)
      dst_version = cookbook[@dst_env_name] || 'none'
      src_version = cookbook[@src_env_name]
      [
        ui.color(dst_version, :red),
        ui.color(src_version, :green)
      ]
    end

  end
end
