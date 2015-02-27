# coding: utf-8
class ChartsBurndownBaseController < ChartsController
  include Redmine::Utils::DateCalculation

  unloadable

  protected

  def get_data_core

    total_base_estimated_hours, total_estimated_hours, total_logged_hours, total_remaining_hours, total_predicted_hours, total_done, total_ideal_hours = get_data_for_burndown_chart

    max = 0
    remaining = []
    base_estimated = []
    estimated = []
    logged = []
    predicted = []
    ideal = []

    @range[:keys].each_with_index do |key, index|
      max = total_predicted_hours[index] if max < total_predicted_hours[index]
      max = total_estimated_hours[index] if max < total_estimated_hours[index]
      max = total_base_estimated_hours[index] if max < total_base_estimated_hours[index]

      base_estimated << [total_base_estimated_hours[index], l(:charts_burndown_hint_base_estimated, { :estimated_hours => RedmineCharts::Utils.round(total_base_estimated_hours[index]) })]
      estimated << [total_estimated_hours[index], l(:charts_burndown_hint_estimated, { :estimated_hours => RedmineCharts::Utils.round(total_estimated_hours[index]) })]
      ideal << [total_ideal_hours[index], l(:charts_burndown_hint_ideal, { :ideal_hours => RedmineCharts::Utils.round(total_ideal_hours[index]) })]
      if RedmineCharts::RangeUtils.date_from_day(key).to_time <= Time.now
        remaining << [total_remaining_hours[index], l(:charts_burndown2_hint_remaining, { :remaining_hours => RedmineCharts::Utils.round(total_remaining_hours[index]), :work_done => total_done[index] > 0 ? Integer(total_done[index]) : 0 })]
        logged  << [total_logged_hours[index], l(:charts_burndown_hint_logged, { :logged_hours => RedmineCharts::Utils.round(total_logged_hours[index]) })]
        if total_predicted_hours[index] > total_base_estimated_hours[index]
          predicted << [total_predicted_hours[index], l(:charts_burndown_hint_predicted_over_estimation, { :predicted_hours => RedmineCharts::Utils.round(total_predicted_hours[index]), :hours_over_estimation => RedmineCharts::Utils.round(total_predicted_hours[index] - total_base_estimated_hours[index]) }), true]
        else
          predicted << [total_predicted_hours[index], l(:charts_burndown_hint_predicted, { :predicted_hours => RedmineCharts::Utils.round(total_predicted_hours[index]) })]
        end
      end
    end

    sets = [
#      [l(:charts_burndown_group_base_estimated), base_estimated],
      [l(:charts_burndown_group_estimated), estimated],
      [l(:charts_burndown_group_predicted), predicted],
      [l(:charts_burndown_group_logged), logged],
      [l(:charts_burndown_group_remaining), remaining],
      [l(:charts_burndown_group_ideal), ideal],
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

    #末端のチケットのみ取得する
    issues = Issue.includes(:tracker).all(:conditions => conditions)
    issues_children = []
    issues.each do |issue|
      issues_children << issue.parent_id if RedmineCharts.has_sub_issues_functionality_active and issue.parent_id
    end
    issues.delete_if {|issue| issues_children.include?(issue.id)}

    rows, @range = ChartTimeEntry.get_timeline(:issue_id, @conditions, @range)

    estimated_hours_per_issue = {}
    estimated_hours_per_issue[0] ||= Array.new(@range[:keys].size, 0)
    issues_per_date = Array.new(@range[:keys].size, 0)
    issues.each do |issue|
      estimated_hours_per_issue[issue.id] ||= Array.new(@range[:keys].size, 0)

      #チケットの発生日がnilの場合は範囲の開始日をチケット発生日とする
      issue_add_date = issue.start_date ? issue.start_date : RedmineCharts::RangeUtils.date_from_unit(@range[:keys][0], @range[:range])
      issue_add_key = [RedmineCharts::RangeUtils.format_date_with_unit(issue_add_date, @range[:range]), @range[:keys].first].max

      @range[:keys].each_with_index do |key, i|
        #keyを日付に変換
        key_date = date_from_key(@range, i)
        if issue_add_key <= key
            #発生日以降のみカウントする。後程、進捗率の平均値を求める際に使用
          issues_per_date[i] += 1
        end
        if issue.estimated_hours
          if issue_add_key <= key
            #その日における工数を取得
            estimated_hours = get_estimated_hours(issue, key_date)
            #発生日に至るまでは工数はゼロ。
            estimated_hours_per_issue[issue.id][i] = estimated_hours
          end
        end
      end
    end

    #実績時間を求める
    #実績時間が発生し始めた日は範囲の開始日より古い可能性がある事を想定しなければならない
    current_logged_hours_per_issue = ChartTimeEntry.get_aggregation_for_issue(@conditions, @range)
    logged_hours_per_issue = {}
    logged_hours_per_issue[0] = Array.new(@range[:keys].size, current_logged_hours_per_issue[0] || 0)
    issues.each do |issue|
      logged_hours_per_issue[issue.id] ||= Array.new(@range[:keys].size, current_logged_hours_per_issue[issue.id] || 0)
    end
    rows.each do |row|
      index = @range[:keys].index(row.range_value.to_s)
      (0..(index-1)).each do |i|
        #rowsはrangeの範囲における実績時間
        #ogged_hours_per_issueはチケット毎の実績時間の総合計
        #rangeの範囲の実績時間を総合計から引くと、rangeの最初の日の実績時間が残る
        #仮に実績時間の発生日がrangeの範囲内に収まっている場合は、引き算をした結果、ゼロになる
        logged_hours_per_issue[row.group_id.to_i][i] -= row.logged_hours.to_f if logged_hours_per_issue[row.group_id.to_i]
      end
    end

    done_ratios_per_issue = ChartDoneRatio.get_timeline_for_issue(@conditions, @range)

    total_estimate_hours_for_done = Array.new(@range[:keys].size, 0)
    total_base_estimated_hours = Array.new(@range[:keys].size, 0)
    total_estimated_hours = Array.new(@range[:keys].size, 0)
    total_logged_hours = Array.new(@range[:keys].size, 0)
    total_remaining_hours = Array.new(@range[:keys].size, 0)
    total_predicted_hours = Array.new(@range[:keys].size, 0)
    total_done = Array.new(@range[:keys].size, 0)

    @range[:keys].each_with_index do |key,index|
      estimated_count = 0
      issues.each do |issue|
        logged = logged_hours_per_issue[issue.id] ? logged_hours_per_issue[issue.id][index] : 0
        #ポイント：進捗率の履歴が見つからなかった場合はissue.done_ratioではなくゼロ固定
        done_ratio = done_ratios_per_issue[issue.id] ? done_ratios_per_issue[issue.id][index] : 0
#        base_estimate = estimated_hours_per_issue[issue.id] ? estimated_hours_per_issue[issue.id][index] : 0
        if estimated_hours_per_issue[issue.id]
          base_estimate = estimated_hours_per_issue[issue.id][index]
          base_estimate ||= 0
        else
          base_estimate = 0
        end
        estimated = (done_ratio > 0 and logged > 0) ? (logged/done_ratio*100) : base_estimate
        total_remaining_hours[index] += done_ratio > 0 ? estimated * (100-done_ratio) / 100 : estimated

        total_logged_hours[index] += logged
        if issue.tracker.is_in_roadmap?
          total_base_estimated_hours[index] += base_estimate
        end
        total_estimated_hours[index] += base_estimate
        total_estimate_hours_for_done[index] += estimated #base_estimated
        if estimated > 0
          estimated_count += 1
        else
          total_done[index] += done_ratio
        end
      end

      total_logged_hours[index] += logged_hours_per_issue[0][index]

      if issues_per_date[index] > 0
        total_done[index] += (1 - (total_remaining_hours[index] / total_estimate_hours_for_done[index])) * 100 * estimated_count if total_estimate_hours_for_done[index] > 0
        total_done[index] /= issues_per_date[index]
      end

      total_predicted_hours[index] = total_remaining_hours[index] + total_logged_hours[index]

      total_logged_hours[index] = 0 if total_logged_hours[index] < 0.01
      total_base_estimated_hours[index] = 0 if total_base_estimated_hours[index] < 0.01
      total_estimated_hours[index] = 0 if total_estimated_hours[index] < 0.01
      total_remaining_hours[index] = 0 if total_remaining_hours[index] < 0.01
      total_done[index] = 0 if total_done[index] < 0.01
      total_predicted_hours[index] = 0 if total_predicted_hours[index] < 0.01
    end
    
    #理想線を求める
    #少々複雑な処理を行っている
    #
    #ポイント１
    #  理想線の開始日をいつにするのか？
    #  実績値がゼロの最終日（実績値発生の直前の日）を理想線を開始日とする
    #  ただし、range開始の時点で実績値がゼロより大きい場合は、range開始日を理想線の開始日とする
    #  なお、実績値が登録されていない場合はrange開始日を理想線の開始日とする
    #
    #ポイント２
    #  理想線の開始値は常に総工数とは限らない
    #  rangeの開始日の時点で残工数がいくらか減っているケースがある
    #  そのケースを考慮し、理想線の値をそのまま利用する事は行わない
    #
    start_logged_index = 0
    if !rows.empty?
      total_logged_hours.each_with_index do |v, i|
        (v == 0) ? start_logged_index = i : break
      end
    end
    working_per_date, total_working = get_working_per_date(@range, start_logged_index)
    total_ideal_hours = Array.new(@range[:keys].size, 0)
    ideal_diff = total_estimated_hours[0] - total_remaining_hours[0]
    working_per_date.each_with_index do |working_days, index|
      #total_ideal_hours[index] = RedmineCharts::Utils.round((total_estimated_hours[index] / total_working) * working_per_date[index]) if total_working > 0
      total_ideal_hours[index] = RedmineCharts::Utils.round(((total_estimated_hours[index] - ideal_diff) / total_working) * working_per_date[index]) if total_working > 0
      total_ideal_hours[index] = 0 if total_ideal_hours[index] < 0.01
    end
    
    [total_base_estimated_hours, total_estimated_hours, total_logged_hours, total_remaining_hours, total_predicted_hours, total_done, total_ideal_hours]
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

  def get_estimated_hours(issue, key_date)
    #journalから最新の工数を利用する
    unless @journal_estimation
      result = Issue.where("issues.project_id = ?", issue.project_id)
      result = result.where("issues.fixed_version_id is not null")
      result = result.where("journals.journalized_type = 'Issue'")
      result = result.where("prop_key = 'estimated_hours'")
      result = result.where("journal_details.value is not null")
      result = result.all(
        :select => 'issues.id as issue_id, convert(journals.created_on , date) day, journal_details.old_value as estimated_hours',
        :joins => 'join journals on issues.id = journals.journalized_id join journal_details on journals.id = journal_details.journal_id ',
        :order => 'day asc')
      @journal_estimation = {}
      result.each do |row|
        @journal_estimation[row.issue_id] ||= []
        @journal_estimation[row.issue_id] << { :date => row.day, :estimated_hours => row.estimated_hours }
      end
    end

    journals = @journal_estimation[issue.id]
    unless journals
      estimated_hours = issue.estimated_hours
    else
      estimated_hours = issue.estimated_hours
      journals.each do |row|
        if row[:date] > key_date
          estimated_hours = row[:estimated_hours]
          break
        end
      end
    end

    return estimated_hours
  end

  def date_from_key(range, i)
      #keyを日付に変換
      #rangeがweekやyearの場合、単純にRangeUtils.date_from_unitでキーを変換すると
      #週や年の最初の日が手に入る。
      #実際に欲しいのは対象の週/年の最終日。

      key_date = RedmineCharts::RangeUtils.date_from_unit(range[:keys][i], @range[:range])
      case range[:range]
      when :days
      when :weeks
        key_date += 6
      when :months
        key_date = (key_date >> 1) - 1
      end
      return key_date
  end

  def get_working_per_date(range, start_index)
    total = 0

    working_days = Array.new(@range[:keys].size, 0)
    ((start_index + 1) ... range[:keys].size).each do |i|
      case range[:range]
      when :days
        day = date_from_key(range, i)
        working_days[i] = is_holiday?(day) ? 0 : 1
        total += working_days[i]
      when :weeks, :months
        working_days[i] = 1
      end
    end

    working_per_date = Array.new(@range[:keys].size, total)
    ((start_index + 1) ... working_per_date.size).each do |i|
      value = 0
      (start_index .. i).each do |index|
        value += working_days[index]
      end
      working_per_date[i] = total - value
    end
    return [working_per_date, total]
  end
  
  def is_holiday?(date)
    non_working = non_working_week_days
    wday = date.cwday
    return true if non_working.include?(wday)

    unless @holidays
      @holidays = []
      if Redmine::Plugin.installed?(:redmine_work_time)
        #work_timeプラグインの休日登録機能を利用する
        rows = WtHolidays.where("deleted_on is null").all
        rows.each do |row|
          @holidays << row.holiday
        end
      end
    end
    
    return @holidays.include? date
  end

end
