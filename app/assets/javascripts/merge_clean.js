// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready( function(){
  $('.checkAll').click(function(){
    $(".table-row-checkbox").prop("checked", this.checked);
  });
});