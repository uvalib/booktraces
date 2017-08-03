$(function() {
   $(".modal .pure-button.cancel").on("click", function() {
      $(".modal").hide();
      $("#dimmer").hide();
   });

   $(".icon-button.edit").on("click", function() {
      var tgt = $(this).data("target");
      $(".modal."+tgt).show();
      $("#dimmer").show();
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
