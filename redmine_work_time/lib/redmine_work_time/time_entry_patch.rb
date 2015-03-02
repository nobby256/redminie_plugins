require 'time_entry'

module RedmineWorkTime
  module TimeEntryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        safe_attributes 'done_ratio'

        validates_numericality_of :done_ratio, :allow_nil => true, :message => :invalid

        alias_method_chain :validate_time_entry, :done_ratio

      end

    end

    module InstanceMethods

      def validate_time_entry_with_done_ratio
        validate_time_entry_without_done_ratio
        errors.add :done_ratio, :invalid if done_ratio && (done_ratio < 0 || done_ratio >= 1000)
      end

    end

  end
end