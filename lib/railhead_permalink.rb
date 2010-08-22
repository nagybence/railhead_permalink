module RailheadPermalink

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods

    def auto_permalink(field, options = {})
      include RailheadPermalink::InstanceMethods
      class << self
        alias_method_chain :find, :permalink
      end
      class_inheritable_reader :permalink_options

      write_inheritable_attribute(:permalink_options, {
        :field => field,
        :keep_existing => (options[:keep_existing] || false),
        :reserved_names => (options[:reserved_names] || []).concat(ActionController::Base.resources_path_names.values)
      })

      before_save :create_permalink
      validates_presence_of field
    end

    def find_with_permalink(*args)
      key = args.first
      if key.is_a?(String)
        find_without_permalink(:first, :conditions => {:permalink => key}) || find_without_permalink(*args)
      else
        find_without_permalink(*args)
      end
    end
  end

  module InstanceMethods

    def create_permalink
      if self.permalink.nil? or (self.changed.include?(permalink_options[:field].to_s) and not permalink_options[:keep_existing])
        key = self[permalink_options[:field]].parameterize.to_s
        unless self.permalink == key
          permalink, counter = key, '-1'
          while permalink_options[:reserved_names].include?(permalink) or permalink.blank? or
            (object = self.class.find_without_permalink(:first, :conditions => {:permalink => permalink}) and object != self)
              counter.succ!
              permalink = key + counter
          end
          self.permalink = permalink
        end
      end
    end

    def to_param
      self.permalink
    end
  end
end


ActiveRecord::Base.send :include, RailheadPermalink

