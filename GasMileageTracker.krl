ruleset a169x685 {
  meta {
    name "Gas Mileage and Maintenance"
    description <<
      Gas Mileage and Maintenance App

      Tracks the Odometer, price, volume, and cost of fill ups.

      Calculates the average MPG, last MPG, minimum MPG, maximum MPG, average $/gal, last $/gal, minmum $/gal, maximum $/gal, $/mile, $/fillup, $/day, miles/$, gal/fillup, days/fillup, miles/fillup, total $, and total gal.

      Copyright 2012 Kynetx, All Rights Reserved
    >>
    author "Jessie A. Morris"
    // Uncomment this line to require Marketplace purchase to use this app.
    // authz require user
    logging off

    use module a169x701 alias CloudRain
    use module a169x676 alias pds
    use module a41x196 alias SquareTag
    use module a41x217 alias Graphing
  }

  dispatch {
    // Some example dispatch domains
    // domain "example.com"
    // domain "other.example.com"
  }

  global {
    thisRID = meta:rid();
    thisECI = meta:eci();
    SquareTagRID = "a41x178";
    myThingsRID = "a169x667";

    get_journal_entries = function(){

      myEntries = ent:entries.reverse();

      entriesListMade = myEntries.map(
        function(entry) {

          timeISO   = entry{"time"};
          time      = time:strftime(timeISO, "%F %l:%M %p");
          odometer = entry{"odometer"};
          price  = entry{"price"};
          volume = entry{"volume"};
          totalCost = entry{"totalCost"};
          mileage = entry{"mileage"};
          distance = entry{"distance"};

          thisEntry = <<
            <div class="accordion-group">
              <div class="accordion-heading">
                <a class="accordion-toggle" data-toggle="collapse" data-parent="#entriesAccordion" href="#collapse#{odometer}">
                  <span class="pull-left">#{volume} Gal</span> #{mileage} MPG <span class="pull-right">$#{price}</span><br />
                  <span class="pull-left">$#{totalCost} @ #{odometer}</span><span class="pull-right">#{time}</span><br />
                </a>
              </div>
              <div id="collapse#{odometer}" class="accordion-body collapse">
                <div class="accordion-inner">
                  <div class="hero-unit" style="padding: 30px;">
                    <h2>#{mileage} MPG</h2>

                    <p>
                      <span class="pull-left">Odometer:</span><span class="pull-right">#{odometer}</span><br />
                    </p>
                    <p>
                      <span class="pull-left">Time:</span><span class="pull-right">#{time}</span><br />
                    </p>
                    <p>
                      <span class="pull-left">Price Per Gallon:</span><span class="pull-right">#{price}</span><br />
                    </p>
                    <p>
                      <span class="pull-left">Number of Gallons:</span><span class="pull-right">#{volume}</span><br />
                    </p>
                    <p>
                      <span class="pull-left">Total Cost:</span><span class="pull-right">#{totalCost}</span><br />
                    </p>
                    <p>
                      <span class="pull-left">Distance:</span><span class="pull-right">#{distance}</span><br />
                    </p>
                    <p>
                      <span class="pull-left">Odometer:</span><span class="pull-right">#{odometer}</span><br />
                    </p>
                  </div>
                </div>
              </div>
            </div>
          >>;

          thisEntry
        }
      ).join(" ");

      entriesListEmpty = <<
        <div class="accordion-group">
          <div class="accordion-heading">
            <h4>You have no entries</h4>
          </div>
        </div>
      >>;

      entriesList = (myEntries.length() > 0) =>
        entriesListMade | 
        entriesListEmpty;


      entriesGallery = <<
        <div class="accordion" id="entriesAccordion">
          #{entriesList}
        </div>
      >>;

      // return the gallery
      entriesGallery
    };

    getEntriesArray = function(){
      /* Point format:
       * [X Axis, Y Axis]
       * [Date, Data]
       */

      entries = ent:entries;

      times = entries.pick("$..time") || [];
      timeEntries = (typeof(times) neq "array") =>
        ([]).append(times) | times;

      odometerEntriesTemp = entries.pick("$..odometer") || [];
      priceEntriesTemp = entries.pick("$..price") || [];
      volumeEntriesTemp = entries.pick("$..volume") || [];
      mileageEntriesTemp = entries.pick("$..mileage") || [];

      odometerEntries = (typeof(odometerEntriesTemp) neq "array") =>
        ([]).append(odometerEntriesTemp) | odometerEntriesTemp;

      priceEntries = (typeof(priceEntriesTemp) neq "array") =>
        ([]).append(priceEntriesTemp) | priceEntriesTemp;

      volumeEntries = (typeof(volumeEntriesTemp) neq "array") =>
        ([]).append(volumeEntriesTemp) | volumeEntriesTemp;

      mileageEntries = (typeof(mileageEntriesTemp) neq "array") =>
        ([]).append(mileageEntriesTemp) | mileageEntriesTemp;

      formatPairwiseData = function(time, data){
        finalTime = (time:strftime(time, "%F %l:%M%p"));
        dataFinal = data.as("num");
        [finalTime, dataFinal.as("num")]
      };

      odometerEntriesFinal = [timeEntries, odometerEntries].pairwise(formatPairwiseData);
      priceEntriesFinal = [timeEntries, priceEntries].pairwise(formatPairwiseData);
      volumeEntriesFinal = [timeEntries, volumeEntries].pairwise(formatPairwiseData);
      mileageEntriesFinal = [timeEntries, mileageEntries].pairwise(formatPairwiseData);

      gasMileageEntriesMap = {
        /*
        "4": mileageEntriesFinal,
        "1": odometerEntriesFinal, // I name the hashes this to make it order the way I want
        "3": priceEntriesFinal, // YES I WANT THREE IN TWOS PLACE. THREE ORDERS AS SECOND
        "2": volumeEntriesFinal
        */
        "1": mileageEntriesFinal,
        "3": odometerEntriesFinal
      };


      entriesArrayFinal = (gasMileageEntriesMap.values());



      entriesArrayFinal
    };

    appMenu = [
      {
        "label"  : "Export Data",
        "action" : "getCSV&token=#{thisECI}"
      }
    ];
  }

  rule showGasMileageForm {
    select when explicit isOwner
    or          web cloudAppSelected
    pre {
      defaultAppHtml = SquareTag:get_default_app_html(thisRID);

      profile = pds:get_all_me();
      myProfileName = profile{"myProfileName"};
      myProfilePhoto = profile{"myProfilePhoto"};

      journalEntries = get_journal_entries();

      entries = ent:entries;
      lastEntry = (entries.length() > 0) => (entries[entries.length()-1]) | {};
      lastOdometer = lastEntry{"odometer"} + 1;

      formHTML = <<
        Hello Phil!

        <form id="formAddGasMileageEntry" class="form-horizontal form-mycloud">
          <fieldset>
            <div class="thumbnail-wrapper">
              <div class="thumbnail mycloud-thumbnail">
                <img src="#{myProfilePhoto}" alt="#{myProfileName}">
                <h5 class="cloudUI-center">#{myProfileName}</h5>
              </div>  <!-- .thumbnail -->
            </div>

            <div class="control-group">
              <div class="controls">
                <input type="hidden" class="input-xlarge" id="lastOdometer" />
              </div>
            </div>

            <div class="control-group">
              <label class="control-label" for="time">Date and Time (Optional)</label>
              <div class="controls">
                <input type="datetime-local" class="input-xlarge" name="time" id="time" title="The date and time of your fill up (Optional)" placeholder="The date and time of your fill up (Optional)" />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="odometer">Odometer Reading</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="odometer" id="odometer" title="Your car's odometer reading (Required)" placeholder="Your car's odometer reading (Required)" step="1" min="#{lastOdometer}" required />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="price">Price Per Gallon</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="price" id="price" title="Price Per Gallon (Required)" placeholder="Price Per Gallon (Required)" step="0.001" min="0" required />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="volume">Total Number of Gallons</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="volume" id="volume" title="Number of Gallons (Required)" placeholder="Number of Gallons (Required)" step="0.001" min="0" required />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="totalCost">Total Fillup Cost</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="totalCost" id="totalCost" title="Total Cost to Fillup" placeholder="Total Cost to Fillup" step="0.01" disabled />
              </div>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Save Entry</button>
            </div>
          </fieldset>
        </form>
      >>;

      html = <<
        <div class="squareTag wrapper">
          #{defaultAppHtml}
          <ul id="myTab" class="nav nav-tabs">
            <li class="active"><a href="#gasMileageNewTab" data-toggle="tab">Record Fill Up</a></li>
            <li class=""><a href="#gasMileageTableTab" data-toggle="tab">View Fill Ups</a></li>
            <li class=""><a href="#gasMileageGraphTab" data-toggle="tab">MPG Graph</a></li>
          </ul>
          <div class="tab-content" id="gasMileageTabContent">
            <div class="tab-pane fade active in" id="gasMileageNewTab">
              #{formHTML}
            </div>

            <div class="tab-pane fade" id="gasMileageTableTab">
              <div id="journalEntries" class="wrapper squareTag">
                #{journalEntries}
              </div>
            </div>
            <div class="tab-pane fade" id="gasMileageGraphTab">
              <div id="gasMileageGraph" data-height="260px" data-width="480px" style="margin-top:20px; margin-left:20px;"></div>
            </div>
          </div>
        </div>
      >>;

      gasMileageEntries = getEntriesArray();

    }
    {
      SquareTag:inject_styling();
      CloudRain:createAppPanel(thisRID, "Gas Mileage Tracker", appMenu);
      CloudRain:loadAppPanel(thisRID, html);
      CloudRain:skyWatchSubmit("#formAddGasMileageEntry", meta:eci());
      emit <<
        $K("#gasMileageGraph").attr('data-width', ($K("#gasMileageTabContent").width() - 40) + "px");
        $K("#volume,#price").change(function(){
          var totalCost = ($K("#volume").val() * $K("#price").val()).toFixed(2);

          $K("#totalCost").val(totalCost);
        });
        
        KOBJ.a169x685.createGraph = function(){
          var gasMileageEntriesLocal = gasMileageEntries;
          var gasMileageGraph = $K.jqplot('gasMileageGraph', gasMileageEntriesLocal, {
            title:'Gas Mileage',
            axes:{
              xaxis:{
                renderer:$K.jqplot.DateAxisRenderer
              },
              yaxis:{  
                autoscale:true,
                label: "Gas Mileage",
                labelOptions: {
                  textColor: "black"
                },
                labelRenderer: $K.jqplot.CanvasAxisLabelRenderer
              },
              y2axis:{  
                autoscale:true,
                label: "Odometer",
                labelOptions: {
                  textColor: "black"
                },
                labelRenderer: $K.jqplot.CanvasAxisLabelRenderer
              }
            },
            legend: {
              show: true,
              location: 'se'
            },

            series:[
              {
                label: "Mileage",
              },
              {
                label: "Odometer",
                yaxis:'y2axis'
              }
            ]
          });

          $K('a[href="#gasMileageGraphTab"]').on('shown', function (e) {
            $K("#gasMileageGraph").attr('data-width', ($K("#gasMileageTabContent").width() - 40) + "px");
            gasMileageGraph.replot();
          });
        };
      >>;
      Graphing:createLineGraphDate("KOBJ.a169x685.createGraph");
    }
  }

  rule saveEntry {
    select when web submit "#formAddGasMileageEntry"
    pre {
      time = event:attr("time");
      odometer = event:attr("odometer").sprintf("%d");
      price = event:attr("price").sprintf("%.3f");
      volume = event:attr("volume").sprintf("%.3f");
      totalCost = (price * volume).sprintf("%.2f");

      entries = ent:entries;

      lastEntry = (entries.length() > 0) => (entries[entries.length()-1]) | {};
      lastOdometer = lastEntry{"odometer"} || odometer;

      distance = (odometer-lastOdometer).sprintf("%d");


      mileage = ((distance) => (distance/volume) | 0).sprintf("%.1f");

      timeNow = (time) => (time:new(time)) | time:now({"tz": "America/Denver"});

      entryData = {
        "time": timeNow,
        "odometer": odometer,
        "price": price,
        "volume": volume,
        "totalCost": totalCost,
        "mileage": mileage,
        "distance": distance
      };

      entries = (ent:entries || []).append(entryData);
    }
    {
      noop();
    }
    fired {
      set ent:entries entries;
    }
  }

  rule showEntries {
    select when web submit "#formAddGasMileageEntry"
    pre {
      journalEntries = get_journal_entries();
      gasMileageEntries = getEntriesArray();
    }
    {
      emit <<
        $K("#journalEntries").html(journalEntries);
        $K("#gasMileageGraph").html("");
        $K("#formAddGasMileageEntry")[0].reset();

        $K('a[href="#gasMileageTableTab"]').tab('show');

        KOBJ.a169x685.createGraph = function(){
          var gasMileageEntriesLocal = gasMileageEntries;
          var gasMileageGraph = $K.jqplot('gasMileageGraph', gasMileageEntriesLocal, {
            title:'Gas Mileage',
            axes:{
              xaxis:{
                renderer:$K.jqplot.DateAxisRenderer
              },
              yaxis:{  
                autoscale:true,
                label: "Gas Mileage",
                labelOptions: {
                  textColor: "black"
                },
                labelRenderer: $K.jqplot.CanvasAxisLabelRenderer
              },
              y2axis:{  
                autoscale:true,
                label: "Odometer",
                labelOptions: {
                  textColor: "black"
                },
                labelRenderer: $K.jqplot.CanvasAxisLabelRenderer
              }
            },
            legend: {
              show: true,
              location: 'se'
            },

            series:[
              {
                label: "Mileage",
              },
              {
                label: "Odometer",
                yaxis:'y2axis'
              }
            ]
          });

          $K('a[href="#gasMileageGraphTab"]').on('shown', function (e) {
            $K("#gasMileageGraph").attr('data-width', ($K("#gasMileageTabContent").width() - 40) + "px");
            gasMileageGraph.replot();
          });
        };
      >>;
      Graphing:createLineGraphDate("KOBJ.a169x685.createGraph");
      CloudRain:hideSpinner();
    }
  }

  rule resetEntries {
    select when web submit "#formReset"
    {
      noop();
    }
    fired {
      clear ent:entries;
    }
  }

  rule exportEntriesHandler {
    select when web cloudAppAction action re/getCSV/
    pre {
      url = "https://cs.kobj.net/sky/event/#{thisECI}/#{math:random(9999999)}/web/getCSV?_rids=#{thisRID}"
    }
    {
      emit <<
        $K('<iframe>', { id:'idown', src:url }).hide().appendTo('body');
      >>;
      CloudRain:setHash("/app/#{myThingsRID}/safeAndMine&authChannel=#{thisECI}");
    }
  }

  rule exportEntries {
    select when web getCSV
    pre {
      csv = SquareTag:getEntriesCSV(ent:entries);
    }
    {
      send_raw("text/csv")
        with content = csv;
    }
  }

  rule showGasMileagePublic {
    select when explicit isNotOwner
    or        explicit SquareTagScanned relationship re/coslave/
    or        explicit SquareTagScanned relationship re/product/
    pre {
      profile = pds:get_all_me();
      myProfileName = profile{"myProfileName"};
      myProfilePhoto = profile{"myProfilePhoto"};

      journalEntries = get_journal_entries();

      entries = ent:entries;
      lastEntry = (entries.length() > 0) => (entries[entries.length()-1]) | {};
      lastOdometer = lastEntry{"odometer"} + 1;

      formHTML = <<
        <form id="formAddGasMileageEntry" class="form-horizontal form-mycloud">
          <fieldset>
            <div class="thumbnail-wrapper">
              <div class="thumbnail mycloud-thumbnail">
                <img src="#{myProfilePhoto}" alt="#{myProfileName}">
                <h5 class="cloudUI-center">#{myProfileName}</h5>
              </div>  <!-- .thumbnail -->
            </div>

            <div class="control-group">
              <div class="controls">
                <input type="hidden" class="input-xlarge" id="lastOdometer" />
              </div>
            </div>

            <div class="control-group">
              <label class="control-label" for="time">Date and Time (Optional)</label>
              <div class="controls">
                <input type="datetime-local" class="input-xlarge" name="time" id="time" title="The date and time of your fill up (Optional)" placeholder="The date and time of your fill up (Optional)" />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="odometer">Odometer Reading</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="odometer" id="odometer" title="Your car's odometer reading (Required)" placeholder="Your car's odometer reading (Required)" step="1" min="#{lastOdometer}" required />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="price">Price Per Gallon</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="price" id="price" title="Price Per Gallon (Required)" placeholder="Price Per Gallon (Required)" step="0.001" min="0" required />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="volume">Total Number of Gallons</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="volume" id="volume" title="Number of Gallons (Required)" placeholder="Number of Gallons (Required)" step="0.001" min="0" required />
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="totalCost">Total Fillup Cost</label>
              <div class="controls">
                <input type="number" class="input-xlarge" name="totalCost" id="totalCost" title="Total Cost to Fillup" placeholder="Total Cost to Fillup" step="0.01" disabled />
              </div>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Save Entry</button>
            </div>
          </fieldset>
        </form>
      >>;

      html = <<
        <div class="squareTag wrapper">
          <ul id="myTab" class="nav nav-tabs">
            <li class="active"><a href="#gasMileageNewTab" data-toggle="tab">Record Fill Up</a></li>
            <li class=""><a href="#gasMileageTableTab" data-toggle="tab">View Fill Ups</a></li>
            <li class=""><a href="#gasMileageGraphTab" data-toggle="tab">MPG Graph</a></li>
          </ul>
          <div class="tab-content" id="gasMileageTabContent">
            <div class="tab-pane fade active in" id="gasMileageNewTab">
              #{formHTML}
            </div>

            <div class="tab-pane fade" id="gasMileageTableTab">
              <div id="journalEntries" class="wrapper squareTag">
                #{journalEntries}
              </div>
            </div>
            <div class="tab-pane fade" id="gasMileageGraphTab">
              <div id="gasMileageGraph" data-height="260px" data-width="480px" style="margin-top:20px; margin-left:20px;"></div>
            </div>
          </div>
        </div>
      >>;

      gasMileageEntries = getEntriesArray();

    }
    {
      SquareTag:inject_styling();
      CloudRain:createAppPanel(thisRID, "Gas Mileage Tracker", appMenu);
      CloudRain:loadAppPanel(thisRID, html);
      CloudRain:skyWatchSubmit("#formAddGasMileageEntry", meta:eci());
      emit <<
        $K("#gasMileageGraph").attr('data-width', ($K("#gasMileageTabContent").width() - 40) + "px");
        $K("#volume,#price").change(function(){
          var totalCost = ($K("#volume").val() * $K("#price").val()).toFixed(2);

          $K("#totalCost").val(totalCost);
        });
        
        KOBJ.a169x685.createGraph = function(){
          var gasMileageEntriesLocal = gasMileageEntries;
          var gasMileageGraph = $K.jqplot('gasMileageGraph', gasMileageEntriesLocal, {
            title:'Gas Mileage',
            axes:{
              xaxis:{
                renderer:$K.jqplot.DateAxisRenderer
              },
              yaxis:{  
                autoscale:true,
                label: "Gas Mileage",
                labelOptions: {
                  textColor: "black"
                },
                labelRenderer: $K.jqplot.CanvasAxisLabelRenderer
              },
              y2axis:{  
                autoscale:true,
                label: "Odometer",
                labelOptions: {
                  textColor: "black"
                },
                labelRenderer: $K.jqplot.CanvasAxisLabelRenderer
              }
            },
            legend: {
              show: true,
              location: 'se'
            },

            series:[
              {
                label: "Mileage",
              },
              {
                label: "Odometer",
                yaxis:'y2axis'
              }
            ]
          });

          $K('a[href="#gasMileageGraphTab"]').on('shown', function (e) {
            $K("#gasMileageGraph").attr('data-width', ($K("#gasMileageTabContent").width() - 40) + "px");
            gasMileageGraph.replot();
          });
        };
      >>;
      Graphing:createLineGraphDate("KOBJ.a169x685.createGraph");
    }
  }

  rule makeDefault {
    select when web cloudAppAction action re/makeDefault/
    pre {
      backChannel = event:attr("backChannel");

      relationship = SquareTag:getRelationship(backChannel);

      defaultOtherApps = (pds:get_item("SquareTag", "defaultApps") || {});
      newDefaultOtherApps = (backChannel) =>
        defaultOtherApps.put([backChannel], thisRID) | defaultOtherApps;
    }
    {
      replace_html("#makeDefaultSquareTagApp", "");
      CloudRain:hideSpinner();
    }
    fired {
      raise pds event new_data_available
        with _api = "sky"
        and namespace = "SquareTag"
        and keyvalue = "defaultApps"
        and value = newDefaultOtherApps if (relationship && relationship{"relationship"} neq "slave");

      raise pds event new_settings_attribute
        with _api = "sky"
        and setRID = SquareTagRID
        and setAttr = "defaultOwnerApp"
        and setValue = thisRID if (relationship{"relationship"} eq "slave");
    }
  }
}
