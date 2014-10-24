begin
  require 'stringex_lite'
rescue LoadError
  class String
    alias_method :to_url, :parameterize
  end
end


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
      class_attribute :permalink_options

      self.permalink_options = {
        :field => field,
        :keep_existing => (options[:keep_existing] || false),
        :reserved_names => (options[:reserved_names] || []),
        :unique => (options[:unique] || false)
      }

      before_save :create_permalink
      validates_presence_of field
      validates_uniqueness_of field, :case_sensitive => false, :if => "#{field}_changed?".to_sym if permalink_options[:unique]
    end

    def find_with_permalink(*args)
      key = args.first
      if key.is_a?(String)
        where(:permalink => key).first || find_without_permalink(*args)
      else
        find_without_permalink(*args)
      end
    end
  end


  module InstanceMethods

    def create_permalink
      if self.permalink.nil? or (self.changed.include?(permalink_options[:field].to_s) and not permalink_options[:keep_existing])
        key = self[permalink_options[:field]].to_url
        unless self.permalink == key
          permalink, counter = key, '-1'
          while permalink_options[:reserved_names].include?(permalink) or permalink.blank? or
            (object = self.class.where(:permalink => permalink).first and object != self)
              counter.succ!
              permalink = key + counter
          end
          self.permalink = permalink
        end
      end
      true
    end

    def to_param
      self.permalink
    end
  end
end


ActiveRecord::Base.send :include, RailheadPermalink
