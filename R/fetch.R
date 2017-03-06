#' Calculate Wind Fetch
#' 
#' Wind fetch is the unobstructed length of water over which wind can blow, and
#' it is commonly used as a measure of exposure to wind and waves at coastal 
#' sites. The \code{fetch} function automatically calculates the wind fetch for
#' marine locations within the boundaries of a specified (polygon) shapefile.
#' This allows wind fetch to be calculated anywhere around the globe.
#' 
#' The function takes a \code{\link{SpatialPolygons-class}} object 
#' (\code{polygon_layer}) that represents the coastline, surrounding islands, 
#' and any other obstructions, and calculates the wind fetch for every specifed 
#' direction. This is done for all the user-defined sites. These sites are 
#' represented as the point geometries in a 
#' \code{\link[sp]{SpatialPoints-class}} object.
#' 
#' The directions for which the wind fetch are calculated for each site are 
#' determined by the number of directions per quadrant (\code{n_directions}). 
#' The default value of 9 calculates 9 fetch vectors per quadrant (90 degrees), 
#' or equivalently, one fetch vector every 10 degrees. The first fetch vector is 
#' always calculated for the northerly direction (0/360 degrees).
#' 
#' @param polygon_layer A \code{\link[sp]{SpatialPolygons}} object where the
#'                      polygon geometries represent any obstructions to fetch
#'                      calculations including the coastline, islands and/or 
#'                      exposed reefs.
#' @param site_layer A \code{\link[sp]{SpatialPoints}} object where the point 
#'                   geometries represent the site locations.
#' @param max_dist numeric. Maximum distance in kilometres (default 300). This 
#'                 will need to be scaled manually if the units for the CRS are 
#'                 not 'm'.
#' @param n_directions numeric. The number of fetch vectors to calculate per 
#'                     quadrant (default 9).
#' @param site_names character vector of the site names. If missing, default 
#'                   names are created ('Site 1', 'Site 2', ...).
#' @param quiet logical. Suppress diagnostic messages? (Default \code{FALSE}).
#' 
#' @return Returns a \code{\link{Fetch}} object.
#' 
#' @note At least one of the inputs to the \code{polygon_layer} or 
#'       \code{site_layer} arguments must be projected. If one of the inputs are 
#'       not projected, then it will be transformed to have the same projection 
#'       as the other. If both are projected, but do not have identical 
#'       coordinate reference systems (CRS) then \code{site_layer} will be 
#'       transformed to the same CRS as \code{polygon_layer}.
#' 
#' @seealso \code{\link[rgdal]{spTransform}} for methods on transforming map 
#'          projections and datum.
#' 
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
fetch = function(polygon_layer, site_layer, max_dist = 300, n_directions = 9,
                 site_names, quiet = FALSE){
  
  if (!is(coast_poly, "SpatialPolygons"))
    stop(paste("polygon_layer must be a SpatialPolygons object.\nSee",
               "'?sp::SpatialPolygons' for details on how to create a",
               "SpatialPolygons object."), call. = FALSE)
  
  if (!is(site_layer, "SpatialPoints"))
    stop(paste("site_layer must be a SpatialPoints object.\nSee",
         "'?sp::SpatialPoints' for details on how to create a SpatialPoints",
         "object."), call. = FALSE)
  
  if (!is.numeric(max_dist) || length(max_dist) != 1)
    stop("max_dist must be a single number.", call. = FALSE)
  
  if (!is.numeric(n_directions) || length(n_directions) != 1)
    stop("n_directions must be a single integer.", call. = FALSE)
  n_directions = round(n_directions)
  
  if (n_directions < 1 || n_directions > 20)
    stop("n_directions must be between 1 and 20.", call. = FALSE)
  
  if (!missing(site_names)){
    site_names = as.character(site_names)
    
    if (length(site_names) != length(site_layer)){
      warning(paste("lengths differ for the number of sites and site names;", 
                    "using default names instead."), call. = FALSE)
      site_names = paste("Site", seq_along(site_layer))
    }
  } else {
    site_names = paste("Site", seq_along(site_layer))
  }
  
  quiet = as.logical(quiet[1])
  
  ## Check if the polygon and points layers are projected, and ensure they have 
  ## the same CRS.
  which_proj = c(is.projected(polygon_layer), is.projected(site_layer))
  
  if (all(!which_proj))
    stop("polygon_layer and/or site_layer must be projected to calculate fetch", 
         call. = FALSE)
  
  if (all(which_proj) && !identicalCRS(polygon_layer, site_layer)){
    warning("the CRS for polygon_layer and site_layer differ; transforming
              site_layer CRS to match")
    site_layer = spTransform(site_layer, CRS(proj4string(polygon_layer)))
  }
  
  if (!which_proj[1]){
    if (!quiet)
      message("projecting polygon_layer onto the site_layer CRS")
    polygon_layer = spTransform(polygon_layer, CRS(proj4string(site_layer)))
  }
  
  if (!which_proj[2]){
    if (!quiet)
      message("projecting site_layer onto the polygon_layer CRS")
    site_layer = spTransform(site_layer, CRS(proj4string(polygon_layer)))
  }

  if (!quiet)
    message("checking site locations are not on land")
  
  # Should remove these sites with warning instead of returning error.
  if (any(!is.na(over(polygon_layer, site_layer))))
    stop("at least one site location is on land")
  
  # Convert max_dist to appropriate units.
  # First of all convert max_dist to metres (default)
  max_dist = max_dist * 1000
  
  # Double check if metres are the correct units
  proj_unit = strsplit(gsub("*.+units=", "", 
                            CRSargs(CRS(proj4string(coast_proj)))), " ")[[1]][1]
  
  # If not, warn the user that the supplied max_dist should be scaled 
  # appropriately
  if (proj_unit != "m")
    warning("the PROJ.4 unit is not metres; ensure max_dist has been scaled 
            appropriately")
  
  directions = head(seq(0, 360, by = 360 / (n_directions * 4)), -1)
  
  # Rearrange sequence order to start at 90 degrees to match up with the output
  # from gBuffer
  directions = unlist(split(directions, directions < 90), use.names = FALSE)
  
  # Create an empty list to store the Fetch objects
  fetch_list = vector("list", length(site_layer))
  
  for (i in seq_along(site_layer)){
    
    message("calculating fetch for ", site_names[i], " (", i, " out of ", 
            length(site_layer), ")")
    
    ## Create polygon (approximating a circle) with a given radius. These 
    ## vertices are used for creating the end points for the fetch vectors.
    d_bff = gBuffer(site_layer[i, ], width = max_dist, quadsegs = n_bearings)
    
    ## Calculate end points at the maximum distances.
    fetch_ends = head(coordinates(d_bff@polygons[[1]]@Polygons[[1]]), -1)
    fetch_ends = fetch_ends[order(directions), ]
    
    ## Create a list of Line objects radiating from the site location to the 
    ## maximum distance for each direction.
    line_list = create_line_list(site_layer[i, ], fetch_ends)
    
    ## Create a SpatialLines object (i.e. add in CRS information)
    fetch_sp_lines = create_sp_lines(line_list, sort(directions), polygon_layer)
    
    ## Subset polygon coastline layer to only incorporate polygons that 
    ## interfere with any of the fetch vectors. This will speed up computation 
    ## times.
    poly_layer_subset = 
      polygon_layer[which(!is.na(over(polygon_layer, fetch_sp_lines))), ]
    
    if (length(poly_layer_subset) > 0){
      
      ## Calculate the fetch bearings that hit land
      hit_land = !sapply(gIntersects(fetch_sp_lines, poly_layer_subset,
                                     byid = c(TRUE, FALSE), returnDense = FALSE),
                         is.null)
      
      ## Calculate intersections and identify closest shoreline for those 
      ## vectors that hit land
      ints = gIntersection(fetch_sp_lines[hit_land], poly_layer_subset, 
                           byid = c(TRUE, FALSE))
      
      fetch_ends[hit_land, ] = t(sapply(ints@lines, function(x){
        coordinates(x)[[1]][1, ]
      }))
      
      ## Update the line list and spatialLines objects
      line_list = create_line_list(site_layer[i, ], fetch_ends)
      fetch_sp_lines = create_sp_lines(line_list, sort(directions), polygon_layer)
    }
    
    fetch.df = data.frame(fetch = SpatialLinesLengths(fetch_sp_lines) / 1000,
                          stringsAsFactors = FALSE)
    
    ## Create a SpatialLinesDataFrame object to include the fetch lengths, and 
    ## add it to the Fetch list
    fetch_list[[i]] = SpatialLinesDataFrame(fetch_sp_lines, fetch.df)
  }
  fetch_list
}
