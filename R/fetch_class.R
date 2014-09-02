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

#' Summarise a Fetch Object
#' 
#' The \code{summary} function calculates the mean and median fetch and the most 
#' exposed direction(s).
#' 
#' @param object \code{fetch} object as returned by \code{\link{fetch}}.
#' 
#' @importFrom methods setMethod
#' @aliases summary,fetch-method
#' @rdname summary
#' @name summary
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

#' @aliases fetch
#' @rdname fetch
#' @importFrom methods setMethod
#' @export
setMethod("show", "fetch", function(object){
  print(object)
})

#' Plot a Fetch Object
#' 
#' This is the default plot method for a \code{\link{fetch}} object. A map is
#' plotted with the area determined by the length of the direction vectors. The 
#' vectors are plotted as lines originating from the location's coordinates.
#' 
#' @param x \code{fetch} object as returned by \code{\link{fetch}}.
#' @param y missing (not used).
#' @param ... further arguments passed to \code{\link{segments}}
#' 
#' @importFrom methods setMethod
#' @aliases plot,fetch,missing-method
#' @rdname plot
#' @name plot
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

#' @importFrom methods setGeneric
setGeneric("save_kml", function(object, file_name) {
  standardGeneric("save_kml")
})

#' Save a KML file of the direction vectors
#' 
#' The \code{save_kml} function saves a KML file for use in Google Earth or 
#' other KML-friendly software.
#' 
#' This function is useful for checking that no vectors pass through any 
#' subtidal reefs or other potentially fetch-limiting structures that aren't 
#' defined in the original shape file.
#' 
#' @importFrom methods setMethod
#' @importFrom XML newXMLDoc newXMLNode saveXML
#' @aliases save_kml,fetch,ANY-method
#' @rdname save_kml
#' @name save_kml
#' @export
setMethod(
  "save_kml", 
  signature(object = "fetch", file_name = "ANY"), 
  function(object, file_name){
    if (missing(file_name))
      stop("file_name must be supplied")
    if (!is.character(file_name))
      stop("file_name must be a character string")
    file_name = file_name[1]
    doc = newXMLDoc()
    kml.node = 
      newXMLNode("kml", 
                 doc = doc, 
                 namespaceDefinitions = 
                   c("http://www.opengis.net/kml/2.2", 
                     gx = "http://www.google.com/kml/ext/2.2", 
                     kml = "http://www.opengis.net/kml/2.2", 
                     atom = "http://www.w3.org/2005/Atom"))
    Document.node = newXMLNode("Document", 
                               parent = kml.node)
    newXMLNode("name", strsplit(file_name, ".kml")[[1]],
               parent = Document.node)
    newXMLNode("StyleMap", attrs = c(id = "mouseover"),
               parent = Document.node,
               newXMLNode("Pair",
                          newXMLNode("key", "normal"),
                          newXMLNode("styleUrl", "#normal")),
               newXMLNode("Pair",
                          newXMLNode("key", "highlight"),
                          newXMLNode("styleUrl", "#highlight")))
    newXMLNode("Style", attrs = c(id = "highlight"),
               parent = Document.node,
               newXMLNode("LineStyle",
                          newXMLNode("color", "FF1400FF"),
                          newXMLNode("width", "3")))
    newXMLNode("Style", attrs = c(id = "normal"),
               parent = Document.node,
               newXMLNode("LineStyle",
                          newXMLNode("color", "50146AFF"),
                          newXMLNode("width", "2")))
    
    
    fetch_folder = newXMLNode("Folder", 
                              parent = Document.node,
                              newXMLNode("name", "Fetch"),
                              newXMLNode("open", "1"))
    for (i in seq_along(object$distance))
      newXMLNode("Placemark",
                 newXMLNode("name", paste(object$direction[i], "degrees")),
                 newXMLNode("description", paste(object$distance[i], "km")),
                 newXMLNode("styleUrl", "#mouseover"),
                 newXMLNode("LineString",
                            newXMLNode("tessellate", "1"),
                            newXMLNode("coordinates", 
                                       paste0(object@location_long, ",",
                                             object@location_lat, ",",
                                             "0", " ",
                                             object$longitude[i], ",",
                                             object$latitude[i], ",",
                                             "0"))), 
                 parent = fetch_folder)
    
    if (grepl("\\.kml$", file_name))
      xml_file = file_name
    else
      xml_file = paste0(file_name, ".kml")
    
    saveXML(doc, file = xml_file)
    message(paste("output KML file:", xml_file))
  }
)