$(document).on('ready', function(){
  $('#button_apply').on('click', function(){
      $('#chart_form_action').value = '';
      $('#page').value = '1';
      $('#chart_form').submit();
  });

  $('#add_filter_select').on('change', function(){
    $('#add_filter_select option:selected').each(function(){
      filter = $(this).attr('value');
      $('#cb_' + filter).attr('checked', true);
      toggle_filter(filter);
    });
    $(this).attr('value', '');
  });;
  
  $('table#filters').on('change', 'input[type="checkbox"]', function(){
    var field = $(this).attr('id').substr(3);
    toggle_filter(field);
  });

  function toggle_filter(field) {
    var select = $('#add_filter_select');
    var check_box = $('#cb_' + field);
    var values = $('#values_' + field);
    if (check_box.is(':checked')) {
      $('#tr_' + field).show();
      values.removeAttr('disabled');
      $('option[value="'+ field+'"]',select).attr('disabled', 'disabled');
    } else {
      $('#tr_' + field).hide();
      values.attr('disabled', 'disabled');
      $('option[value="'+ field+'"]',select).removeAttr('disabled');
    }
  }
  
  $('table#filters input[type="checkbox"]').each(function(){
    var field = $(this).attr('id').substr(3);
    toggle_filter(field);
  });

  $('#saved_condition_create').hide();
  $('#saved_condition_update').hide();

  function date_pagination( back ){
    var limit = parseInt($('#limit').attr('value'));
    var offset = parseInt($('#offset').attr('value'));
    var newOffset = offset + limit;
    if (back !== true){
      newOffset = offset - limit;
      if(newOffset < 1) {
          newOffset = 1;
      }
    }
    $('#offset').attr('value', newOffset);
    $('#offset').parents('form').submit();
  }

  $('.charts_earlier').click(function(){
    date_pagination(true);
  });
  $('.charts_later').click(function(){
    date_pagination();
  });

  function page_pagination(prev){
    var page = parseInt($('#page').attr('value'));
    var newPage = page +1;
    if (prev){
      if(page < 1) {
          newPage = 1;
      }
      newPage = page - 1;
    }
    $('#page').attr('value', newPage);
    $('#page').parents('form').submit();
  }

  $('.charts_previous').click(function(){
    page_pagination(true);
  });

  $('.charts_next').click(function(){
    page_pagination(); 
  });
});

