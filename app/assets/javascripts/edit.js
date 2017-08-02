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
});
