module KnifeMigrate
  module ChefPaths
    module ClassMethods; end

    module InstanceMethods
      def cookbook_path
        cookbook_path = Chef::Config[:cookbook_path].first
        cookbook_path.chomp('/')
        cookbook_path
      end

      def environment_path
        organization_path = ::File.split(cookbook_path).first
        ::File.absolute_path "#{organization_path}/environments"
      end

      def node_path
        organization_path = ::File.split(cookbook_path).first
        ::File.absolute_path "#{organization_path}/nodes"
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
