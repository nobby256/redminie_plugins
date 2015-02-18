# coding: utf-8
class ChartsBurndownBaseController < ChartsController

  unloadable

  protected

  def get_data_core

    total_estimated_hours, total_logged_hours, total_remaining_hours, total_predicted_hours, total_done, total_velocities = get_data_for_burndown_chart

    max = 0
    remaining = []
    estimated = []
    logged = []
    predicted = []

    @range[:keys].each_with_index do |key, index|
      max = total_predicted_hours[index] if max < total_predicted_hours[index]
      max = total_estimated_hours[index] if max < total_estimated_hours[index]

      estimated << [total_estimated_hours[index], l(:charts_burndown_hint_estimated, { :estimated_hours => RedmineCharts::Utils.round(total_estimated_hours[index]) })]
      if RedmineCharts::RangeUtils.date_from_day(key).to_time <= Time.now
          remaining << [total_remaining_hours[index], l(:charts_burndown2_hint_remaining, { :remaining_hours => RedmineCharts::Utils.round(total_remaining_hours[index]), :work_done => total_done[index] > 0 ? Integer(total_done[index]) : 0 })]
        logged  << [total_logged_hours[index], l(:charts_burndown_hint_logged, { :logged_hours => RedmineCharts::Utils.round(total_logged_hours[index]) })]
        if total_predicted_hours[index] > total_estimated_hours[index]
          predicted << [total_predicted_hours[index], l(:charts_burndown_hint_predicted_over_estimation, { :predicted_hours => RedmineCharts::Utils.round(total_predicted_hours[index]), :hours_over_estimation => RedmineCharts::Utils.round(total_predicted_hours[index] - total_estimated_hours[index]) }), true]
        else
          predicted << [total_predicted_hours[index], l(:charts_burndown_hint_predicted, { :predicted_hours => RedmineCharts::Utils.round(total_predicted_hours[index]) })]
        end
      end
    end

    velocity = []

    @range[:keys].size.times do |index|
      velocity << [total_velocities[index], l(:charts_burndown2_hint_velocity, { :remaining_hours => RedmineCharts::Utils.round(total_velocities[index])})]
    end

    velocity[velocity.size-1] = [0, l(:charts_burndown2_hint_velocity, { :remaining_hours => 0.0})]

    sets = [
      [l(:charts_burndown_group_estimated), estimated],
#        [l(:charts_burndown_group_logged), logged],
      [l(:charts_burndown2_group_velocity), velocity],
      [l(:charts_burndown_group_remaining), remaining],
      [l(:charts_burndown_group_predicted), predicted],
    ]

    {
      :labels => @range[:labels],
      :count => @range[:keys].size,
      :max => max > 0 ? max : 1,
      :sets => sets
    }

  end

  def get_data_for_burndown_chart
    conditions = {}

    @conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, 'issues')
      column_name = 'issues.id' if column_name == 'issues.issue_id'
      conditions[column_name] = v if v and column_name
    end

    issues = Issue.includes(:tracker).all(:conditions => conditions)

    # remove parent issues
    issues_children = []
    issues.each do |issue|
      issues_children << issue.parent_id if RedmineCharts.has_sub_issues_functionality_active and issue.parent_id
    end
    issues.delete_if {|issue| issues_children.include?(issue.id)}

    rows, @range = ChartTimeEntry.get_timeline(:issue_id, @conditions, @range)

    current_logged_hours_per_issue = ChartTimeEntry.get_aggregation_for_issue(@conditions, @range)

    done_ratios_per_issue = ChartDoneRatio.get_timeline_for_issue(@conditions, @range)

    total_estimate_hours = Array.new(@range[:keys].size, 0)
    total_base_estimated_hours = Array.new(@range[:keys].size, 0)
    total_logged_hours = Array.new(@range[:keys].size, 0)
    total_remaining_hours = Array.new(@range[:keys].size, 0)
    total_predicted_hours = Array.new(@range[:keys].size, 0)
    total_done = Array.new(@range[:keys].size, 0)
    total_velocities = Array.new(@range[:keys].size, 0)
    issues_per_date = Array.new(@range[:keys].size, 0)
    logged_hours_per_issue = {}
    estimated_hours_per_issue = {}
    velocities_per_issue = {}

    logged_hours_per_issue[0] = Array.new(@range[:keys].size, current_logged_hours_per_issue[0] || 0)
    estimated_hours_per_issue[0] ||= Array.new(@range[:keys].size, 0)

    issues.each do |issue|
      logged_hours_per_issue[issue.id] ||= Array.new(@range[:keys].size, current_logged_hours_per_issue[issue.id] || 0)
      estimated_hours_per_issue[issue.id] ||= Array.new(@range[:keys].size, 0)
      velocities_per_issue[issue.id] ||= Array.new(@range[:keys].size, 0)

      issue_start_date = issue.created_on.to_date
      range_start_date = issue.created_on.to_date
      if issue.start_date
        issue_start_date = issue.start_date if issue.start_date > issue.created_on.to_date
        range_start_date = issue.start_date if issue.start_date < issue.created_on.to_date
      end

      issue_start_key = [RedmineCharts::RangeUtils.format_date_with_unit(issue_start_date, @range[:range]), @range[:keys].first].max
      range_start_key = [RedmineCharts::RangeUtils.format_date_with_unit(range_start_date, @range[:range]), @range[:keys].first].max
      range_end_key = issue.due_date ? [RedmineCharts::RangeUtils.format_date_with_unit(issue.due_date, @range[:range]), @range[:keys].last].min : @range[:keys].last

      range_start_date = RedmineCharts::RangeUtils.date_from_unit(range_start_key, @range[:range])
      range_end_date = RedmineCharts::RangeUtils.date_from_unit(range_end_key, @range[:range])
      range_diff_days = (range_end_date - issue_start_date) #オリジナルのバグ？ issue_start_dateはrange_start_dateの可能性あり
      #range_diff_days = (range_end_date - range_start_date)

      @range[:keys].each_with_index do |key, i|
        if range_start_key <= key
          if issue.estimated_hours
            if key <= range_end_key
              velocities_per_issue[issue.id][i] =
                (range_diff_days > 0 and key > issue_start_key) ?
                (issue.estimated_hours * (range_end_date - RedmineCharts::RangeUtils.date_from_unit(key, @range[:range])) / range_diff_days) :
                issue.estimated_hours
            end
            estimated_hours_per_issue[issue.id][i] = issue.estimated_hours
          end
          issues_per_date[i] += 1
        end
      end
    end

    rows.each do |row|
      index = @range[:keys].index(row.range_value.to_s)
      (0..(index-1)).each do |i|
        logged_hours_per_issue[row.group_id.to_i][i] -= row.logged_hours.to_f if logged_hours_per_issue[row.group_id.to_i]
      end
    end
    @range[:keys].each_with_index do |key,index|
      estimated_count = 0
      issues.each do |issue|
        logged = logged_hours_per_issue[issue.id] ? logged_hours_per_issue[issue.id][index] : 0
        done_ratio = done_ratios_per_issue[issue.id] ? done_ratios_per_issue[issue.id][index] : 0
        base_estimate = estimated_hours_per_issue[issue.id] ? estimated_hours_per_issue[issue.id][index] : 0
        estimated = (done_ratio > 0 and logged > 0) ? (logged/done_ratio*100) : base_estimate
        total_remaining_hours[index] += done_ratio > 0 ? estimated * (100-done_ratio) / 100 : estimated
        velocity = velocities_per_issue[issue.id] ? velocities_per_issue[issue.id][index] : 0

        total_logged_hours[index] += logged
        if issue.tracker.is_in_roadmap?
          total_base_estimated_hours[index] += base_estimate
          total_estimate_hours[index] += estimated
          total_velocities[index] += velocity
        end
        if estimated > 0
          estimated_count += 1
        else
          total_done[index] += done_ratio
        end
      end

      total_logged_hours[index] += logged_hours_per_issue[0][index]

      if issues_per_date[index] > 0
        total_done[index] += (1 - (total_remaining_hours[index] / total_estimate_hours[index])) * 100 * estimated_count if total_estimate_hours[index] > 0
        total_done[index] /= issues_per_date[index]
      end

      total_predicted_hours[index] = total_remaining_hours[index] + total_logged_hours[index]

      total_logged_hours[index] = 0 if total_logged_hours[index] < 0.01
      total_base_estimated_hours[index] = 0 if total_base_estimated_hours[index] < 0.01
      total_remaining_hours[index] = 0 if total_remaining_hours[index] < 0.01
      total_done[index] = 0 if total_done[index] < 0.01
      total_predicted_hours[index] = 0 if total_predicted_hours[index] < 0.01
      total_velocities[index] = 0 if total_velocities[index] < 0.01
    end

    [total_base_estimated_hours, total_logged_hours, total_remaining_hours, total_predicted_hours, total_done, total_velocities]
  end

  def get_title
    raise "overwrite it"
  end

  def get_help
    l(:charts_burndown_help)
  end

  def get_x_legend
    l(:charts_burndown_x)
  end

  def get_y_legend
    l(:charts_burndown_y)
  end

  def get_current_fixed_version_in(project)
    version = Version.all(:conditions => {:project_id => project.id}).detect do |version|
      version.created_on.to_date <= Date.current && !version.effective_date.nil? && version.effective_date >= Date.current
    end
    if version
      [version.id]
    else
      versions = RedmineCharts::ConditionsUtils.to_options(project, [:fixed_version_ids])[:fixed_version_ids]
      unless versions.nil? || versions.empty?
        [versions.first[1]]
      else
        []
      end
    end
  end

end
