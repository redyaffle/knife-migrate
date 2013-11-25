module KnifeMigrate
  module CookbookVersions
    module ClassMethods; end

    module InstanceMethods
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
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end
  end
end
