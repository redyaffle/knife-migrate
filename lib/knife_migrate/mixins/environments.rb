module KnifeMigrate
  module Environments
    module ClassMethods; end
    module InstanceMethods
      def environment(env)
        rest.get_rest("environments/#{env}")
      end

      def load_environments
        @dst_env_name ||= name_args.last
        @src_env_name ||= name_args.first
        @dst_env ||= environment(@dst_env_name)
        @src_env ||= environment(@src_env_name)
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
