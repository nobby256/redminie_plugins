require_dependency 'issue'

module IssueNoParentUpdate
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        belongs_to :sub_category, :class_name => 'IssueSubCategory', :foreign_key => 'sub_category_id'
        safe_attributes 'external_id', 'external_order', 'tag', 'sub_category_id', :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }

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
      # Returns the number of hours spent on this issue
      def started_on
        unless @cached_started_on
          @cached_started_on = true
          @started_on = time_entries.minimum(:spent_on)
        end
        return @started_on
      end
      def closed_on
        v = read_attribute(:closed_on)
        return (v ? v.to_date : nil)
      end
    end
  end
end