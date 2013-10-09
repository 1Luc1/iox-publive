function setupEnsemble( ensemble_id ){

  function MembersViewModel(){
    this.data = ko.observableArray();
  }

  var membersData = new MembersViewModel();

  $('#ensemble_logo').fileupload({
    dataType: 'json',
    formData: {
      "authenticity_token": $('input[name="authenticity_token"]:first').val()
    },
    done: function (e, data) {
      var logo = data._response.result[0];
      $('.logo[data-ensemble-id='+ensemble_id+']').attr('src', logo.thumbnail_url);
    }
  });


  $('.country-select').select2();


}