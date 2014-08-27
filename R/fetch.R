#' Calculate Fetch with \pkg{fetchR}
#' 
#' The \pkg{fetchR} package provides an objective calculation of fetch 
#' based on current conventional standards.
#' 
#' Fetch is an important measurement in coastal applications effectively 
#' providing a proportional measurement of the length of water wind is blown 
#' over. The higher the fetch the more energy is imparted to the surface of the 
#' water resulting in a larger sea state
#' (\url{http://en.wikipedia.org/wiki/Fetch_(geography)}).
#' 
#' Fetch is currently calculated as the sum of distances from the marine 
#' location to the shoreline for every 10 degrees (default) of the compass rose. 
#' The only function required for the calculation of fetch at given latitude and
#' longitude coordinates is \code{\link{fetch}}.
#' 
#' @note The \pkg{fetchR} package is intended for New Zealand coastal
#' applications and only supports marine sites within the following bounding 
#' box:
#' 
#' \tabular{lll}{
#'  \tab Min \tab Max \cr
#' Longitude \tab 167 \tab  178 \cr
#' Latitude  \tab -47 \tab  -35 \cr
#' }
#' 
#' Locations near the perimiter or outside this bounding box are either not 
#' coastal or do not (yet?) have the coastal boundaries to calculate the fetch.
#' 
#' 
#' @seealso \code{\link{fetch}}
#' @name fetchR
#' @aliases fetchR-package
#' @docType package
#' @keywords package
NULL

#' Calculate Fetch for a (NZ) Coastal Marine Location
#' 
#' Calculate average fetch for a New Zealand coastal location given in decimal 
#' degrees. The accuracy can be as low as 1m (0.001km) but can be very 
#' computationally expensive, especially for exposed sites. The number of angles 
#' can be between 4 and 100, however large values can be very computationally 
#' expensive and may not improve the accuracy of the estimate too much. When 
#' land is hit, the distance to coast from the previous iteration is used i.e. 
#' the points will always end up in the water. The zoom is only used for when
#' \code{plot} is \code{TRUE} --- the higher the value, the higher the zoom.
#' 
#' @param lon longitude in decimal degrees.
#' @param lat latitude in decimal degrees.
#' @param max_dist maximum distance (km) allowed for any given angle (default 
#'                 300).
#' @param accuracy accuracy (km) of the fetch estimate (default 0.1km).
#' @param n_angles number of angles for the fetch calculation (equally spaced).
#' @param quiet \code{FALSE}. Suppress diagnostic messages.
#' @param plot \code{TRUE}. Create a png in the current working directory.
#' @param zoom number indicating the zoom for the plot.
#' @param ... further arguments passed to \code{\link[grDevices]{png}}
#' 
#' @return returns an invisible dataframe containing the resultant coordinates 
#'         at the coastline, magnitude and direction.
#' @importFrom sp CRS proj4string Polygons Polygon SpatialPolygons SpatialPoints 
#'                over coordinates
#' @import rgeos
#' @importFrom grDevices png
#' @seealso fetchR
#' @export
fetch = function(lon, lat, max_dist = 300, accuracy = 0.1, n_angles = 10, 
                 plot = TRUE, zoom = max_dist / 10, quiet = FALSE, ...){
  if (!is.numeric(lon) || !is.numeric(lat))
    stop("longitude and latitude must be numeric")
  
  if (!all(length(lat) == 1, length(lon) == 1))
    stop("only one longitude and latitude can be supplied at a time")
  
  if (!is.numeric(max_dist) || length(max_dist) != 1)
    stop("max_dist must be a single number")
  
  if (max_dist < 1 || max_dist > 500)
    stop("max_dist must be between 1 and 500 km")
  
  if (!is.numeric(accuracy) || length(accuracy) != 1)
    stop("accuracy must be a single number")
  
  if (accuracy < .001 || accuracy > max_dist)
    stop(paste("accuracy must be between 0.001 km and", max_dist))
  
  if (!is.numeric(n_angles) || length(n_angles) != 1)
    stop("n_angles must be a single number")
  
  if (n_angles < 4 || n_angles > 100)
    stop("n_angles must be between 4 and 100")
  
  if (!is.logical(quiet) || length(quiet) != 1)
    stop("quiet must be either TRUE or FALSE")
  
  if (!is.logical(plot) || length(plot) != 1)
    stop("plot must be either TRUE or FALSE")
  
  if (!is.numeric(zoom) || length(zoom) != 1)
    stop("zoom must be a single number")
  
  centre_point = SpatialPoints(data.frame(lon, lat), 
                               proj4string = CRS(proj4string(nz_coast)))
  if (!quiet)
    message("checking coordinate is not on land")
  
  if (any(!is.na(over(nz_coast, centre_point))) || 
        any(!is.na(over(nz_islands, centre_point))))
    stop("coordinate is on land")
  
  max_dist = max_dist * 1000
  accuracy = accuracy * 1000
  outer_radii = seq(accuracy, max_dist, by = accuracy)
  directions = seq(0, 2 * pi, by = 2 * pi / (360 / n_angles))
  if (tail(directions, 1) == 2 * pi)
    directions = head(directions, -1)
  
  circle_vector = data.frame(direction = directions, magnitude = max_dist)
  my_circle = vectordestination(c(lon, lat), circle_vector)
  
  bound_matrix = matrix(c(min(my_circle$lon), min(my_circle$lat),
                          min(my_circle$lon), max(my_circle$lat),
                          max(my_circle$lon), min(my_circle$lat),
                          min(my_circle$lon), min(my_circle$lat),
                          min(my_circle$lon), min(my_circle$lat)),
                        ncol = 2, byrow = TRUE)
  bound_poly_p = Polygon(bound_matrix)
  bound_poly_ps = Polygons(list(bound_poly_p), 1)
  bound_poly_sps = SpatialPolygons(list(bound_poly_ps), 
                                   proj4string = CRS(proj4string(nz_coast)))
  
  
  in_plot_area_islands = over(bound_poly_sps, nz_islands)
  nz_islands_subset = nz_islands[in_plot_area_islands, ]
  in_plot_area_coast = over(bound_poly_sps, nz_coast)
  nz_coast_subset = nz_coast[in_plot_area_coast, ]
  
  if (isTRUE(plot)){
    circle_vector = data.frame(direction = directions, magnitude = max_dist / zoom)
    my_circle = vectordestination(c(lon, lat), circle_vector)
    
    png(filename = paste0("Fetch_", paste(coordinates(centre_point), 
                                          collapse = "_"), ".png"), ...)
    plot(my_circle, type = 'n')
    plot(nz_coast_subset, add = TRUE)
    plot(nz_islands_subset, add = TRUE)
    points(centre_point)
  }
  
  if (!quiet)
    message("calculating fetch")
  
  end_points = data.frame(longitude = numeric(length(directions)),
                          latitude = numeric(length(directions)),
                          direction = numeric(length(directions)),
                          distance = numeric(length(directions)))
  rows = rownames(end_points)
  for (i in seq_along(outer_radii)){
    circle_vector = data.frame(direction = directions, 
                               magnitude = outer_radii[i])
    my_circle = vectordestination(c(lon, lat), circle_vector)
    my_points = SpatialPoints(my_circle, 
                              proj4string = CRS(proj4string(nz_coast)))
    on_land = !is.na(as.character(over(my_points, nz_coast_subset)$name)) |
      !is.na(as.character(over(my_points, nz_islands_subset)$name))
    
    if (any(on_land) || i == length(outer_radii)){
      if (i == length(outer_radii)){
        on_land = rep(TRUE, length(rows))
        j = i
      } else {
        if (i == 1){
          my_previous_circle = my_circle
          warning(sum(on_land), " directions are less than ", accuracy, 
                  "m from land")
        }
        else
          j = i - 1
      }
      end_points[rows[on_land], ] = c(my_previous_circle$longitude[on_land],
                                      my_previous_circle$latitude[on_land],
                                      round(360 / (pi * 2) * 
                                              directions[on_land], 2),
                                      if (i == 1)
                                        0
                                      else
                                        outer_radii[rep(j, sum(on_land))] / 1000)
      
      directions = directions[!on_land]
      rows = rows[!on_land]
    }
    my_previous_circle = my_circle[!on_land, ]
    percent_done = i / length(outer_radii) * 100
    if ((percent_done %% 10 == 0) && !isTRUE(quiet))
      message(paste0(percent_done, "% calculated"))
  }
  if (isTRUE(plot)){
    if (!isTRUE(quiet))
      message("preparing plot")
    lons = c(t(data.frame(coordinates(centre_point)[1],
                          end_points[, 1])))
    lats = c(t(data.frame(coordinates(centre_point)[2],
                          end_points[, 2])))
    lines(x = lons, y = lats, col = 'red')
    graphics.off()
    if (!isTRUE(quiet))
      message("plot saved in ", normalizePath("."))
  }
  message("average fetch = ", mean(end_points$distance), " km")
  invisible(end_points)
}

load(system.file("extdata", "nz_coast.rda", package = "fetchR"))
load(system.file("extdata", "nz_islands.rda", package = "fetchR"))