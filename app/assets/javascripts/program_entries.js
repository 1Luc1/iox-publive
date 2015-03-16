// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

//= require 3rdparty/jquery.smartWizard-2.0.min
//= require 3rdparty/bootstrap.datepicker
//= require 3rdparty/lightbox.min

//= require 3rdparty/jquery.fileupload

//= require iox/common
//= require iox/ensembles
//= require iox/venues

$(document).ready(function(){

  setupPEEvents();

});

function setupPEEvents(){

  $('.coproduction').select2({
    tags: [],
    tokenSeparators: [","]
  });

  $('.meta-keywords').select2({
    tags: [],
    tokenSeparators: [","]
  });

  $('.categories-tags').select2({
    tags: [],
    tokenSeparators: [","]
  });

  $('.select2').select2();

  $(".age-slider").slider({
    value: 0,
    min: 0,
    max: 20,
    slide: function( event, ui ) {
      $('#program_entry_age').val( ui.value );
    }
  });

  $(".duration-slider").slider({
    value: 90,
    min: 5,
    max: 480,
    slide: function( event, ui ) {
      $('#program_entry_duration').val( ui.value );
    }
  });

  $('#program_entry_duration').on('change', function(e){
    $('.duration-slider').slider( "value", this.value );
  });

  $('#program_entry_age').on('change', function(e){
    $('.age-slider').slider( "value", this.value );
  });

  $('.event-type').select2({
    tags: ['Premiere', 'Derniere', 'Abgesagt'],
    tokenSeparators: [","]
  });

  $('.swMain ul.anchor a.disabled').on('click', function(){
    $.blockUI({ message: $('#finish_step1_first')});
  });

  $('.edit-select2-btn').on('click', function(e){
    e.preventDefault();
    var sel = $(this).parent().find('select');
    if( !sel.find('option:selected') || sel.find('option:selected').val() === '' )
      return;
    var $newDtls = $('<div class="iox-details-container iox-content">').append( iox.loader );
    $('.iox-content').after( $newDtls );
    $('.iox-content').hide();
    $newDtls.show().load( sel.attr('data-url')+'/'+sel.find('option:selected').val()+'/edit?layout=false' );
  });

  if( $('#person_avatar').length )
    setupPersonAvatarUpload();

  $('[data-role=publish-and-finish]').on('click', function(e){
    e.preventDefault();
    var $form = $(this).closest('.iox-content-padding').find('form:first');
    $form.find('#program_entry_published').val('1');
    $form.submit();
    if( $('#pe-grid').length )
      $('#pe-grid').data('kendoGrid').dataSource.get($form.attr('data-form-id')).set('published', true );
    $('.iox-details-container').remove();
    $('.iox-content').show();
  });

}

function setupPersonAvatarUpload(){

  $('#person_avatar').fileupload({
    dataType: 'json',
    formData: {
      "authenticity_token": $('input[name="authenticity_token"]:first').val()
    },
    done: function (e, data) {
      var avatar = data._response.result[0];
      $('.person-main-avatar').attr('src', avatar.thumbnail_url);
    }
  });

}

function setupDefaultCKEditor($elem){

  CKEDITOR.replace( $elem.get(0), {
    removePlugins: 'elementspath',
    toolbar: [
      [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ],
      [ 'Bold', 'Italic', 'OrderedList', 'UnorderedList'],
      ['Source' ]
    ]
  });

  $elem.closest('form').on('submit', function(e){
    for(var instanceName in CKEDITOR.instances)
      CKEDITOR.instances[instanceName].updateElement();
  });
}
