$(function() {
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
            config.data.labels = data.labels;
            var ctx = document.getElementById("distribution-chart").getContext("2d");
            var pie = new Chart(ctx, config);
         }
      });
   };

   var createHitRateChart = function(hitsPer, classification, system) {
      $("#generating").show();
      var config = {
         type: 'bar',
         data: {
            datasets: [{
               data: [],
               borderWidth: 1,
               backgroundColor: "#44aacc"
            }],
            labels: []
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

      var extra = "";
      if (system != "any") {
         extra += "&system="+system;
      }
      if (classification != "any") {
         extra += "&classification="+classification;
      }
      $.getJSON("/api/report?type=hit-rate&pool="+hitsPer+extra, function ( data, textStatus, jqXHR ){
         $("#generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            if (window.barChart ) {
               window.barChart.destroy();
            }
            var ctx = document.getElementById("library-hit-rate").getContext("2d");
            window.barChart = new Chart(ctx, config);

         }
      });
   };

   if ( $("#distribution-chart").length > 0 ) {
      createHitRateChart("library", "any", "any");
      createDistributionChart();
   }

   $(".pure-button.generate").on("click", function() {
      var hitsPer = $('input[name=rate-select]:checked').val();
      var classification = "any";
      var system = "any";
      if (hitsPer == "subclassification") {
         classification = $("#rate-class-filter").val();
      } else if (hitsPer == "classification") {
         system = $("#system-class-filter").val();
      }
      createHitRateChart(hitsPer, classification, system);
   });
});
