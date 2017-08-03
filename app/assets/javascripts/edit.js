$(function() {
   $(".modal .pure-button.cancel").on("click", function() {
      $(".modal").hide();
      $("#dimmer").hide();
   });

   var populateInterventionModal = function( obj ) {
      var modal = $(".modal.intervention-edit");
      modal.find("form").attr("action", "/admin/interventions/"+obj.id);
      modal.find('input[name=found_at]').val(obj.found_at);
      modal.find('input[name=who_found]').val(obj.who_found);
      modal.find('input[name=special_interest]').val(obj.special_interest);
      modal.find('input[name=special_problems]').val(obj.special_problems);
      modal.find('input[type=checkbox]').prop("checked", false);
      $.each(obj.details, function(idx,val) {
         modal.find("input[value='"+val.id+"']").prop("checked", true);
      });
   };

   $(".icon-button.edit").on("click", function() {
      var tgt = $(this).data("target");
      $(".modal."+tgt).show();
      $("#dimmer").show();

      var model = $(this).data("model");
      if (model ) {
         if ( tgt === "intervention-edit") {
            populateInterventionModal(model);
         }
      }
   });

   $(".icon-button.trash").on("click", function() {
      var tgtType = $(this).data("target-type");
      var tgtId = $(this).data("target-id");
      resp = confirm("Delete this "+tgtType+"? The data will be lost and cannot be recovered.");
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
