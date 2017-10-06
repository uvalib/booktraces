$(function() {

   var createChart = function() {
      var data = $("#booktraces-chart").data("data");
      var config = {
         type: 'bar',
         data: {
            datasets: [{
               data: data.data,
               borderWidth: 1,
               backgroundColor: "#44aacc"
            }],
            labels: data.labels
         },
         options: {
            plugins: {
               datalabels: {
                  anchor: "end",
                  align: "start",
                  offset: -20,
                  color: "black",
                  formatter: function(value, context) {
                     var lbl = data.labels[context.dataIndex];
                     var total = lbl.split("|")[1];
                     var hits = lbl.split("|")[2];
                     return hits + " / " + total;
                  }
               }
            },
            responsive: true,
            title: {
               display: false,
            },
            legend: {
               display: false
            },
            scales: {
               yAxes: [{
                  ticks: {
                     callback: function(value, index, values) {
                        return value + '%';
                     }
                  }
               }],
               xAxes: [{
                  ticks: {
                     callback: function(value, index, values) {
                        return value.split("|")[0];
                     }
                  }
               }]
            },
            tooltips: {
               callbacks: {
                  label: function(tooltipItem, data) {
                     return Number(tooltipItem.yLabel) + "%";
                  }
               }
            }
         }
      };
      var ctx = document.getElementById("booktraces-chart").getContext("2d");
      var newChart = new Chart(ctx, config);
   };

   if ( $("#booktraces-chart").length > 0 ) {
      createChart();
   }
});
