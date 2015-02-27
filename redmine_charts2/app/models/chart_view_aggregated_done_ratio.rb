class ChartViewAggregatedDoneRatio < ActiveRecord::Base

  def self.get_aggregation_for_issue(raw_conditions)
    conditions = {}
    conditions[:project_id] = raw_conditions[:project_ids]
    conditions[:day] = 0
    conditions[:week] = 0
    conditions[:month] = 0

    rows = all(:conditions => conditions)

    issues = {}

    rows.each do |row|
      issues[row.issue_id.to_i] = row.done_ratio.to_i
    end

    issues
  end

end
