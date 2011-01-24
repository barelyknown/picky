// If this returns true there were errors.
//
function handleErrors(data) {
  var error = false;
  $.each(data, function(index, element) {
    if (element == 'ERROR') {
      $('#parameters').find('.' + index + ' .error').html('Error in this config, not updated.');
      error = true;
    } else {
      $('#parameters').find('.' + index + ' .error').html('');
    }
  });
  return error;
};

function updateParameter(name, data) {
  var input = $('#parameters .' + name + ' input');
  if (input.val() != data[name]) {
    input.val(data[name]);
    $('#parameters').find('.' + name + ' .error').html('Updated.');
  }
};

function updateParameters(data) {
  if (handleErrors(data)) { return; };
  updateParameter('querying_removes_characters', data);
  updateParameter('querying_stopwords', data);
  updateParameter('querying_splits_text_on', data);
};

function getParameters() {
  var data = {};
  
  var querying_removes_characters = $('#parameters .querying_removes_characters input').val();
  if (querying_removes_characters != '') { data['querying_removes_characters'] = querying_removes_characters; };
  
  var querying_stopwords = $('#parameters .querying_stopwords input').val();
  if (querying_stopwords != '') { data['querying_stopwords'] = querying_stopwords; };
  
  var querying_splits_text_on = $('#parameters .querying_splits_text_on input').val();
  if (querying_splits_text_on != '') { data['querying_splits_text_on'] = querying_splits_text_on; };
  
  $.ajax({
    url: 'index.json',
    data: data,
    success: function(data) {
      data = $.parseJSON(data);
      updateParameters(data);
      $('#actions .status').html('Server set with the following data (if it\'s still the same, check your config changes).').fadeOut(2500);
    }
  });
};