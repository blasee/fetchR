#' Calculate Fetch for a New Zealand Coastal Marine Location
#' 
#' Fetch is the unobstructed length of water over which wind can blow, and is
#' commonly used as a measure of exposure to wind and waves at coastal sites. The 
#' \code{fetch} function calculates the fetch for a New Zealand coastal location 
#' for a number of bearings to quantify the fetch in 
#' various compass directions.
#' 
#' @param lat latitude in decimal degrees.
#' @param lon longitude in decimal degrees.
#' @param max_dist maximum distance in kilometers (default 300).
#' @param n_bearings the number of bearings per quadrant. A value of 9 (default)
#'                   gives a total of 36 bearings i.e. one at every 10 degrees.
#' @param quiet suppress diagnostic messages (default \code{FALSE}).
#' @param accuracy Deprecated.
#' @param degree_int Deprecated.
#' 
#' @return Returns a \code{\link{Fetch}} object.
#' @importFrom sp SpatialPoints CRS over spTransform coordinates
#' @import rgdal
#' @importFrom rgeos gBuffer gIntersects gIntersection
#' @importFrom utils head
#' @importFrom methods new
#' @seealso \code{\link{fetchR}}
#' @examples
#' # Calculate fetch for Kawau Bay
#' kawau_bay = fetch(-36.4, 174.8)
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
#' \dontrun{
#' # ---- Output to KML/KMZ
#' # Install and load plotKML library
#' if (!require(plotKML))
#'   install.packages("plotKML")
#' library(plotKML)
#' 
#' Create some labels indicating the fetch vector directions
#' labs = sapply(slot(kawau_bay, "lines"), slot, "ID")
#' 
#' # Save 'kawau_bay.kml' to the current directory
#' kml(kawau_bay, labels = labs)
#' }
#' @export
fetch = function(lat, lon, max_dist = 300, n_bearings = 9,
                 quiet = FALSE, accuracy, degree_int){
  if (!is.numeric(lon) || !is.numeric(lat))
    stop("longitude and latitude must be numeric")
  
  if (!all(length(lat) == 1, length(lon) == 1))
    stop("only one longitude and latitude can be supplied at a time")
  
  if (!is.numeric(max_dist) || length(max_dist) != 1)
    stop("max_dist must be a single number")
  
  if (max_dist < 1 || max_dist > 500)
    stop("max_dist must be between 1 and 500 km")
  
  if (!is.numeric(n_bearings) || length(n_bearings) != 1)
    stop("n_bearings must be a single integer")
  n_bearings = round(n_bearings)
  
  if (n_bearings < 1 || n_bearings > 20)
    stop("n_bearings must be between 1 and 20")
  
  if (!is.logical(quiet) || length(quiet) != 1 || is.na(quiet))
    stop("quiet must be either TRUE or FALSE")
  
  if (!missing(accuracy))
    warning("the accuracy argument has been deprecated due to an improved algorithm.")
  
  if (!missing(degree_int))
    warning("the degree_int argument has been deprecated; please use n_bearings instead.")
    
  centre_point_latlon = SpatialPoints(data.frame(lon, lat),
                                      CRS("+proj=longlat +datum=WGS84"))
  
  if (!quiet)
    message("Projecting location onto NZTM 2000 map projection")
  
  centre_point_proj = spTransform(centre_point_latlon, CRS("+init=epsg:2193"))
  
  if (!quiet)
    message("Checking coordinate is not on land")
  
  if (any(!is.na(over(coastal_nz, centre_point_proj))))
    stop("coordinate is on land")

  max_dist = max_dist * 1000
  bearings = head(seq(0, 360, by = 360 / (n_bearings * 4)), -1)
  # Rearrange sequence order to start at 90 degrees to match up with the output
  # from gBuffer
  bearings = unlist(split(bearings, bearings < 90), use.names = FALSE)
  
  # Create polygon (approximating a circle) with a given radius. These vertices
  # are used for creating the end points for the fetch bearings.
  d_bff = gBuffer(centre_point_proj, width = max_dist * 1000, quadsegs = n_bearings)
  
  # Subset NZ to incorporate only polygons within the radius to speed up 
  # computation times.
  coastal_nz_subset = coastal_nz[which(!is.na(over(coastal_nz, d_bff))), ]
  
  # Calculate end points at the maximum distances.
  max_dist_endpoints = head(coordinates(d_bff@polygons[[1]]@Polygons[[1]]), -1)
  
  # Create spatialLines object
  fetch_sp_lines = create_sp_lines(centre_point_proj, max_dist_endpoints, bearings)
  
  # Which fetch bearings hit land?
  hit_land = !sapply(gIntersects(fetch_sp_lines, coastal_nz_subset,
                                 byid = c(TRUE, FALSE), returnDense = FALSE), 
                     is.null)
  
  # Calculate intersections and identify closest shoreline

  if (!quiet)
    message("calculating fetch")
  ints = gIntersection(fetch_sp_lines, coastal_nz_subset, byid = c(TRUE, FALSE))

  fetch_ends = max_dist_endpoints
  fetch_ends[hit_land, ] = t(sapply(ints@lines, function(x){
    coordinates(x)[[1]][1, ]
  }))
  
  # Return the Fetch object
  
  new("Fetch",
      location_lat = lat,
      location_long = lon,
      subset_map = coastal_nz_subset,
      create_sp_lines(centre_point_proj, fetch_ends, bearings)
  )
}

# Internal functions ------------------------------------------------------

# Create SpatialLines objects
#
# This function takes a single location along with the end points for each 
# direction and returns a SpatialLines object.
# 
# @param d the location of interest
# @param end_points the end points for each direction of interest
# @param bearings the directions to be used for the SpatialLines ID's
#
#' @importFrom sp CRS proj4string SpatialLines Lines Line

create_sp_lines = function(d, end_points, bearings){
  
  # 1) Create the matrix of all the lons and lats
  all_mat = rbind(do.call("rbind", rep(list(d@coords), nrow(end_points))), end_points)
  
  # 2) Split this matrix into a list
  all_list = split(all_mat, 1:nrow(end_points))
  
  # 3) Create a list of 2x2 matrices indicating the start and end lons and lats
  all_list_mat = lapply(all_list, matrix, ncol = 2)
  
  # 4) Create a list of Line objects
  line_list = lapply(all_list_mat, Line)
  
  # 5) Create a list of Lines objects with different ID's
  lines_list = vector("list", length(line_list))
  for (i in seq_along(line_list)){
    lines_list[[i]] = Lines(list(line_list[[i]]), ID = bearings[i])
  }
  
  # 6) Make it spatial
  SpatialLines(lines_list, proj4string = CRS(proj4string(d)))
}
