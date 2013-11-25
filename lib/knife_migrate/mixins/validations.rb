module KnifeMigrate
  module Validations
    module ClassMethods; end

    module InstanceMethods
      def validate
        self.config = Chef::Config.merge!(config)
        if name_args.size < 2
          ui.fatal 'You need to supply two environments!'
          show_usage
          exit(1)
        end
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
