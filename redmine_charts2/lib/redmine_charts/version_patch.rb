require_dependency 'version'

module RedmineCharts
  module VersionPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        validates :range_start_date, :date => true
        safe_attributes 'range_start_date'

        alias_method_chain :start_date, :charts

      end
    end

    module ClassMethods
      # Preloads visible started_on for a collection of issues
      def load_visible_started_on(issues, user=User.current)
        if issues.any?
          dates_by_issue_id = TimeEntry.visible(user).group(:issue_id).minimum(:created_on)
          issues.each do |issue|
            issue.instance_variable_set "@started_on", (dates_by_issue_id[issue.id] || nil)
          end
        end
      end
    end

    module InstanceMethods

      def start_date_with_charts
        @start_date ||= self.range_start_date
      end

      def start_date=(arg)
        self.range_start_date=(arg)
      end

    end

  end
end