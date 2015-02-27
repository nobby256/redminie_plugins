class ChartViewAggregatedTimeline < ActiveRecord::Base

  belongs_to :issue

  def self.get_aggregation(raw_group, raw_conditions)
    raw_group ||= :user_id
    group = RedmineCharts::GroupingUtils.to_column(raw_group, table_name)

    conditions = {}

    raw_conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, table_name)
      conditions[column_name] = v if v and column_name
    end

    conditions[:day] = 0
    conditions[:week] = 0
    conditions[:month] = 0

    joins = "left join issues on issues.id = issue_id"

    select = "sum(logged_hours) as logged_hours, sum(entries) as entries, #{group} as group_id, '#{raw_group}' as grouping"

    if group == "#{table_name}.issue_id"
      select << ", issues.estimated_hours as estimated_hours, issues.subject as subject"
      group << ", issues.estimated_hours, issues.subject"

      if RedmineCharts.has_sub_issues_functionality_active
        select << ", issues.root_id, issues.parent_id"
        group << ", issues.root_id, issues.parent_id"
      else
        select << ", #{table_name}.issue_id as root_id, null as parent_id"
      end
    else
      select << ", 0 as estimated_hours"
    end

    rows = all(:joins => joins, :select => select, :conditions => conditions, :readonly => true, :group => group, :order => "1 desc, 3 asc")

    rows.each do |row|
      row.group_id = '0' unless row.group_id
      row.estimated_hours = '0' unless row.estimated_hours
    end
  end

end
