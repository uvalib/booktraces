// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function() {
   // Columns in the table:
   //   ID, CallNum, Title, Bookplate, Library, class, subclass, intervention
   $('#shelf-listings').DataTable( {
      serverSide: true,
      processing: true,
      pageLength: 50,
      ordering: false,
      columnDefs: [
         { "width": "50px", "targets": [0] },
         { "width": "30px", "targets": [5,6] },
         { "width": "75px", "targets": [1] },
         { "width": "100px", "targets": [2] }
      ],
      ajax: {
        url:  '/api/query',
        type: 'POST'
    }
   });
});
