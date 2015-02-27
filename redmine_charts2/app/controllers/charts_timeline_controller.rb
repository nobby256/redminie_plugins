# coding: utf-8
class ChartsTimelineController < ChartsController

  unloadable
  
  protected

  def get_data
    @grouping ||= :user_id

    start_date = get_logged_start_date(@conditions)
    unless start_date
      return { :error => :charts_error_no_data }
    end
    start_date -= 1 #もっとも古い実績時間の一日前

    #このチャートは全バージョンが対象のチャートなので
    #バージョンを絞り込む必要性はない
    versions = Version.where("project_id=?", @project.id)
                      .where("effective_date is not null")
                      .order("effective_date desc")
                      .limit(1)
                      .all
    if versions.empty?
      end_date = Time.now.to_date
    else
      end_date = versions.first[:effective_date]
      #なにかのミスでバージョン期日より開始日が未来日の場合はリカバリーする
      end_date = Time.now.to_date if end_date < start_date
    end

    @range = RedmineCharts::RangeUtils.propose_range_for_two_dates(start_date, end_date)
    rows, @range = ChartTimeEntry.get_timeline(@grouping, @conditions, @range)

    sets = {}
    max = 0

    
    if rows.size > 0
      rows.each do |row|
        group_name = RedmineCharts::GroupingUtils.to_string(row.group_id, @grouping)
        # Issue 13 
        val = row.range_value.to_s
        if (@range[:range] == :weeks) && (val =~ /000$/)
          val = RedmineCharts::RangeUtils.format_week(Date.new(val[0,4].to_i));
        end
        index = @range[:keys].index(val)
        if index
          sets[group_name] ||= Array.new(@range[:keys].size, [0, get_hints(group_name, nil)])
          sets[group_name][index] = [row.logged_hours.to_f, get_hints(group_name, row)]
          max = row.logged_hours.to_f if max < row.logged_hours.to_f
        else
          raise row.range_value.to_s
        end
      end
    else
      sets[""] ||= Array.new(@range[:keys].size, [0, get_hints(RedmineCharts::GroupingUtils.to_string(nil, @grouping), nil)])
    end

    sets = sets.sort.collect { |name, values| [name, values] }

    {
      :labels => @range[:labels],
      :count => @range[:keys].size,
      :max => max > 1 ? max : 1,
      :sets => sets
    }
  end

  def get_hints(group_name, record = nil)
    unless record.nil?
      l(:charts_timeline_hint, { :group_name => group_name, :hours => RedmineCharts::Utils.round(record.logged_hours), :entries => record.entries.to_i })
    else
      l(:charts_timeline_hint_empty, { :group_name => group_name} )
    end
  end

  def get_title
    l(:charts_link_timeline)
  end
  
  def get_help
    l(:charts_timeline_help)
  end

  def get_type
    :line
  end

  def get_x_legend
    l(:charts_timeline_x)
  end
  
  def get_y_legend
    l(:charts_timeline_y)
  end

  def show_date_condition
    false
  end

  def get_grouping_options
    [ :none, RedmineCharts::GroupingUtils.types ].flatten
  end

  def get_multiconditions_options
#    RedmineCharts::ConditionsUtils.types
    (RedmineCharts::ConditionsUtils.types - [:project_ids, :fixed_version_ids]).flatten
  end

  private

  def get_logged_start_date(raw_conditions)
    conditions = {}

    raw_conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, "chart_time_entries")
      conditions[column_name] = v if v and column_name
    end

    joins = "left join issues on issues.id = issue_id"

    column_name = RedmineCharts::ConditionsUtils.to_column(:days, "chart_time_entries")

    select = "#{column_name} as unit_value"

    rows = ChartTimeEntry.where("#{column_name} != 0").all(:joins => joins, :select => select, :conditions => conditions, :readonly => true, :order => "1 asc", :limit => 1)
    if rows.empty?
      return nil
    end
    unit = rows.first[:unit_value]
    date = RedmineCharts::RangeUtils.date_from_day(unit.to_s)
    
    return date
  end

end
