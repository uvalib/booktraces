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
      columnDefs: [
         { orderable: false, targets: [9,10] },
         { width: "50px", targets: [0] },
         { width: "90px", targets: [2] },
         { width: "150px", targets: [4] },
         { width: "30px", targets: [7,8] },
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
         }, targets: 9},
         { render: function ( data, type, row ) {
            return "<a class='detail' title='View details' href='listings/"+data+"'></a>";
         }, targets: 10}
      ],
      searchCols: [
         null,null,null,null,null,null,null,null,null,{ "search": "true" }
      ],
      stateDuration: 0,
      stateSave: true,
      stateLoadCallback: function (settings, callback) {
         $.ajax({
            url: '/api/search_state',
            dataType: 'json',
            success: function (json) {
               if (json) {
                  var q = json.search.search;
                  if ( q.includes("|") ) {
                     $("#query").val( q.split("|")[0] );
                     $("#query-fields").val( q.split("|")[1] );
                     $("#full-word").prop("checked", q.split("|")[2]==="true" );
                  } else {
                     $("#query").val("");
                     $("#query-fields").val("all");
                  }

                  var val = json.columns[5].search.search;
                  if (val.length === 0) val = "Any";
                  $("#library-filter").val(val);
                  $("#library-filter").trigger("chosen:updated");

                  val = json.columns[6].search.search;
                  if (val.length === 0) val = "Any";
                  $("#system-filter").val(val);
                  $("#system-filter").trigger("chosen:updated");

                  val = json.columns[7].search.search;
                  if (val.length === 0) val = "Any";
                  $("#class-filter").val(val);
                  $("#class-filter").trigger("chosen:updated");

                  val = json.columns[8].search.search;
                  if (val.length === 0) val = "Any";
                  $("#subclass-filter").val( val );
                  $("#subclass-filter").trigger("chosen:updated");

                  val = json.columns[9].search.search;
                  if (val.length === 0) val = "Any";
                  $("#intervention-filter").val( val );
                  $("#intervention-filter").trigger("chosen:updated");
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

   $("#system-filter").chosen().change( function() {
      var val = $("#system-filter").val();
      $.ajax({
         url: "/api/classifications/"+val,
         method: "GET",
         complete: function( jqXHR, textStatus ) {
            var vals = jqXHR.responseJSON;
            $("#class-filter option").remove();
            $.each(vals, function(idx, v) {
               $("#class-filter").append( $('<option>', {
                    value: v,
                    text : v
                }));
            });
            $("#class-filter").trigger("chosen:updated");

            if ( val == "Hicks") {
               $("#subclass-filter").prop('disabled', true).trigger("chosen:updated");

            } else {
               $("#subclass-filter").prop('disabled', false).trigger("chosen:updated");
            }
            $("#subclass-filter").val( "Any" );
            $("#subclass-filter").trigger("chosen:updated");
         }
      });
   });

   $("#class-filter").chosen().change( function() {
      var val = $("#class-filter").val();
      $.ajax({
         url: "/api/subclassifications/"+val,
         method: "GET",
         complete: function( jqXHR, textStatus ) {
            var vals = jqXHR.responseJSON;
            $("#subclass-filter option").remove();
            $.each(vals, function(idx, v) {
               $("#subclass-filter").append( $('<option>', {
                    value: v,
                    text : v
                }));
            });
            $("#subclass-filter").val( "Any" );
            $("#subclass-filter").trigger("chosen:updated");
         }
      });
   });

   var doFilter = function() {
      var val = $("#library-filter").val();
      if (!val) val = "Any";
      table.columns(5).search( val );

      val = $("#system-filter").val();
      if (!val) val = "Any";
      table.columns(6).search( val );

      val = $("#class-filter").val();
      if (!val) val = "Any";
      table.columns(7).search( val );

      val = $("#subclass-filter").val();
      if (!val) val = "Any";
      table.columns(8).search( val );

      val = $("#intervention-filter").val();
      if (!val) val = "Any";
      table.columns(9).search( val );

      val = $("#query").val();
      if (val.length > 0) {
         var fields = $("#query-fields").val();
         val = val + "|"+fields+"|"+ $("#full-word").is(":checked");
      }
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
      $("#system-filter").val("Any");
      $("#system-filter").trigger("chosen:updated");
      $("#class-filter").val("Any");
      $("#class-filter").trigger("chosen:updated");
      $("#subclass-filter").val("Any");
      $("#subclass-filter").trigger("chosen:updated");
      $("#query").val("");
      $("#full-word").prop("checked", true);
      $("#intervention-filter").val("Any");
      $("#intervention-filter").trigger("chosen:updated");
      doFilter();
   });

   $("#filter").on("click", function() {
      doFilter();
   });
});
