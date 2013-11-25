module KnifeMigrate
  module DefaultAttributes
    module ClassMethods; end

    module InstanceMethods
      def missing_attrs(dst_attrs, src_attrs)
        result = []
        src_attrs.keys.each do |cookbook_name|
          unless dst_attrs.has_key?(cookbook_name)
            result << { cookbook_name => src_attrs[cookbook_name] }
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
