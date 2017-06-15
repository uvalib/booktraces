// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$( document ).on('turbolinks:load', function() {
   $("#continue-btn").on("click", function() {
      if ( $("#staff").is(':checked') ) {
         window.location.href = "admin/listings";
      } else {
         window.location.href = "listings";
      }
   });
});
