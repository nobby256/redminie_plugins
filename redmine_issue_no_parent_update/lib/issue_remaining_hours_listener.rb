class IssueRemaining_HoursListener < Redmine::Hook::ViewListener

  def view_issues_show_details_bottom(context={ })
    begin
      issue = context[:issue]

      snippet = ''

      project = context[:project]

      if issue.is_story?
        unless issue.remaining_hours.nil?
          snippet += "<tr><th>#{l(:field_remaining_hours)}</th><td>#{l_hours(issue.remaining_hours)}</td></tr>"
        end
      end

      if issue.is_task? && User.current.allowed_to?(:update_remaining_hours, project) != nil
          snippet += "<tr><th>#{l(:field_remaining_hours)}</th><td>#{l_hours(issue.remaining_hours)}</td></tr>"
      end

      return snippet
    rescue => e
      exception(context, e)
      return ''
    end
  end

  def view_issues_form_details_bottom(context={ })
    begin
      snippet = ''
      issue = context[:issue]

      if issue.is_task? && !issue.new_record?
        snippet += "<p><label for='remaining_hours'>#{l(:field_remaining_hours)}</label>"
        snippet += text_field_tag('remaining_hours', issue.remaining_hours, :size => 3)
        snippet += '</p>'
      end

      return snippet
    rescue => e
      exception(context, e)
      return ''
    end
  end

  def controller_issues_edit_before_save(context={ })
    params = context[:params]
    issue = context[:issue]

    if issue.is_task? && params.include?(:remaining_hours)
      begin
        issue.remaining_hours = Float(params[:remaining_hours])
      rescue ArgumentError, TypeError
        issue.remaining_hours = nil
      end
    end
  end
end
