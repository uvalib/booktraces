// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$( document ).on('turbolinks:load', function() {
   $('#shelf-listings').DataTable( {
      serverSide: true,
      ajax: {
        url:  '/api/query',
        type: 'POST'
    }
   });
});
