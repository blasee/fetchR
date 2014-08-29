load(system.file("extdata", "nz_coast.rda", package = "fetchR"))
load(system.file("extdata", "nz_islands.rda", package = "fetchR"))

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
#' coastal or do not (yet?) have the high resolution coastal boundaries to 
#' calculate the fetch.
#' 
#' @seealso \code{\link{fetch}}
#' @name fetchR
#' @aliases fetchR-package
#' @docType package
#' @keywords package
NULL

#' @rdname fetch
#' @aliases fetch
#' @importFrom methods setClass
#' @importClassesFrom sp SpatialPolygonsDataFrame
setClass("fetch", 
         slots = c(location_lat = "numeric",
                   location_long = "numeric",
                   subset_coast = "SpatialPolygonsDataFrame",
                   subset_island = "SpatialPolygonsDataFrame"),
         contains = "data.frame")

#' @importFrom methods setMethod
#' @export
setMethod("summary", "fetch", function(object){
  which_max = which(object$distance == max(object$distance))
  cat(
    "Latitude: ", object@location_lat, "\n",
    "Longitude: ", object@location_long, "\n",
    "Average fetch:\t", mean(object$distance), "\n",
    "Median fetch:\t", median(object$distance), "\n",
    "Exposed directions:\t", paste(object$direction[which_max], collapse = ", "), 
    "\n", sep = "")
})

#' @importFrom methods setMethod
#' @export
setMethod("show", "fetch", function(object){
  print(object[, 3:4])
})

#' @importFrom methods setMethod
#' @export
setMethod("plot", c("fetch", "missing"), function(x, y, ...){
  x0 = x@location_long
  y0 = x@location_lat
  x1 = x$longitude
  y1 = x$latitude
  message("initializing plot...")
  dev.hold()
  plot(x[, 1:2], type = "n")
  plot(x@subset_coast, add = TRUE, col = "grey")
  plot(x@subset_island, add = TRUE, col = "grey")
  segments(x0, y0, x1, y1, ...)
  invisible(dev.flush())
})