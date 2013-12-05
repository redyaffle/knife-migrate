require 'chef/knife'
require 'knife_migrate/knife_migrate'

module KnifeMigrate
  class EnvironmentMigrate < Chef::Knife
    include KnifeMigrate::Validations
    include KnifeMigrate::Environments
    include KnifeMigrate::CookbookVersions
    include KnifeMigrate::DefaultAttributes
    include KnifeMigrate::ChefPaths
    include KnifeMigrate::UserInterface

    banner 'knife environment migrate -from [Environment] -to [Environment]'

    option :from,
      short: '-from',
      long:  '--from',
      description: 'From Environment'

    option :to,
      short:  '-to',
      long:  '--to',
      description: 'To Environment'

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

    def remove_cookbook(cookbook_name)
      @dst_env.cookbook_versions.delete(cookbook_name)
    end

    def remove_cookbooks
      dst_env_name = _color_environment_names.first
      question = "Do you want to remove any cookbook from "
      question += "#{dst_env_name} environment"
      while confirm_update?(question)
        get_cookbook_name = 'which cookbook do you want to remove? :  '
        cookbook_name = ui.ask_question(get_cookbook_name)
        cookbook_name = _color_cookbook_name(cookbook_name)
        cookbook_version = remove_cookbook(cookbook_name)
        if cookbook_version
          ui.msg("Removed cookbook #{cookbook_name} #{cookbook_version}")
        else
          message = "Trying to remove cookbook #{cookbook_name} "
          message += "that does not exist in #{dst_env_name} environment!"
          ui.msg(ui.color(message, :red))
        end
      end
    end

    def run
      validate
      load_environments
      update_versions
      remove_cookbooks
      update_attrs
      download_env(pretty_json(@dst_env.to_hash))
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
  end
end
