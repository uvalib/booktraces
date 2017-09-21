// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function() {
   $(".chosen-select").chosen({
       no_results_text: "Sorry, no matches found",
       width: "100%"
   });
   $(".rate-setting").chosen({
       no_results_text: "Sorry, no matches found",
       width: "100px"
   });

   // Columns in the table:
   //   ID, CallNum, Title, Bookplate, Library, class, subclass, intervention
   var pageLen = parseInt($("div.filter").data("default-page-size"), 10);
   var table = $('#shelf-listings').DataTable( {
      serverSide: true,
      processing: true,
      dom: 'lBrtip',
      pageLength: pageLen,
      columnDefs: [
         { orderable: false, targets: [9,10,11] },
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
         }, targets: 11}
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

                  if (json.columns[10].search) {
                     val = json.columns[10].search.search;
                     if (val.length === 0) val = "Any";
                     $("#status-filter").val( val );
                     $("#status-filter").trigger("chosen:updated");
                  }
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

   // NOTES: This is necessary because the data returned by the built-in datatables CSV generator is
   // just what is in the visible table. The requirements for the export exceed this: the intervention
   // dates and preservation data is also necessary. To acheive this, make a call directly to the search API
   // with a format of CSV. This will pull all required data into the report
   $("#csv").on("click", function() {
      // convert all of the UI filter/order settings into a set of query params for the API Call
      params = [];
      var val = $("#library-filter").val();
      if (val !== "Any") {
         params.push("l="+val);
      }

      val = $("#system-filter").val();
      if (val !== "Any") {
         params.push("sys="+val);
      }

      val = $("#class-filter").val();
      if (val !== "Any") {
         params.push("c="+val);
      }

      val = $("#subclass-filter").val();
      if (val !== "Any") {
         params.push("s="+val);
      }

      val = $("#intervention-filter").val();
      if (val !== "Any") {
         params.push("i="+val);
      }

      val = $("#status-filter").val();
      if (val !== "Any") {
         params.push("status="+val);
      }

      val = $("#query").val();
      if (val.length > 0) {
         params.push("q="+val);
         var fields = $("#query-fields").val();
         if (fields !== "all") {
            params.push("field="+fields);
         }
         var full = $("#full-word").is(":checked");
         params.push("full="+full);
      }

      var pg = $("a.paginate_button.current").data("dt-idx");
      var num = parseInt(pg, 10) -1;

      var len = $("#shelf-listings_length select").val();
      if (num > 0) {
         var start = num * parseInt(len, 10);
         params.push("start="+start);
      }
      params.push("length="+len);
      params.push("format=csv");

      // figure out ordering. Get all of the TH elements in the report table
      // find the one that has the class sorting_asc or sorting_desc. Note the index
      // and send this info along with the query to get CSV
      $("#shelf-listings th").each( function(idx) {
         if ( $(this).hasClass("sorting_asc") ) {
            params.push("oc="+idx);
            params.push("od=asc");
         } else if (  $(this).hasClass("sorting_desc")) {
            params.push("oc="+idx);
            params.push("od=desc");
         }
      });

      // Redirect to the API call for search. Since search results
      // are returned as a CSV attachment, the current page will remain
      var origUrl = window.location.href;
      var bits = origUrl.split("/");
      var searchUrl = bits[0] + "//" + bits[2] + "/api/search?"+params.join("&");
      window.location.href = searchUrl;
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

      val = $("#status-filter").val();
      if (!val) val = "Any";
      table.columns(10).search( val );

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
