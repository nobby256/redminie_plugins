module RedmineCharts
  module IssuePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        after_save :chart_update_issue
      end

    end

    def self.add_time_entry(project_id, issue_id, status_id, done_ratio, date)
        val_done_ratio = nil
        row = TimeEntry.where("done_ratio is not null").first(:conditions => {:issue_id => issue_id}, :order => 'spent_on desc, id desc')
#        done_ratio = IssueStatus.find(status_id).is_closed? ? 100 : done_ratio
        if row
          if row.done_ratio != done_ratio
            val_done_ratio = done_ratio
          end
        elsif done_ratio > 0
          val_done_ratio = done_ratio
        end

        val_status_id = nil
        row = TimeEntry.where("status_id is not null").first(:conditions => {:issue_id => issue_id}, :order => 'spent_on desc, id desc')
        if row
          if row.status_id != status_id
            val_status_id = status_id
          end
        else
            val_status_id = status_id
        end

        if val_done_ratio || val_status_id
          new_entry = TimeEntry.new(
                                    :project_id => project_id, 
                                    :issue_id => issue_id, 
                                    :user => User.current, 
                                    :spent_on => date
                                    )
          new_entry.hours = 0
          new_entry.activity_id = 0
          new_entry.done_ratio = val_done_ratio if val_done_ratio
          new_entry.status_id = val_status_id if val_status_id
          new_entry.save(:validate => false)
        end
      end

    module InstanceMethods

      def chart_update_issue
        RedmineCharts::IssuePatch.add_time_entry(self.project_id, self.id, self.status_id, self.done_ratio, Time.now)
      end

    end

  end
end