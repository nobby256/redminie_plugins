# coding: utf-8

class IssueRemaining_HoursListener < Redmine::Hook::ViewListener

  def view_issues_show_details_bottom(context={ })
    begin
      issue = context[:issue]

      snippet = ''

      project = context[:project]

      #cH”‚Í—\’èH”‚ÆƒZƒbƒg‚Ìl‚¦B
      #—\’èH”‚ª”ñ•\¦‚Ìê‡‚ÍcH”‚à”ñ•\¦
      unless issue.disabled_core_fields.include?('estimated_hours')
        unless issue.remaining_hours.nil?
          snippet += "<tr><th>#{l(:field_remaining_hours)}</th><td>#{l_hours(issue.remaining_hours)}</td></tr>"
        end
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

      #cH”‚Í—\’èH”‚ÆƒZƒbƒg‚Ìl‚¦B
      #—\’èH”‚ª”ñ•\¦‚Ìê‡‚ÍcH”‚à”ñ•\¦
      if issue.safe_attribute? 'estimated_hours'
        if !issue.new_record?
          snippet += "<p><label for='remaining_hours'>#{l(:field_remaining_hours)}</label>"
          snippet += text_field_tag('remaining_hours', issue.remaining_hours, :size => 3, :disabled => !issue.leaf?)
          snippet += l(:field_hours)
          snippet += '</p>'
        end
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

    if issue.leaf? && params.include?(:remaining_hours)
      begin
        issue.remaining_hours = Float(params[:remaining_hours])
      rescue ArgumentError, TypeError
        issue.remaining_hours = nil
      end
    end
  end
end
