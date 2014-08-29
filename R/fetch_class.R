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
setClass("fetch", contains = "data.frame")

setMethod("summary", "fetch", function(object){
  which_max = which(object$distance == max(object$distance))
  cat(
    "Average fetch: \t", mean(object$distance), "\n",
    "Median fetch \t", median(object$distance), "\n",
    "Exposed directions \t", paste(object$direction[which_max], collapse = ", "), 
    "\n")
})

load(system.file("extdata", "nz_coast.rda", package = "fetchR"))
load(system.file("extdata", "nz_islands.rda", package = "fetchR"))