# coding: utf-8

class IssueAddColumnsListener < Redmine::Hook::ViewListener

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
