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

   var createHitRateChart = function(tgtElement, chartType, library, system, classification ) {
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

      var url = "/api/report?type=";
      var preserveChart = false;
      if (chartType === "top25" || chartType === "bottom25") {
         url += chartType;
      } else {
         url += chartType+"-hit-rate&library="+library+"&system="+system+"&classification="+classification;
         preserveChart = true;
      }

      $.getJSON(url, function ( data, textStatus, jqXHR ){
         $("#generating").hide();
         if (textStatus == "success" ) {
            if ( preserveChart ) {
               if ( window.hitRateChart ) {
                  window.hitRateChart.destroy();
               }
            }
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            var ctx = document.getElementById(tgtElement).getContext("2d");
            var newChart = new Chart(ctx, config);
            if ( preserveChart ) {
               window.hitRateChart = newChart;
            }
         }
      });
   };

   if ( $("#distribution-chart").length > 0 ) {
      window.hitRateChart = null;
      createHitRateChart("library-hit-rate", "library", "any", "any", "any");
      createHitRateChart("top25-chart", "top25", "any", "any", "any");
      createHitRateChart("bottom25-chart", "bottom25", "any", "any", "any");
      createDistributionChart();
   }

   $(".pure-button.generate").on("click", function() {
      var hitsPer = $("#x-axis-type").val();
      var lib = $("#library-rate").val();
      var system = $("#system-rate").val();
      var classification = $("#class-rate").val();
      if ( hitsPer != "library" && system=="Any" && hitsPer != "decade") {
         alert("Please select a classification system other than Any");
         return;
      }
      if ( hitsPer == "subclass" && classification=="Any" ) {
         alert("Please select a classification other than Any");
         return;
      }
      createHitRateChart("library-hit-rate", hitsPer, lib, system, classification);
      var link = $("#chart-link").attr("href").split("?")[0];
      var params = [];
      params.push("type="+hitsPer);
      if (lib != "Any") params.push("library="+lib);
      if (system != "Any") params.push("sys="+system);
      if (classification != "Any") params.push("class="+classification);
      link = link + "?" + params.join("&");
      $("#chart-link").attr("href", link);
   });

   $("#x-axis-type").chosen().change( function() {
      var val = $("#x-axis-type").val();
      if ( val==="library") {
         $("#library-rate").prop("disabled", true);
         $("#system-rate").prop("disabled", true);
         $("#class-rate").prop("disabled", false);
      } else if ( val==="class") {
         $("#library-rate").prop("disabled", false);
         $("#system-rate").prop("disabled", false);
         $("#class-rate").prop("disabled", true);
      } else if ( val==="subclass") {
         $("#library-rate").prop("disabled", false);
         $("#system-rate").prop("disabled", false);
         $("#class-rate").prop("disabled", false);
      } else if ( val==="decade") {
         $("#library-rate").prop("disabled", false);
         $("#system-rate").prop("disabled", true);
         $("#class-rate").prop("disabled", false);
      }
      $("#library-rate").val("Any");
      $("#system-rate").val("Any");
      $("#class-rate").val("Any");
      $("#library-rate").trigger("chosen:updated");
      $("#system-rate").trigger("chosen:updated");
      $("#class-rate").trigger("chosen:updated");
   });

   $("#system-rate").chosen().change( function() {
      var val = $("#system-rate").val();
      $.ajax({
         url: "/api/classifications/"+val,
         method: "GET",
         complete: function( jqXHR, textStatus ) {
            var vals = jqXHR.responseJSON;
            $("#class-rate option").remove();
            $.each(vals, function(idx, v) {
               $("#class-rate").append( $('<option>', {
                    value: v,
                    text : v
                }));
            });
            $("#class-rate").trigger("chosen:updated");
         }
      });
   });
});
