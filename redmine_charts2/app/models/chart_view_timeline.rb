class ChartViewTimeline < ActiveRecord::Base

  belongs_to :issue

  def self.get_timeline(raw_group, raw_conditions, range)
    group = RedmineCharts::GroupingUtils.to_column(raw_group, table_name)

    conditions = {}

    raw_conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, table_name)
      conditions[column_name] = v if v and column_name
    end

    joins = "left join issues on issues.id = issue_id"

    unless range
      row = first(:select => "month, week, day", :joins => joins, :conditions => ["day > 0 AND #{table_name}.project_id in (?)", conditions["#{table_name}.project_id"]], :readonly => true, :order => "1 asc, 2 asc, 3 asc")

      if row
        range = RedmineCharts::RangeUtils.propose_range({ :month => row.month, :week => row.week, :day => row.day })
      else
        range = RedmineCharts::RangeUtils.default_range
      end
    end

    range = RedmineCharts::RangeUtils.prepare_range(range)

    range[:column] = RedmineCharts::ConditionsUtils.to_column(range[:range], table_name)

    select = "#{range[:column]} as range_value, '#{range[:range]}' as range_type, sum(logged_hours) as logged_hours, sum(entries) as entries, '#{raw_group}' as grouping"

    if group
      select << ", #{group} as group_id"
    else
      select << ", 0 as group_id"
    end

    conditions[range[:column]] = range[:min]..range[:max]

    grouping = "#{range[:column]}"
    grouping << ", #{group}" if group

    rows = all(:joins => joins, :select => select, :conditions => conditions, :readonly => true, :group => grouping, :order => "1 asc, 6 asc")

    rows.each do |row|
      row.group_id = '0' unless row.group_id
    end

    [rows, range]
  end

  def self.get_aggregation_for_issue(raw_conditions, range)
    group = RedmineCharts::GroupingUtils.to_column(:issue_id, table_name)

    conditions = {}

    raw_conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, table_name)
      conditions[column_name] = v if v and column_name
    end

    range = RedmineCharts::RangeUtils.prepare_range(range)
    
    range[:column] = RedmineCharts::ConditionsUtils.to_column(range[:range], table_name)

    conditions[range[:column]] = '1'..range[:max]

    joins = "left join issues on issues.id = issue_id"
    select = "sum(logged_hours) as logged_hours, #{table_name}.issue_id as issue_id"

    rows = all(:joins => joins, :select => select, :conditions => conditions, :readonly => true, :group => group, :order => "1 desc, 2 asc")

    issues = {}

    rows.each do |row|
      issues[row.issue_id.to_i] = row.logged_hours.to_f
    end

    issues
  end

  def self.get_logged_start_date(raw_conditions)
    conditions = {}

    raw_conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, table_name)
      conditions[column_name] = v if v and column_name
    end

    joins = "left join issues on issues.id = issue_id"

    column_name = RedmineCharts::ConditionsUtils.to_column(:days, table_name)

    select = "#{column_name} as unit_value"

    rows = where("#{column_name} != 0").all(:joins => joins, :select => select, :conditions => conditions, :readonly => true, :order => "1 asc", :limit => 1)
    if rows.empty?
      return nil
    end
    unit = rows.first[:unit_value]
    date = RedmineCharts::RangeUtils.date_from_day(unit.to_s)
    
    return date
  end

end
