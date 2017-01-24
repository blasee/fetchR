load(system.file("extdata", "coastal_nz.rda", package = "fetchR"))

#' Calculate Wind Exposure with the \pkg{fetchR} Package
#' 
#' The \pkg{fetchR} package provides an objective calculation of wind fetch.
#' 
#' Fetch is an important measurement in coastal applications, which
#' provides a measurement for the unobstructed length of water that wind from a
#' certain direction can blow over. The higher the wind fetch from a certain bearing,
#'  the more energy is imparted to the surface of the 
#' water resulting in a larger sea state
#' (\url{http://en.wikipedia.org/wiki/Fetch_(geography)}). Therefore, the larger
#' the fetch, the larger the exposure to wind and the more likely the coastal
#' site experiences large sea states.
#' 
#' Fetch from all directions can therefore be averaged to provide an overall 
#' indication of the location's exposure to wind. The default is to provide the
#' lengths (km) for every 10 degree bearings on the NZTM 2000 projection.
#' Details of the New Zealand Transverse Mercator 2000 map projection can be found
#' at 
#' \url{http://www.linz.govt.nz/data/geodetic-system/datums-projections-and-heights/projections/new-zealand-transverse-mercator-2000}.
#' 
#' The \pkg{fetchR} package contains data sourced from Land Information New Zealand under CC-By.
#' 
#' @note The \pkg{fetchR} package is intended for New Zealand coastal
#' applications and only supports the specification of areas within the following bounding 
#' box:
#' 
#' \tabular{lll}{
#'  \tab Min \tab Max \cr
#' Longitude \tab 165.869 \tab  183.846 \cr
#' Latitude  \tab -52.6209 \tab  -29.2313 \cr
#' }
#' 
#' @seealso \code{\link{fetch}} for calculating fetch.
#' @name fetchR
#' @aliases fetchR-package
#' @docType package
#' @keywords package
NULL

#' Fetch Object
#' 
#' Extends the \code{\link[sp]{SpatialLines}} class to include the subset of the 
#' coastal NZ map which can speed up plotting.
#' 
#' @slot location_lat latitude of the location of interest.
#' @slot location_lon longitude of the location of interest.
#' @slot subset_map a subset of the coastal NZ shapefile to increase efficiency when plotting.
#' 
#' @aliases Fetch
#' @importFrom methods setClass
#' @importClassesFrom sp SpatialPolygonsDataFrame SpatialLines
setClass("Fetch", 
         slots = c(location_lat = "numeric",
                   location_long = "numeric",
                   subset_map = "SpatialPolygonsDataFrame"),
         contains = "SpatialLines")

#' Summarise a Fetch Object
#' 
#' The \code{summary} function calculates the mean and median fetch of the 
#' location, along with the average fetch for the separate northerly, easterly, 
#' southerly and westerly quadrants. The mean fetch for the northerly component,
#' for example, averages over the fetch vectors between directions 315 (inclusive)
#' and 45 (exclusive), i.e. the fetch vectors within the interval [315, 45). 
#' The number of bearings per quadrant (\code{n_bearings}) is also returned to 
#' remind the user how many vectors were used for calculating the means for each 
#' quadrant.
#' 
#' @param object \code{Fetch} object as returned by \code{\link{fetch}}.
#' 
#' @importFrom methods setMethod
#' @aliases summary,Fetch-method
#' @importFrom sp SpatialLinesLengths
#' @importFrom stats median
#' @importFrom methods slot
#' @export
setMethod("summary", "Fetch", function(object){
  angles = as.numeric(sapply(slot(object, "lines"), slot, "ID"))
  angles_bin = findInterval(angles, seq(45, 315, by = 90))
  angles_bin[angles_bin == 4] = 0
  cat(
    "Latitude:  ", object@location_lat, "\n",
    "Longitude: ", object@location_long, "\n",
    "Average:   ", round(mean(SpatialLinesLengths(object)/1000), 2), "km\n",
    "Median:    ", round(median(SpatialLinesLengths(object)/1000), 2), "km\n\n",
    "Average northerly fetch [315, 45):  ", 
    round(mean(SpatialLinesLengths(object)[angles_bin == 0] / 1000), 1), "km\n",
    "Average easterly fetch [45, 135):   ", 
    round(mean(SpatialLinesLengths(object)[angles_bin == 1] / 1000), 1), "km\n",
    "Average southerly fetch [135, 225): ", 
    round(mean(SpatialLinesLengths(object)[angles_bin == 2] / 1000), 1), "km\n",
    "Average westerly fetch [225, 315):  ", 
    round(mean(SpatialLinesLengths(object)[angles_bin == 3] / 1000), 1), "km\n\n",
    "n_bearings = ", table(angles_bin)[[1]], "\n", sep = "")
})

#' @aliases fetch
#' @aliases show,Fetch-method
#' @rdname fetch
#' @param object a \code{\link{Fetch}} object.
#' @importFrom methods setMethod
#' @importFrom sp spTransform SpatialLinesLengths
#' @import rgdal
#' @importMethodsFrom methods show
#' @export
setMethod("show", "Fetch", function(object){
  obj_latlon = spTransform(object, CRS("+proj=longlat +datum=WGS84"))
  lat_lon_mat = t(sapply(sapply(slot(obj_latlon, "lines"), slot, "Lines"), 
                         slot, "coords"))[, c(4, 2)]
  unord_df = data.frame(latitude = lat_lon_mat[, 1],
                        longitude = lat_lon_mat[, 2],
                        direction = as.numeric(
                          sapply(slot(object, "lines"), slot, "ID")),
                        fetch = round(SpatialLinesLengths(object) / 1000, 2))
  ord_df = unord_df[order(unord_df$direction), ]
  rownames(ord_df) = NULL
  print(ord_df)
})

#'@importFrom methods setGeneric isGeneric
if (!isGeneric("plot"))
  setGeneric("plot", function(x, y, ...) standardGeneric("plot"))

#' Plot a Fetch Object
#' 
#' This is the default plot method for a \code{\link{Fetch}} object. The NZ
#' Transverse Mercator 2000 projection is used for the plot and the fetch 
#' vectors are plotted as lines originating from the location's coordinates.
#' 
#' @param x \code{\link{Fetch}} object as returned by \code{\link{fetch}}.
#' @param y missing (not used).
#' @param ... further arguments passed to \code{\link[sp]{plot,SpatialLines,missing-method}}.
#' 
#' @importFrom methods setMethod as
#' @importFrom sp SpatialLines plot
#' @export
setMethod("plot", 
          signature(x = "Fetch", y = "missing"), 
          definition = function(x, y, ...){
            plot(as(x, "SpatialLines"), ...)
            plot(x@subset_map, add = TRUE, col = "lightgrey")
          })

#' Deprecated Functions in \pkg{fetchR}
#' 
#' \code{save_kml} has been deprecated. Instead use the \code{kml} function in
#' the \pkg{plotKML} package.
#' 
#' @examples 
#' \dontrun{
#' kawau_bay = fetch(-36.4, 174.8)
#' 
#' # Install plotKML if required
#' if (!require(plotKML))
#'   install.packages("plotKML")
#'   
#' library(plotKML)
#' 
#' # Create some labels indicating the fetch vector directions
#' labs = sapply(slot(kawau_bay, "lines"), slot, "ID")
#' 
#' # Save 'kawau_bay.kml' to the current directory
#' kml(kawau_bay, labels = labs)
#' }
#' 
#' @name fetchR-deprecated
#' @aliases save_kml
#' @export
save_kml = function(){
  .Deprecated("kml", "fetchR")
}