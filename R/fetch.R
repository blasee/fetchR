#' Calculate Fetch for a (NZ) Coastal Marine Location
#' 
#' Calculate average fetch for a New Zealand coastal location given in decimal 
#' degrees. The accuracy can be as low as 1m (0.001km) but can be very 
#' computationally expensive, especially for exposed sites. The number of angles 
#' can be between 4 and 100, however large values can be very computationally 
#' expensive and may not improve the accuracy of the estimate too much. When 
#' land is hit, the distance to coast from the previous iteration is used i.e. 
#' the points will always end up in the water.
#' 
#' @param lon longitude in decimal degrees.
#' @param lat latitude in decimal degrees.
#' @param max_dist maximum distance (km) allowed for any given angle (default 
#'                 300).
#' @param accuracy accuracy (km) of the fetch estimate (default 0.1km).
#' @param degree_int interval of the directions for the fetch calculation in degrees 
#'                   (equally spaced).
#' @param quiet \code{FALSE}. Suppress diagnostic messages.
#' 
#' @return returns an invisible dataframe containing the resultant coordinates 
#'         at the coastline, magnitude and direction.
#' @importFrom sp CRS proj4string Polygons Polygon SpatialPolygons SpatialPoints 
#'                over coordinates
#' @import rgeos
#' @seealso \code{\link{fetchR}}
#' @examples
#' # Calculate fetch for Kawau Bay
#' kawau_bay = fetch(174.8, -36.4)
#' 
#' # Show the distances for each direction and the resultant locations
#' kawau_bay
#' 
#' # Summarise the information
#' summary(kawau_bay)
#' 
#' # Plot the vectors
#' plot(kawau_bay)
#' 
#' # Output the file as a KML for further investigation in Google Earth
#' save_kml(kawau_bay, "kawau_bay")
#' @export
fetch = function(lon, lat, max_dist = 300, accuracy = 0.1, degree_int = 10,
                 quiet = FALSE){
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
  
  if (!is.numeric(degree_int) || length(degree_int) != 1)
    stop("degree_int must be a single number")
  
  if (degree_int < 4 || degree_int > 100)
    stop("degree_int must be between 4 and 100")
  
  if (!is.logical(quiet) || length(quiet) != 1 || is.na(quiet))
    stop("quiet must be either TRUE or FALSE")
    
  centre_point = SpatialPoints(data.frame(lon, lat), 
                               proj4string = CRS(proj4string(nz_coast)))
  if (!quiet)
    message("checking coordinate is not on land")
  
  if (!is.na(over(nz_coast, centre_point)) ||
        !is.na(over(nz_islands, centre_point)))
    stop("coordinate is on land")
  
  max_dist = max_dist * 1000
  accuracy = accuracy * 1000
  outer_radii = seq(accuracy, max_dist, by = accuracy)
  directions = seq(0, 2 * pi, by = 2 * pi / (360 / degree_int))
  if (tail(directions, 1) == 2 * pi)
    directions = head(directions, -1)
  
  circle_vector = data.frame(direction = directions, magnitude = max_dist)
  my_circle = vector_destination(c(lon, lat), circle_vector)
  
  circle_lon_min = min(my_circle$lon)
  circle_lon_max = max(my_circle$lon)
  circle_lat_min = min(my_circle$lat)
  circle_lat_max = max(my_circle$lat)
  bound_matrix = matrix(c(circle_lon_min, circle_lat_min,
                          circle_lon_min, circle_lat_max,
                          circle_lon_max, circle_lat_max,
                          circle_lon_max, circle_lat_min,
                          circle_lon_min, circle_lat_min),
                        ncol = 2, byrow = TRUE)
  bound_poly_p = Polygon(bound_matrix)
  bound_poly_ps = Polygons(list(bound_poly_p), 1)
  bound_poly_sps = SpatialPolygons(list(bound_poly_ps), 
                                   proj4string = CRS(proj4string(nz_coast)))
  
  
  in_radius_islands = which(!is.na(over(nz_islands, bound_poly_sps)))
  nz_islands_subset = nz_islands[in_radius_islands, ]
  in_radius_coast = which(!is.na(over(nz_coast, bound_poly_sps)))
  nz_coast_subset = nz_coast[in_radius_coast, ]
  
  if (!quiet)
    message("calculating fetch")
  
  initial_vector = numeric(length(directions))
  end_points = data.frame(longitude = initial_vector,
                          latitude = initial_vector,
                          direction = initial_vector,
                          distance = initial_vector)
  rows = rownames(end_points)
  for (i in seq_along(outer_radii)){
    circle_vector = data.frame(direction = directions, 
                               magnitude = outer_radii[i])
    my_circle = vector_destination(c(lon, lat), circle_vector)
    my_points = SpatialPoints(my_circle, 
                              proj4string = CRS(proj4string(nz_coast)))
    on_land =
      !is.na(as.character(over(my_points, nz_coast_subset)$name)) |
      !is.na(as.character(over(my_points, nz_islands_subset)$name))
    
    if (any(on_land) || i == length(outer_radii)){
      if (i == length(outer_radii)){
        on_land = rep(TRUE, length(rows))
        j = i
      } else {
        if (i == 1){
          my_previous_circle = my_circle
          warning(sum(on_land), " directions are less than ", accuracy, 
                  "m from land", immediate. = TRUE)
        }
        else
          j = i - 1
      }
      end_points[rows[on_land], ] = c(my_previous_circle$longitude[on_land],
                                      my_previous_circle$latitude[on_land],
                                      round(360 / (pi * 2) * 
                                              directions[on_land], 2),
                                      if (i == 1)
                                        rep(0, sum(on_land))
                                      else
                                        outer_radii[rep(j, sum(on_land))] / 1000)
      directions = directions[!on_land]
      rows = rows[!on_land]
      
      if (length(rows) && !quiet)
        message(length(rows), " more directions to calculate")
    }
    my_previous_circle = my_circle[!on_land, ]
    if (!length(rows))
      break
  }
  
  new("fetch", 
      location_lat = lat, 
      location_long = lon,
      subset_coast = nz_coast_subset, 
      subset_island = nz_islands_subset,
      end_points)
}