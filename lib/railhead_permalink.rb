module RailheadPermalink
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      class << self
        alias_method_chain :find, :permalink
      end
      class_inheritable_reader :permalink_options
      before_validation :create_permalink
    end
  end

  module ClassMethods
    def auto_permalink(field, options = {})
      include RailheadPermalink::InstanceMethods

      write_inheritable_attribute(:permalink_options, {
        :field => field,
        :reserved_names => (options[:reserved_names] || []).concat(ActionController::Base.resources_path_names.values)
      })
    end

    def find_with_permalink(*args)
      key = args.first
      if key.is_a?(String)
        find_without_permalink(:first, :conditions => ['permalink = ?', key]) || find_without_permalink(*args)
      else
        find_without_permalink(*args)
      end
    end
  end

  module InstanceMethods
    def create_permalink
      key, counter = self[permalink_options[:field]].parameterize.to_s, '-1'
      permalink = key
      while permalink_options[:reserved_names].include?(permalink) or self.class.exists?(:permalink => permalink)
        counter.succ!
        permalink = key + counter
      end
      self[:permalink] = permalink
    end

    def to_param
      permalink
    end
  end
end


ActiveRecord::Base.send :include, RailheadPermalink
