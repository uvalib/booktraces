// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function() {
   $(".chosen-select").chosen({
       no_results_text: "Sorry, no matches found",
       width: "100%"
   });

   // Columns in the table:
   //   ID, CallNum, Title, Bookplate, Library, class, subclass, intervention
   var table = $('#shelf-listings').DataTable( {
      serverSide: true,
      processing: true,
      pageLength: 25,
      ordering: false,
      columnDefs: [
         { width: "50px", targets: [0] },
         { width: "30px", targets: [5,6] },
         { width: "70px", targets: [1] },
         { render: function ( data, type, row ) {
            var url = "http://search.lib.virginia.edu/catalog?catalog_select=catalog&search_field=advanced&call_number=";
            var safe = data.replace(/\s/g, "+");
            url += safe;
            return "<a title='View in Virgo' target='_blank' href='"+url+"'>"+data+"</a>";
         }, targets: 2},
         { render: function ( data, type, row ) {
            clazz = "no";
            if ( data === true) clazz= "yes";
            return "<div class='intervention'><span class='intervention "+clazz+"'></span></div>";
         }, targets: 8},
         { render: function ( data, type, row ) {
            return "<a class='detail' title='View details' href='/listings/"+data+"'></a>";
         }, targets: 9}
      ],
      searchCols: [
         null,null,null,null,null,null,null,null,{ "search": "true" }
      ],
      ajax: {
        url:  '/api/query',
        type: 'POST'
    }
   });

   var doFilter = function() {
      table.columns(5).search(  $("#library-filter").val() );
      table.columns(6).search( $("#class-filter").val() );
      table.columns(7).search( $("#subclass-filter").val() );
      table.columns(8).search( $("#intervention-filter").is(":checked") );

      var q = $("#query").val();
      $("#shelf-listings_filter input").val(q);
      table.search( q );

      table.draw();
   };

   $("#query").on("keyup", function (evt) {
      if ( evt.keyCode === 13) {
         doFilter();
      }
   });

   $("#clear").on("click", function() {
      $("select.filter").val("Any");
      $('select.filter').trigger("chosen:updated");
      $("#query").val("");
      $("#intervention-filter").prop("checked", false);
      table.search("").draw();
   });

   $("#filter").on("click", function() {
      doFilter();
   });
});
