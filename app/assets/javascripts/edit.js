$(function() {
   $(".modal .pure-button.cancel").on("click", function() {
      $(".modal").hide();
      $("#dimmer").hide();
   });
   $(".modal .pure-button.submit").on("click", function() {
      $(this).parent().parent().find("form").submit();
   });

   var populateInterventionModal = function( obj ) {
      var modal = $(".modal.intervention-edit");
      modal.find("form").attr("action", "/admin/interventions/"+obj.id);
      if ( modal.find('input[name=_method]').length === 0 ) {
         var put = '<input type="hidden" name="_method" value="put">';
         modal.find("form").append(put);
      }
      $("#intervention-barcode-selector").hide();
      modal.find('input[name=found_at]').val(obj.found_at);
      modal.find('input[name=who_found]').val(obj.who_found);
      modal.find('input[name=special_interest]').val(obj.special_interest);
      modal.find('input[name=special_problems]').val(obj.special_problems);
      modal.find('input[type=checkbox]').prop("checked", false);
      $.each(obj.details, function(idx,val) {
         modal.find("input[value='"+val.id+"']").prop("checked", true);
      });
   };

   var populateDestinationModal = function( obj ) {
      var modal = $(".modal.destination-edit");
      modal.find("form").attr("action", "/admin/destinations/"+obj.id);
      if ( modal.find('input[name=_method]').length === 0 ) {
         var put = '<input type="hidden" name="_method" value="put">';
         modal.find("form").append(put);
      }
      $("#destination-barcode-selector").hide();
      modal.find('input[name=date_sent_out]').val(obj.date_sent_out);
      modal.find('input[name=bookplate]').val(obj.bookplate);
      modal.find('select[name=destination_name_id]').val(obj.destination_name_id);
   };

   var populateCatalogingModal = function( obj ) {
      var modal = $(".modal.cataloging-edit");
      modal.find("form").attr("action", "/admin/cataloging_requests/"+obj.id);
      if ( modal.find('input[name=_method]').length === 0 ) {
         var put = '<input type="hidden" name="_method" value="put">';
         modal.find("form").append(put);
      }
      modal.find('input[name=problems]').val(obj.problems);
      modal.find('input[name=sent_out_on]').val(obj.sent_out_on);
      modal.find('input[name=returned_on]').val(obj.returned_on);
      modal.find('input[name=barcode]').val(obj.barcode.barcode);
      modal.find('input[name=destination]').val(obj.destination);
   };

   $(".icon-button.edit").on("click", function() {
      var tgt = $(this).data("target");
      $(".modal."+tgt).show();
      $("#dimmer").show();

      var model = $(this).data("model");
      if (model ) {
         if ( tgt === "intervention-edit") {
            populateInterventionModal(model);
         } else if ( tgt === "destination-edit") {
            populateDestinationModal(model);
         } else if ( tgt === "cataloging-edit") {
            populateCatalogingModal(model);
         }
      }
   });

   $(".icon-button.add").on("click", function() {
      var tgt = $(this).data("target");
      var modal = $(".modal."+tgt);
      modal.show();
      $("#dimmer").show();

      var model = $(this).data("model");
      modal.find('input[name=_method]').remove();
      modal.find('textarea').val("");
      modal.find('input[type=checkbox]').prop("checked", false);
      modal.find('input[type=text]').val("");
      if ( tgt === "intervention-edit") {
         modal.find("form").attr("action", "/admin/interventions");
         $("#intervention-barcode-selector").show();
      } else if (tgt === "destination-edit") {
         modal.find("form").attr("action", "/admin/destinations");
         $("#destination-barcode-selector").show();
      } else if (tgt === "catalog-edit") {
         modal.find("form").attr("action", "/admin/cataloging_requests");
      }
   });

   $(".icon-button.trash").on("click", function() {
      var tgtType = $(this).data("target-type");
      var tgtId = $(this).data("target-id");
      resp = confirm("Delete this "+tgtType.replace("_", " ")+"? The data will be lost and cannot be recovered.");
      if (!resp) return;

      $.ajax({
         url: "/admin/"+tgtType+"s/"+tgtId,
         method: "DELETE",
         complete: function(jqXHR, textStatus) {
            if ( textStatus != "success" ) {
               alert("Unable to delete "+tgtType+": "+jqXHR.responseText);
            } else {
               window.location.reload();
            }
         }
      });
   });
});
