#' Calculate Wind Exposure with the \pkg{fetchR} Package
#'
#' The \pkg{fetchR} package allows for an objective calculation of wind fetch
#' and provides methods to visualise the wind exposure and export the fetch
#' vectors to a KML file.
#'
#' Fetch is an important measurement in coastal applications. It
#' provides a measurement for the unobstructed length of water that wind from a
#' certain direction can blow over. The higher the wind fetch from a certain
#' direction, the more energy is imparted onto the surface of the
#' water resulting in a larger sea state. Therefore, the larger
#' the fetch, the larger the exposure to wind and the more likely the
#' site experiences larger sea states.
#'
#' The fetch length from all directions (and from each quadrant) can
#' be averaged to provide an indication of the location's exposure to
#' wind. The \pkg{fetchR} package
#' calculates the lengths of wind fetch vectors from all directions, at any
#' given location(s) on Earth, and can provide summaries, visualisations and KML
#' files along with the raw data.
#'
#' @seealso \code{\link{fetch}} for an extensive reproducible example.
#' @seealso \code{vignette("introduction-to-fetchR")} for a short introduction
#' to **fetchR**.
#' @seealso \url{http://windfetch.cer.auckland.ac.nz/} for the online web 
#' application.
#' @name fetchR
#' @docType package
#' @keywords package
NULL

#' Fetch Class
#'
#' Class to hold Fetch objects.
#'
#' A \code{Fetch} object is essentially a list of \code{\link[sp]{SpatialLines}}
#' objects.
#'
#' @note Fetch objects should only be created using the \code{\link{fetch}}
#' function.
#'
#' @slot names character vector containing the names for each location.
#' @slot max_dist numeric vector of length 1 containing the maximum distance
#'                a fetch vector is allowed.
#'
#' @section Extends:
#' Class \code{"list"} directly, and class \code{"vector"}, by class \code{"list"}.
#'
#' @name Fetch
#' @rdname Fetch-class
#' @importFrom methods setClass
setClass("Fetch", slots = c(names = "character", max_dist = "numeric"),
         contains = "list")

#' @importFrom sp proj4string
# Fetch Class Validation
#
# Checks to ensure that all the CRS are equal.
valid_fetch = function(object){
  errors = character()

  if (length(unique(sapply(object, proj4string))) != 1){
    msg = "All sites must have the same CRS"
    errors = c(errors, msg)
  }

  if (length(errors) == 0){
    TRUE
  } else {
    errors
  }
}

#' @importFrom methods setValidity
setValidity("Fetch", valid_fetch)

#' Summarise a Fetch Object
#'
#' The \code{summary} function calculates the average fetch for the separate
#' northerly, easterly, southerly and westerly quadrants. For example, the mean
#' fetch for the northerly component averages over the fetch vectors with
#' directions between 315 (inclusive) and 45 (exclusive) degrees, i.e. the fetch
#' vectors within the interval [315, 45).
#'
#' @return The \code{summary} function returns a \code{\link{data.frame}}.
#'
#' @param object a \code{Fetch} object that has been returned by the
#'               \code{\link{fetch}} function.
#'
#' @importFrom methods setMethod
#' @export
setMethod("summary", "Fetch", function(object){
  summary.df = data.frame(t(sapply(object, function(x){
    by(x@data$fetch, x@data$quadrant, mean)
  })))
  summary.df$Average = sapply(object, function(x)
    mean(x@data$fetch))
  summary.df
})

#' @rdname summary-Fetch-method
#' @importFrom methods setMethod
#' @importFrom methods show
setMethod("show", "Fetch", function(object){

  cat("Is projected\t: ", is.projected(object[[1]]), "\n",
      "Max distance\t: ", object@max_dist, " km\n",
      "Directions\t: ", nrow(object[[1]]@data), "\n",
      "Sites\t\t: ", length(object), "\n\n",
      sep = "")
  print(round(summary(object), 1))
})

#' spTransform for map projection and datum transformation
#'
#' spTransform for map projection and datum transformation
#'
#' @param x \code{\link{Fetch}} object to be transformed
#' @param CRSobj object of class \code{\link[sp]{CRS}}, or of class character in
#'               which case it is converted to \code{\link{CRS}}
#' @param ... further arguments (ignored)
#' @importFrom methods setMethod new
#' @importFrom sp spTransform CRS
#' @return \code{\link{Fetch}} object with coordinates transformed to the
#'         new coordinate system.
#' @export
setMethod("spTransform",
          signature(x = "Fetch", CRSobj = "CRS"),
          function(x, CRSobj){
            validObject(x)
            obj_new = lapply(x, spTransform, CRSobj)
            new("Fetch", obj_new, names = x@names, max_dist = x@max_dist)
          }
)

#' @rdname spTransform-Fetch-CRS-method
#' @importFrom methods setMethod
#' @importFrom sp spTransform CRS
#' @export
setMethod("spTransform",
          signature(x = "Fetch", CRSobj = "character"),
          function(x, CRSobj){
            validObject(x)
            CRSobj = CRS(CRSobj)
            spTransform(x, CRSobj)
            }
)

#' Retrieve projection attributes for Fetch objects
#'
#' Retrieve projection attributes for \code{\link{Fetch}} objects.
#' @param obj \code{\link{Fetch}} object
#' @importFrom methods setMethod signature
#' @importFrom sp proj4string
#' @export
setMethod("proj4string",
          signature(obj = "Fetch"),
          function (obj) {
            validObject(obj)

            proj4string(obj[[1]])
          }
)

#' @importFrom methods setAs
#' @importFrom sp is.projected
setAs("Fetch", "data.frame", function(from){
  validObject(from)
  fetch.df = data.frame(do.call("rbind", lapply(from, slot, "data")),
                        row.names = NULL)

  coords.mat = do.call("rbind",
                       lapply(
                         lapply(from, coordinates), function(x)
                           do.call("rbind", lapply(x, function(z)
                             z[[1]]))))

  coords.df = cbind(coords.mat[seq(1, nrow(coords.mat), by = 2), ],
                    coords.mat[seq(2, nrow(coords.mat), by = 2), ])

  if (is.projected(from[[1]]))
    colnames(coords.df) = c("x", "y", "x_end", "y_end")
  else
    colnames(coords.df) = c("lon", "lat", "lon_end", "lat_end")

  data.frame(cbind(fetch.df, coords.df))
})


#' @importFrom methods setAs slot
#' @importFrom sp SpatialLines Lines proj4string CRS
setAs("Fetch", "SpatialLines", function(from){
  validObject(from)

  lines_list = do.call("c", lapply(from, slot, "lines"))
  line_list = do.call("c", lapply(lines_list, slot, "Lines"))
  lines_list = list(Lines(line_list, ID = "all_fetch_lines"))

  SpatialLines(lines_list, CRS(proj4string(from)))
})

#' Plot a Fetch Object
#'
#' Plot method for \code{\link{Fetch}} objects.
#'
#' These plot methods allow for the fetch vectors to be plotted (missing
#' \code{y}), or the fetch vectors to be plotted along with a
#' \code{\link[sp]{SpatialPolygons}} object. If both \code{x} and \code{y} are
#' supplied, then it does not matter which argument is supplied first.
#'
#' @param x either a \code{\link{Fetch}} object as returned by
#'          \code{\link{fetch}}, or a \code{\link[sp]{SpatialPolygons}} object.
#' @param y can be missing, otherwise same as \code{x}.
#' @param ... further arguments passed to
#'            \code{\link[sp]{plot,SpatialLines,missing-method}}.
#'
#' @importFrom methods setMethod as
#' @importFrom sp plot
#' @export
setMethod("plot",
          signature(x = "Fetch", y = "missing"),
          definition = function(x, y, ...){
            validObject(x)
            plot(as(x, "SpatialLines"), ...)
          })

#' @rdname plot-Fetch-missing-method
#' @importFrom methods setMethod as signature validObject
#' @importFrom sp plot proj4string CRS identicalCRS
#' @export
setMethod("plot",
          signature(x = "Fetch", y = "SpatialPolygons"),
          definition = function(x, y, ...){
            validObject(x)

            identical_crs = identicalCRS(x, y)

            if (!identical_crs){
              warning(paste("transforming fetch vectors onto the same map",
                            "CRS as the polygon layer"), call. = FALSE)
              x = spTransform(x, CRS(proj4string(y)))
            }

            plot(as(x, "SpatialLines"), ...)
            plot(y, add = TRUE, col = "lightgrey", border = NA)
          })

#' @rdname plot-Fetch-missing-method
#' @importFrom methods setMethod signature validObject
#' @export
setMethod("plot",
          signature(x = "SpatialPolygons", y = "Fetch"),
          definition = function(x, y, ...){
            plot(y, x, ...)
          })

#' Write a Fetch object to a KML file
#'
#' Write a \code{\link{Fetch}} object to a KML file. Various aesthetics
#' parameters can be set via \code{colour}, \code{alpha}, \code{size},
#' \code{shape} arguments.
#'
#' @param obj a \code{\link{Fetch}} object
#' @param folder.name character; folder name in the KML file
#' @param file.name character; output KML file name
#' @param overwrite logical; overwrite the existing file if one exists? Default
#'                  FALSE
#' @param ... additional aesthetics arguments passed to
#'            \code{\link[plotKML]{kml_layer.SpatialLines}}
#'
#' @importFrom methods setMethod signature validObject
#' @importFrom plotKML kml kml_open kml_close kml_layer normalizeFilename
#' @export
setMethod("kml",
          signature(obj = "Fetch"),
          definition =
            function(obj,
                     folder.name = normalizeFilename(deparse(
                       substitute(obj, env = parent.frame()))),
                     file.name = paste(normalizeFilename(deparse(
                       substitute(obj, env = parent.frame()))), ".kml",
                       sep = ""),
                     overwrite = FALSE, ...){
              validObject(obj)

              kml_open(file.name = file.name, folder.name = folder.name,
                       overwrite = overwrite, kml_visibility = FALSE)

              on.exit(kml_close(file.name))

              for (i in seq_along(obj))
                kml_layer(obj[[i]], subfolder.name = obj@names[i], ...)
            })
