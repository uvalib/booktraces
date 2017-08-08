$(function() {
   var randomColorGenerator = function () {
    return '#' + (Math.random().toString(16) + '0000000').slice(2, 8);
};

   var createDistributionChart = function() {

      var config = {
         type: 'pie',
         data: {
            datasets: [{
               data: [],
               borderWidth: 0,
               backgroundColor: [
                  "#e6194b", "#3cb44b", "#ffe119", "#0082c8", "#f58231", "#911eb4", "#46f0f0",
                  "#f032e6", "#d2f53c", "#fabebe", "#008080", "#e6beff", "#aa6e28", "#11aaff",
                  "#fffac8", "#800000", "#aaffc3", "#808000", "#ffd8b1", "#000080", "#808080"
               ]
            }],
            labels: []
         },
         options: {
            responsive: true,
            legend: {
               display: true,
               position: 'bottom'
           }
         }
      };
      $.getJSON("/api/report?type=intervention-distribution", function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            $.each(data.data, function(idx,val) {
               config.data.datasets[0].backgroundColor.push(randomColorGenerator());
            });
            config.data.labels = data.labels;
            var ctx = document.getElementById("distribution-chart").getContext("2d");
            var pie = new Chart(ctx, config);
         }
      });
   };

   if ( $("#distribution-chart").length > 0 ) {
      createDistributionChart();
   }
});
