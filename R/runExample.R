#' Run fetchR example
#'
#' Launch a Shiny application of \pkg{fetchR} that incorporates all of the
#' functionality available within the package.
#'
#' The application is also
#' \href{https://blasee.shinyapps.io/fetchR_shiny/}{available online}.
#'
#' @seealso For help on using the \pkg{fetchR} web application refer to the
#' \href{https://github.com/blasee/fetchR/blob/master/README_shiny.md#calculate-wind-fetch-using-the-shiny-application}{README}.
#'
#' @examples
#' ## Only run this application in interactive R sessions
#' if (interactive())
#'   runExample()
#'
#' @import shiny
#' @importFrom shinyjs enable disable useShinyjs
#' @importFrom sp spTransform CRS is.projected
#' @importFrom methods is as
#' @importFrom purrr walk2
#' @importFrom plotKML kml
#' @export
runExample <- function() {
  appDir <- system.file("shiny-examples", "fetchR", package = "fetchR")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `fetchR`.",
         call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
