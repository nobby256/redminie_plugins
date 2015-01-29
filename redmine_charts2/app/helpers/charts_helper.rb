module ChartsHelper

  def self.l(s)
    s
  end

  # Shows chart plugin menu.
  def show_charts_menu
    res = ""
    RedmineCharts::Utils.controllers_for_routing do |name, controller_name|      
      link_name = l("charts_link_#{name}".to_sym)

      if controller.controller_name == controller_name
        res << link_name << "<br /> "
      else
        res << link_to(link_name, :controller => controller_name, :project_id => @project) << "<br /> "
      end
    end
    res
  end

  # Shows chart flash setting path to data.
  def show_graph(data)
    div_name = 'flash_content_leRRmNzK'
    relative_url_path = ActionController::Base.respond_to?(:relative_url_root) ?     ActionController::Base.relative_url_root : ActionController::AbstractRequest.relative_url_root
    
    html = "<div id=\"#{div_name}\"></div>"
    html << '<script type="text/javascript">' << "\n"
    html << "function open_flash_chart_inline_data() {\n"
    html << "return '#{data.gsub("'","\\\\'").gsub('"','\\\\"')}';\n"     
    html << "};\n"
    html << "swfobject.embedSWF('#{relative_url_path}/plugin_assets/open_flash_chart/open-flash-chart.swf', '#{div_name}', '100%', '400', '9.0.0', 'expressInstall.swf', {'get-data':'open_flash_chart_inline_data'});"
    html << "\nvar charts_to_image_title = '#{h(controller.controller_name)}';\n"
    html << "var charts_to_image_id = '#{div_name}';\n"
    html << '</script>'

    html
  end

  # Shows date condition.
  def show_date_condition(limit, range, offset)
    res = ""
    res << l(:charts_show_last) << " "
    res << text_field_tag(:limit, limit, :size => 4)
    res << hidden_field_tag(:offset, offset) << " "
    res << select_tag(:range, options_for_select(RedmineCharts::RangeUtils.options, range.to_sym))

    res << '&nbsp; &nbsp;'

    # Pagination.

    res << content_tag(:a, l(:charts_earlier), :class => 'charts_earlier', :href => '#') << " - "

    if offset.to_i == 1
      res << l(:charts_later)
    else
      res << content_tag(:a, l(:charts_later), :class => 'charts_later', :href => '#')
    end

    res
  end

  # Shows pages.
  def show_pages(page, pages)
    res = ""

    if pages > 1
      if page == 1
        res << l(:charts_previous)
      else
        res << content_tag(:a, l(:charts_previous), :class => 'charts_previous', :href => '#')
      end

      res << ' - '

      if page == pages
        res << l(:charts_next)
      else
        res << content_tag(:a, l(:charts_next), :class => 'charts_next', :href => '#')
      end
    end

    res
  end

end
