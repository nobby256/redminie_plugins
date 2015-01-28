# coding: utf-8

class VersionBurndownChartsController < ApplicationController
  unloadable
  menu_item :version_burndown_charts
  before_filter :find_project, :find_versions, :find_version_issues, :find_burndown_dates, :find_version_info, :find_issues_closed_status
  
  def index
    relative_url_path =
      ActionController::Base.respond_to?(:relative_url_root) ? ActionController::Base.relative_url_root : ActionController::AbstractRequest.relative_url_root

    @graph =
      open_flash_chart_object( 880, 450,
        url_for( :action => 'get_graph_data', :project_id => @project.id, :version_id => @version.id ),
          true, "#{relative_url_path}/plugin_assets/open_flash_chart/" )
  end

  def get_graph_data
    
    estimated_data_array = []
    performance_data_array = []
    perfect_data_array = []
    upper_data_array = []
    lower_data_array = []
    x_labels_data = []
    
    index_date = @start_date - 1
    index_estimated_hours = @estimated_hours
    index_performance_hours = @estimated_hours
    count = 1
    
    while index_date <= (@version.due_date + 1)
      logger.debug("index_date #{index_date}")

      if index_date < @start_date
        # ready
        estimated_data_array << index_estimated_hours
        performance_data_array << index_performance_hours
        index_date += 1
        count += 1
        next
      elsif index_date == @start_date || index_date == @version.due_date
        x_labels_data << index_date.strftime("%m/%d")
      elsif @sprint_range > 20
        period = count % (@sprint_range / 3).round
        if (period != 0) || (period == 3)
          x_labels_data << ""
        else
          x_labels_data << index_date.strftime("%m/%d")
        end
      else
        x_labels_data << index_date.strftime("%m/%d")
      end
      estimated_data_array << round(index_estimated_hours -= calc_estimated_hours_by_date(index_date))
      index_performance_hours = calc_performance_hours_by_date(index_date)
      performance_data_array << round(index_performance_hours)
      perfect_data_array << 0
      upper_data_array << 0
      lower_data_array << 0

      logger.debug("#{index_date} index_estimated_hours #{round(index_estimated_hours)}")
      logger.debug("#{index_date} index_performance_hours #{round(index_performance_hours)}")
      
      index_date += 1
      count += 1
    end

    perfect_data_array.fill {|i| round(@estimated_hours - (@estimated_hours / @sprint_range * i)) }
    upper_data_array.fill {|i| round((@estimated_hours - (@estimated_hours / @sprint_range * i)) * 1.2) }
    lower_data_array.fill {|i| round((@estimated_hours - (@estimated_hours / @sprint_range * i)) * 0.8) }
    create_graph(x_labels_data, estimated_data_array, performance_data_array, perfect_data_array, upper_data_array, lower_data_array)
  end

  def create_graph(x_labels_data, estimated_data_array, performance_data_array, perfect_data_array, upper_data_array, lower_data_array)
    chart =OpenFlashChart.new
    chart.set_title(Title.new("#{@version.name} #{l(:version_burndown_charts)}"))
    chart.set_bg_colour('#ffffff');

    x_legend = XLegend.new("#{l(:version_burndown_charts_xlegend)}")
    x_legend.set_style('{font-size: 20px; color: #000000}')
    chart.set_x_legend(x_legend)

    y_legend = YLegend.new("#{l(:version_burndown_charts_ylegend)}")
    y_legend.set_style('{font-size: 20px; color: #000000}')
    chart.set_y_legend(y_legend)

    x = XAxis.new
    x.set_range(0, @sprint_range + 1, 1)
    x.set_labels(x_labels_data)
    chart.x_axis = x

    y = YAxis.new
    y.set_range(0, round(@estimated_hours * 1.2 + 1), (@estimated_hours / 6).round)
    chart.y_axis = y

    add_line(chart, "#{l(:version_burndown_charts_upper_line)}", 1, '#dfdf3f', 4, upper_data_array)
    add_line(chart, "#{l(:version_burndown_charts_lower_line)}", 1, '#3f3fdf', 4, lower_data_array)
    add_line(chart, "#{l(:version_burndown_charts_perfect_line)}", 3, '#bbbbbb', 6, perfect_data_array)
    add_line(chart, "#{l(:version_burndown_charts_estimated_line)}", 2, '#00a497', 4, estimated_data_array)
    add_line(chart, "#{l(:version_burndown_charts_peformance_line)}", 3, '#bf0000', 6, performance_data_array)

    render :text => chart.to_s
  end

  def add_line(chart, text, width, colour, dot_size, values)
    my_line = Line.new
    my_line.text = text
    my_line.width = width
    my_line.colour = colour
    my_line.dot_size = dot_size
    my_line.values = values
    chart.add_element(my_line)
  end

  def is_leaf(issue)
    if !(defined?(issue.rgt) and defined?(issue.lft)) then
      return true
    end
    if issue.rgt - issue.lft == 1 then
      return true
    else
      return false
    end
  end

  def calc_estimated_hours_by_date(target_date)
    target_issues = @estimated_issues.select { |issue| issue.due_date == target_date}
    target_hours = 0
    target_issues.each do |issue|
      target_hours += round(issue.estimated_hours)
    end
    logger.debug("#{target_date} estimated hours = #{target_hours}")
    return target_hours
  end

  #指定日の時点でのバージョン内の総残工数を求めます
  def calc_performance_hours_by_date(target_date)
    target_hours = 0
    @version_issues.each do |issue|
      target_hours += calc_issue_performance_hours_by_date(target_date, issue)
    end
    logger.debug("issues remaining hours #{target_hours} #{target_date}")
p "issues remaining hours #{target_hours} #{target_date}"
    return target_hours
  end

  #指定日の時点での特定チケットの残工数を求めます
  def calc_issue_performance_hours_by_date(target_date, issue)
    sql = <<"QUERY"
select
  t2.value as value
  , t2.old_value as old_value
  , t1.created_on as created_on
from
  ( 
    select
      * 
    from
      journals 
    where
      journalized_id = :issue_id 
      and journalized_type = 'Issue' 
  ) as t1 join ( 
    select
      * 
    from
      journal_details 
    where
      property = 'attr' 
      and prop_key = 'remaining_hours'
  ) as t2 
    on t1.id = t2.journal_id 
order by
  t1.created_on asc
QUERY
    results = Journal.find_by_sql([sql, {:issue_id => issue.id}]);

    #ここ以降はcreated_onの昇順でソートされている前提の処理
    less_eq_result = nil #指定の日以下の最終レコード
    greater_result = nil #指定の日を超えた直後のレコード
    results.each do |result|
      less_eq_result = result
      if result.created_on > target_date
        greater_result = result
        break
      end
    end
    if less_eq_result.nil? && greater_result.nil?
      #変更履歴がゼロの場合
      #チケットの残工数は一度も変更されていない
      remaining_hours_by_date = issue.remaining_hours
    elsif !less_eq_result.nil?
      #対象の日依然の履歴が発見できた場合
      remaining_hours_by_date = less_eq_result.value
    elsif less_eq_result.nil? && !greater_result.nil?
      #対象の日より前に修正が一度も行われていなかった場合
      #対象の日より後に変更が行われているはずなので、変更前の値を採用
      remaining_hours_by_date = greater_result.old_value
    end
    unless remaining_hours_by_date
      remaining_hours_by_date = 0.0
    end
    return remaining_hours_by_date.to_f
  end

  def round(value)
    unless value
      return 0
    else
      return (value.to_f * 1000.0).round / 1000.0
    end
  end

  def find_project

    logger.debug("params[:project_id].class #{params[:project_id].class}")

    if params[:project_id].blank?
      flash[:error] = l(:version_burndown_charts_project_nod_found, :project_id => 'parameter not found.')
      render_404
      return
    end

    begin
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = l(:version_burndown_charts_project_nod_found, :project_id => params[:project_id])
      render_404
      return
    end 
  end

  def find_versions
    versions = @project.versions.select(&:effective_date).sort_by(&:effective_date)
    @open_versions = versions.select{|version| version.status == 'open'}
    @locked_versions = versions.select{|version| version.status == 'locked'}
    @closed_versions = versions.select{|version| version.status == 'closed'}
    if params[:version_id]
      @version = Version.find(params[:version_id])
    else
      # First display case.
      @version = @open_versions.first || versions.last
    end

    logger.debug("@version.class #{@version.class}")
    logger.debug("@version.nil? #{@version.nil?}")

    if @version.blank?
      flash[:error] = l(:version_burndown_charts_no_version_with_due_date)
      render_404
      return
    end

    unless @version.due_date
      flash[:error] = l(:version_burndown_charts_version_due_date_not_found, :version_name => @version.name)
      render :action => "index" and return false
    end
  end

  def find_version_issues
    #末端（leaf）のチケットのみを収集
    @version_issues = Issue.find_by_sql([
          "select * from issues
             where fixed_version_id = :version_id and
               remaining_hours is not NULL and (rgt - lft) = 1",
                 {:version_id => @version.id}])
    if @version_issues.empty?
      flash[:error] = l(:version_burndown_charts_issues_not_found, :version_name => @version.name)
      render :action => "index" and return false
    end
  end

  def find_burndown_dates
    @start_date = @version_issues[0].start_date
    if @version.due_date <= @start_date
      flash[:error] = l(:version_burndown_charts_version_start_date_invalid, :version_name => @version.name)
      render :action => "index" and return false
    end

    @sprint_range = (@version.due_date - @start_date + 1).to_i

    logger.debug("@start_date #{@start_date}")
    logger.debug("@version.due_date #{@version.due_date}")
    logger.debug("@sprint_range = #{@sprint_range}")
  end

  def find_version_info
    @closed_pourcent = (@version.closed_pourcent * 100).round / 100
    @open_pourcent = 100 - @closed_pourcent
    @estimated_issues = Issue.find_by_sql([
          "select * from issues
              where fixed_version_id = :version_id and 
                    exists (select * from trackers where issues.tracker_id=trackers.id and trackers.is_in_roadmap=1) and
                    start_date is not NULL and estimated_hours is not NULL and parent_id is NULL",
                 {:version_id => @version.id}])
    @estimated_hours = 0
    @estimated_issues.each do |issue|
      @estimated_hours += round(issue.estimated_hours)
    end
    if @estimated_hours == 0
      flash[:error] = l(:version_burndown_charts_issues_start_date_or_estimated_date_not_found, :version_name => @version.name)
      render :action => "index" and return false
    end
    logger.debug("@estimated_hours #{@estimated_hours}")
  end

  def find_issues_closed_status
    @closed_statuses = IssueStatus.find_all_by_is_closed(true)
    logger.debug("@closed_statuses #{@closed_statuses}")
  end
end
