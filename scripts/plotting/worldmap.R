# Suffix of the HTML ids of the map and its buttons
worldmap_id_suffix <- function(view)
{
    if (view$suffix == "") {
        return("")
    }
    return(paste0("_", sub("_$", "", view$suffix)))
}

prepare_data_for_worldmap <- function(view)
{
    logdata <- view$logdata
    # ------------------------- add html text for info popup ------------------
    mapdata <- aggregate(logdata$calls, list(logdata$latitude,
                                                  logdata$longitude,
                                                  logdata$country,
                                                  logdata$city), sum)
    mapdata_aggr_by_app <- aggregate(logdata$calls, list(logdata$latitude,
                                                              logdata$longitude,
                                                              logdata$app), sum)
    colnames(mapdata) <- c("lat", "lng", "country", "city", "radius_size")
    colnames(mapdata_aggr_by_app) <- c("lat", "lng", "app", "calls")
    mapdata <- mapdata[order(mapdata$lat),]
    mapdata_aggr_by_app <- mapdata_aggr_by_app[order(mapdata_aggr_by_app$lat),]

    n <- nrow(mapdata)

    mapdata["infotext"] <- rep(",", n) # initialize
    j <- 1 # keeps mapdata and mapdata_aggr_by_app synchronized
    for ( i in seq(1, n) ){ # for every location

      #determine number of apps num_apps for location i
      curr_apps <- which(mapdata_aggr_by_app$lat == mapdata$lat[i])
      num_apps <- length(curr_apps)

      # append city name and (country)
      content <- c('<table style="width:100%">',
                   '<tr>',
                   '<th></th>',
                   '<th>', mapdata$city[i], ' (',
                   mapdata$country[i], ')</th>',
                   '</tr>')
      #append 'Expand...' if needed
      if (num_apps -5 > 0){
        content <- c(content,'<tr>', '<td></td>',
                     '<td style="text-align:right;"><a href="#all_apps" data-toggle="collapse">Expand...</a></td>',
                     '</tr>')
      }

      # append first 5 apps
      for (a in curr_apps[1:min(5, num_apps)]){
        content <- c(content, '<tr>',
                     '<td style="padding: 0px 10px 0px 0px">',
                     mapdata_aggr_by_app$calls[a], '</td>',
                     '<td>', mapdata_aggr_by_app$app[a],'</td>',
                     '</tr>'
        )
      }

      # append last ones as expand panel
      if (num_apps -5 > 0){
        content <- c(content, '</table><table id=all_apps class="collapse" style="width:100%">')
        for (a in curr_apps[1:(num_apps - 5)]){
          content <- c(content, '<tr>',
                       '<td style="padding:0px 10px 0px 0px">',
                       mapdata_aggr_by_app$calls[a], '</td>',
                       '<td>', mapdata_aggr_by_app$app[a],'</td>',
                       '</tr>'
          )
        }
      }

      content <- c(content, "</table>")
      mapdata$infotext[i] <- paste(content, collapse = "")
      j <- j + num_apps
    }

    # ------------------------- manipulate radius size ------------------

    # +1 pseudocounts, take log for scaling outliers
    mapdata$radius_size <- log(mapdata$radius_size + 1)
    max_calls <- max(mapdata$radius_size)
    max_radius <- 20

    # scale radius so the circles do not get too big
    mapdata$radius_size <- mapdata$radius_size * max_radius / max_calls

    return(mapdata)
}

# Bounding box of the calls of `view`, like leaflet's zoomToLimits computes it from the markers
worldmap_limits <- function(view)
{
    limits <- list(lat = range(view$logdata$latitude), lng = range(view$logdata$longitude))
    # leaflet pads a bounding box of size 0
    for (axis in c("lat", "lng")) {
        if (limits[[axis]][1] == limits[[axis]][2]) {
            limits[[axis]] <- limits[[axis]] + c(-0.006, 0.006)
        }
    }
    return(limits)
}

# The map shows the calls of `view` and initially fits the bounding box of the calls of `bounds_view`.
plotWorldmap <- function(view, bounds_view = view)
{
    mapdata <- prepare_data_for_worldmap(view)
    limits <- worldmap_limits(bounds_view)
    return(
        leaflet(mapdata,
                width="960px",
                height="540px",
                elementId=paste0("leaflet-worldmap", worldmap_id_suffix(view)),
                options = leafletOptions(zoomControl = TRUE,
                                         zoomSnap = 0.05,
                                         zoomDelta = 0.05,
                                         wheelPxPerZoomLevel = 150)) %>%
        addTiles(urlTemplate="https://tile.openstreetmap.de/{z}/{x}/{y}.png",
                 attribution='© <a href="https://openstreetmap.org/copyright/">OpenStreetMap</a>, <a href="https://opendatacommons.org/licenses/odbl/">ODbL</a>') %>%
        addCircleMarkers(~lng, ~lat,
                         radius = ~radius_size,
                         color = "blue",
                         fill = T,
                         popup = ~infotext) %>%
        fitBounds(limits$lng[1], limits$lat[1], limits$lng[2], limits$lat[2]) %>%
        onRender("function(el, x) {
            const map = el.htmlwidget_data_init_result.getMap();
            // A map in a hidden tab gets its view only when the tab is shown
            map.whenReady(function() {
              map.original_bounds = map.getBounds();

              map.printPlugin = L.easyPrint({
                title: 'My awesome print button',
                exportOnly: true,
                hidden: true,
                position: 'bottomright',
                sizeModes: ['Current', 'A4Portrait', 'A4Landscape']
              }).addTo(map);
            });
        }")
    )
}

# The maps in the tabs show the same area: when a tab is shown, its map takes over the center and zoom of the
# map in the previous tab. Only the visible map changes, so hidden maps do not load tiles.
worldmap_sync_script <- function()
{
  return(r"(
  <script>
  (function() {
    function worldmap(link) {
      const el = $($(link).attr('href')).find('.leaflet.html-widget[id^="leaflet-worldmap"]')[0];
      return el ? el.htmlwidget_data_init_result.getMap() : null;
    }
    let view = null;
    // The previous tab is still visible
    $(document).on('show.bs.tab', function(e) {
      const from = worldmap(e.relatedTarget);
      view = from && from._loaded ? {center: from.getCenter(), zoom: from.getZoom()} : null;
    });
    $(document).on('shown.bs.tab', function(e) {
      const to = worldmap(e.target);
      if (view && to && to._loaded) {
        to.setView(view.center, view.zoom, {animate: false});
      }
      view = null;
    });
  })();
  </script>
  )")
}

display_worldmap_buttons <- function(view)
{
  button_html <- r"(
  <abbr title="Temporarily resizes the map to 1920x1080px. The downloaded file might be blurry. In this case, the tiles were not loaded fully. It usually works the second time."><button id="btn_export@ID@" type="button" class="btn btn-info btn-dl">Resized</button></abbr>
  <button id="btn_export2@ID@" type="button" class="btn btn-info btn-dl">As shown</button>
  <button id="btn_reset@ID@" type="button" class="btn btn-info btn-dl btn-reset">Reset view</button>
  )"

  button_script_part1 <- r"(
  <script>
  $('#btn_export@ID@').click(function (e){
    const $divMap = $('#leaflet-worldmap@ID@');
    const map = $divMap[0].htmlwidget_data_init_result.getMap();
    $divMap.width(1920);
    $divMap.height(1080);
    $divMap[0].htmlwidget_data_init_result.resize(1920,1080);
    map.fitBounds(map.original_bounds);
    map.once("moveend zoomend load", ()=>{
      map.on('easyPrint-finished', () => {
        setTimeout(() => {
          $divMap.width(960);
          $divMap.height(540);
          $divMap[0].htmlwidget_data_init_result.resize(960,540);
          map.fitBounds(map.original_bounds);
        }, 1000);
      });
      setTimeout(() => {
        map.printPlugin.printMap('CurrentSize', ')"
  # paste0("worldmap_", view$suffix, CURRENT_DATE, "_1920x1080")
  button_script_part2 <- r"(');
      }, 1500);
    });
  });
  $('#btn_export2@ID@').click(function (e){
    const $divMap = $('#leaflet-worldmap@ID@');
    const map = $divMap[0].htmlwidget_data_init_result.getMap();
    map.printPlugin.printMap('CurrentSize', ')"
  # paste0("worldmap_", view$suffix, CURRENT_DATE, "_960x540")
  button_script_part3 <- r"(');
  });
  $('#btn_reset@ID@').click(function (e){
    const $divMap = $('#leaflet-worldmap@ID@');
    const map = $divMap[0].htmlwidget_data_init_result.getMap();
    map.fitBounds(map.original_bounds);
  });
  </script>
  )"

  button_script <- paste0(button_script_part1,
                          paste0("worldmap_", view$suffix, CURRENT_DATE, "_1920x1080"),
                          button_script_part2,
                          paste0("worldmap_", view$suffix, CURRENT_DATE, "_960x540"),
                          button_script_part3)

  id_suffix <- worldmap_id_suffix(view)
  button_html <- gsub("@ID@", id_suffix, button_html, fixed = TRUE)
  button_script <- gsub("@ID@", id_suffix, button_script, fixed = TRUE)

  return(paste0(button_html, "\n\n", button_script, "\n\n"))
}
