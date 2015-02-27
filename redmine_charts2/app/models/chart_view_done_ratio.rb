class ChartViewDoneRatio < ActiveRecord::Base

  def self.get_timeline_for_issue(raw_conditions, range)
    conditions = {}
    done_ratios = {}

    raw_conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, table_name)
      conditions[column_name] = v if v and column_name
    end

    range = RedmineCharts::RangeUtils.prepare_range(range)

    range[:column] = RedmineCharts::ConditionsUtils.to_column(range[:range], table_name)

    joins = "left join issues on issues.id = issue_id"
    
    conditions[range[:column]] = range[:min]..range[:max]

    select = "#{range[:column]} as range_value, '#{range[:range]}' as range_type, #{table_name}.done_ratio, #{table_name}.issue_id"

    rows = all(:select => select, :joins => joins, :conditions => conditions, :order => "range_value asc, #{table_name}.day asc")

    rows.each do |row|
      done_ratios[row.issue_id.to_i] ||= Array.new(range[:keys].size, 0)
      index = range[:keys].index(row.range_value.to_s)
      next unless index
      (index...range[:keys].size).each do |i|
        done_ratios[row.issue_id.to_i][i] = row.done_ratio.to_i
      end
    end

    latest_done_ratio = ChartViewAggregatedDoneRatio.get_aggregation_for_issue(raw_conditions)

    latest_done_ratio.each do |issue_id, done_ratio|
      done_ratios[issue_id] ||= Array.new(range[:keys].size, done_ratio)
    end

    done_ratios
  end

end
