class IssueNoParentUpdateListener < Redmine::Hook::ViewListener
  def view_issues_form_details_bottom(context={ })
    issue = context[:issue]

    unless issue.id
      return #新規
    end
    unless issue.tracker.is_in_roadmap
      return #ロードマップに表示しないチケットはデフォルト挙動
    end
    
    #ロードマップに表示するチケットの場合のみ、
    #開始日/期日/優先度を子供の有無を問わず変更可能とする
    
    html = <<-"SCRIPT"
<script type='text/javascript'>
//<![CDATA[
$(function() {
  var elm;
  var attr;
  
  //issue_priority_id
  elm = $('#issue_priority_id');
  attr = elm.attr('disabled');
  if(typeof attr !== typeof undefined && attr !== false) {
    elm.removeAttr('disabled');
  }
  
  //issue_start_date
  elm = $('#issue_start_date');
  attr = elm.attr('disabled');
  if(typeof attr !== typeof undefined && attr !== false) {
    elm.removeAttr('disabled');
    elm.datepicker(datepickerOptions);
  }
  
  //issue_due_date
  elm = $('#issue_due_date');
  attr = elm.attr('disabled');
  if(typeof attr !== typeof undefined && attr !== false) {
    elm.removeAttr('disabled');
    elm.datepicker(datepickerOptions);
  }
});
//]]>
</script>
    SCRIPT
    html
  end
end