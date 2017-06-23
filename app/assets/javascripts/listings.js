// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function() {
   $(".chosen-select").chosen({
       no_results_text: "Sorry, no matches found",
       width: "100%"
   });

   // Columns in the table:
   //   ID, CallNum, Title, Bookplate, Library, class, subclass, intervention
   var pageLen = parseInt($("div.filter").data("default-page-size"), 10);
   var table = $('#shelf-listings').DataTable( {
      serverSide: true,
      processing: true,
      pageLength: pageLen,
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
            return "<a class='detail' title='View details' href='listings/"+data+"'></a>";
         }, targets: 9}
      ],
      searchCols: [
         null,null,null,null,null,null,null,null,{ "search": "true" }
      ],
      stateDuration: 0,
      stateSave: true,
      stateLoadCallback: function (settings, callback) {
         $.ajax({
            url: '/api/search_state',
            dataType: 'json',
            success: function (json) {
               if (json) {
                  $("#query").val( json.search.search );
                  var val = json.columns[5].search.search;
                  if (val.length === 0) val = "Any";
                  $("#library-filter").val(val);
                  $("#library-filter").trigger("chosen:updated");

                  val = json.columns[6].search.search;
                  if (val.length === 0) val = "Any";
                  $("#class-filter").val(val);
                  $("#class-filter").trigger("chosen:updated");

                  val = json.columns[7].search.search;
                  if (val.length === 0) val = "Any";
                  $("#subclass-filter").val( val );
                  $("#subclass-filter").trigger("chosen:updated");
                  
                  val = json.columns[8].search.search;
                  $("#intervention-filter").prop('checked', val==="true");
               }
               callback(json);
            }
         });
      },
      ajax: {
        url:  '/api/query',
        type: 'POST'
     }
   });

   var doFilter = function() {
      var val = $("#library-filter").val();
      if (!val) val = "Any";
      table.columns(5).search( val );

      val = $("#class-filter").val();
      if (!val) val = "Any";
      table.columns(6).search( val );

      val = $("#subclass-filter").val();
      if (!val) val = "Any";
      table.columns(7).search( val );

      table.columns(8).search( $("#intervention-filter").is(":checked") );

      val = $("#query").val();
      if (!val) val = "";
      $("#shelf-listings_filter input").val( val );
      table.search( val );

      table.draw();
   };

   $("#query").on("keyup", function (evt) {
      if ( evt.keyCode === 13) {
         doFilter();
      }
   });

   $("#clear").on("click", function() {
      $("#library-filter").val("Any");
      $("#library-filter").trigger("chosen:updated");
      $("#class-filter").val("Any");
      $("#class-filter").trigger("chosen:updated");
      $("#subclass-filter").val("Any");
      $("#subclass-filter").trigger("chosen:updated");
      $("#query").val("");
      $("#intervention-filter").prop("checked", true);
      doFilter();
   });

   $("#filter").on("click", function() {
      doFilter();
   });
});
