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
                  title: function(tooltipItem, data) {
                     var v = data.labels[tooltipItem[0].index].split("|");
                     return v[0]+" ("+v[2]+"/"+v[1]+")";
                  },
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
