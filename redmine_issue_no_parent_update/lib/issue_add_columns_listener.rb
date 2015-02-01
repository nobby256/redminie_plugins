# coding: utf-8

class IssueAddColumnsListener < Redmine::Hook::ViewListener

  def view_issues_show_details_bottom(context={ })
    begin
      issue = context[:issue]

      snippet = ''

      project = context[:project]

      #�T�u�J�e�S���̓J�e�S���ƃZ�b�g�̍l���B
      #�J�e�S������\���̏ꍇ�̓T�u�J�e�S������\��
      unless issue.disabled_core_fields.include?('categories')
        unless issue.sub_category
          snippet += "<tr><th>#{l(:field_sub_category)}</th><td>#{issue.sub_category.name}</td></tr>"
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

      #�c�H���͗\��H���ƃZ�b�g�̍l���B
      #�\��H������\���̏ꍇ�͎c�H������\��
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
