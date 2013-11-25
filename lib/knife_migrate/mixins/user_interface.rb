module KnifeMigrate
  module UserInterface
    module ClassMethods; end

    module InstanceMethods
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

      def pretty_json(hash)
        ::JSON.pretty_generate(hash)
      end

      private
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

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
