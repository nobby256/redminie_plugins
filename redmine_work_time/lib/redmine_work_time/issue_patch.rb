require 'issue'

module RedmineWorkTime
  module IssuePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        after_save :chart_update_issue
      end

    end

    def self.add_time_entry(project_id, issue_id, status_id, done_ratio, date)
      row = TimeEntry.where("done_ratio is not null").first(:conditions => {:issue_id => issue_id}, :order => 'spent_on desc, id desc')
#        done_ratio = IssueStatus.find(status_id).is_closed? ? 100 : done_ratio
      val_done_ratio = nil
      if row
        if row.done_ratio != done_ratio
          val_done_ratio = done_ratio
        end
      elsif done_ratio > 0
        val_done_ratio = done_ratio
      end

      if val_done_ratio
        new_entry = TimeEntry.new(
                                  :project_id => project_id, 
                                  :issue_id => issue_id, 
                                  :user => User.current, 
                                  :spent_on => date
                                  )
        new_entry.hours = 0
        new_entry.activity_id = 0
        new_entry.done_ratio = val_done_ratio if val_done_ratio
        new_entry.save
      end
    end

    module InstanceMethods

      def is_add_time_entry?
        @is_add_time_entry = true if @is_add_time_entry.nil?
        return @is_add_time_entry
      end
      def is_add_time_entry=(val)
        @is_add_time_entry = val
      end

      def chart_update_issue
        if self.is_add_time_entry?
          RedmineWorkTime::IssuePatch.add_time_entry(self.project_id, self.id, self.status_id, self.done_ratio, Time.now)
        end
      end

    end

  end
end
