library(fetchR)
library(sp)
library(rgdal)

options(shiny.maxRequestSize = 50 * 1024^2)

fetch_r_file = function(poly_layer, point_layer, max_dist, directions, fn){
  cat('# This file was created by the fetchR_shiny web application:
# https://blasee.shinyapps.io/fetchR_shiny/

# Unmodified, this file is only intended for interactive R sessions.

# Install and load packages -----------------------------------------------

# Install and load the latest CRAN release of fetchR
if(!require(fetchR)){
  install.packages("fetchR")
  library(fetchR)
}

# Read in the shapefiles --------------------------------------------------

# Navigate to the ', poly_layer, '.shp file
my_coast = rgdal::readOGR(dirname(file.choose()), "', poly_layer, '")

# Navigate to the ', point_layer, '.shp file
my_sites = rgdal::readOGR(dirname(file.choose()), "', point_layer, '")

# Calculate Fetch ---------------------------------------------------------

# Polygon layer:       ', poly_layer, '
# Points layer:        ', point_layer, '
# Maximum distance:    ', max_dist, 'km
# Directions per 90°:  ', directions, '

my_fetch = fetch(my_coast, my_sites, ', max_dist, ', ', directions, ')
my_fetch

# Raw data ----------------------------------------------------------------

# Transform "my_fetch" to have lon/lat coordinates
my_fetch_latlon = spTransform(my_fetch, CRS("+init=epsg:4326))

# Create a data frame containing the raw data
my_fetch.df = as(my_fetch_latlon, "data.frame")

# Plot in R ---------------------------------------------------------------

plot(my_fetch, my_coast)

# Output to KML -----------------------------------------------------------

kml(my_fetch)
message("my_fetch.kml was saved in: ", getwd())

#  ------------------------------------------------------------------------

# For more information on the fetchR package
vignette("introduction-to-fetchR")

# To cite the fetchR package in publications
citation("fetchR")

# If you encounter a problem when using this file, you can submit an issue here:
# https://github.com/blasee/fetchR/issues/new
',
sep = "", file = fn)
}

shinyServer(function(input, output) {

  rvs = reactiveValues(show_button = FALSE)

  observe({
    rvs$show_button = all(
      !is.null(input$polygon_shape),
      !is.null(input$point_shape),
      !is.null(input$n_dirs),
      !is.null(input$dist)
    )
  }
  )

  observeEvent(input$n_dirs,
               {
                 if (all(!is.null(input$polygon_shape),
                         !is.null(input$point_shape))){
                   enable("submit")
                   rvs$show_button = TRUE
                 }
               })

  observeEvent(rvs$show_button,
               {
                 if (rvs$show_button)
                   enable("submit")
                 else
                   disable("submit")
               })

  observeEvent(input$submit,
               {
                 disable("submit")
                 calc_fetch()
                 rvs$show_button = FALSE
               })

  polyShapeInput = reactive({
    inFile <- input$polygon_shape

    if (is.null(inFile))
      return(NULL)

    validate(need(any(grepl("\\.shp$", inFile$name)),
                  "Please include a shape format file (.shp)."))

    validate(need(any(grepl("\\.prj$", inFile$name)),
                  "Please include a projection format file (.prj)."))

    validate(need(any(grepl("\\.shx$", inFile$name)),
                  "Please include a shape index format file (.shx)."))

    # Names of the uploaded files
    infiles = inFile$datapath

    # Directory containing the files
    dir = unique(dirname(inFile$datapath))

    # New names for the files (matching the input names)
    outfiles = file.path(dir, inFile$name)
    walk2(infiles, outfiles, ~file.rename(.x, .y))

    x <- try(readOGR(dir, strsplit(inFile$name[1], "\\.")[[1]][1]), TRUE)

    validate(need(class(x) != "try-error", "Could not read shapefile."))

    validate(need(is(x, "SpatialPolygons"),
                  "Please provide a 'Polygon' shapefile."))

    validate(need(is.projected(x),
                  "Please project the shapefile onto a suitable map projection."))
    x
  })

  pointShapeInput = reactive({
    inFile <- input$point_shape

    if (is.null(inFile))
      return(NULL)

    validate(need(any(grepl("\\.shp$", inFile$name)),
                  "Require a shape format (.shp)."))

    validate(need(any(grepl("\\.prj$", inFile$name)),
                  "Require a projection format (.prj)."))

    validate(need(any(grepl("\\.shx$", inFile$name)),
                  "Require a shape index format (.shx)."))

    # Names of the uploaded files
    infiles = inFile$datapath

    # Directory containing the files
    dir = unique(dirname(inFile$datapath))

    # New names for the files (matching the input names)
    outfiles = file.path(dir, inFile$name)
    walk2(infiles, outfiles, ~file.rename(.x, .y))

    x <- try(readOGR(dir, strsplit(inFile$name[1], "\\.")[[1]][1]), TRUE)

    validate(need(class(x) != "try-error", "Could not read shapefile."))

    validate(need(is(x, "SpatialPoints"),
                  "Please provide a '[Multi]Point' shapefile."))
    x
  })

output$polygon_map <- renderPlot({

    poly_layer = polyShapeInput()
    point_layer = pointShapeInput()

    if (is.null(input$polygon_shape) &
        input$submit == 0)
      return(NULL)

    if (is.null(input$point_shape)){

      plot(poly_layer, border = NA, col = "lightgrey")

    } else {

      # If both projected, test for the same map projections here...

      if (all(is.projected(poly_layer),
              !is.projected(point_layer)))
        point_layer = spTransform(point_layer,
                                  CRS(proj4string(poly_layer)))

      # Make sure there are no points on land here...

      plot(point_layer, col = "red")
      plot(poly_layer, add = TRUE, border = NA, col = "lightgrey")
    }
  })

  calc_fetch = eventReactive(input$submit, {

    poly_layer = polyShapeInput()
    point_layer = pointShapeInput()

    validate(need(all(input$n_dirs <= 20,
                      input$n_dirs > 0),
                  "Directions per quadrant: please choose a number between 1 and 20."))

    # Must have a '[Nn]ame' column to get names
    name_col = grep("^[Nn]ame$", names(point_layer))

    if (length(name_col)) {
      my_fetch = fetch(poly_layer,
                       point_layer,
                       max_dist = input$dist,
                       n_directions = input$n_dirs,
                       site_names = as.character(point_layer@data[, name_col]),
                       quiet = TRUE)
    } else{
      my_fetch = fetch(poly_layer,
                       point_layer,
                       max_dist = input$dist,
                       n_directions = input$n_dirs,
                       quiet = TRUE)
    }
    list(my_fetch = my_fetch,
         my_fetch_latlon = spTransform(my_fetch, CRS("+init=epsg:4326")))
  })

  output$fetch_plot = renderPlot({
    plot(calc_fetch()$my_fetch, polyShapeInput())
    })

  output$summary = renderTable({
    poly_layer = polyShapeInput()
    point_layer = pointShapeInput()

    if (is.null(input$polygon_shape) &
        input$submit == 0)
      return(NULL)

    summary(calc_fetch()$my_fetch)
  },
  rownames = TRUE, colnames = TRUE)

  output$distances = renderDataTable({
    poly_layer = polyShapeInput()
    point_layer = pointShapeInput()

    if (is.null(input$polygon_shape) &
        input$submit == 0)
      return(NULL)

    calc_fetch.df = as(calc_fetch()$my_fetch_latlon, "data.frame")
    class(calc_fetch.df$direction) = "integer"
    calc_fetch.df
  })

  output$dl_file = downloadHandler(
    filename = function(){
      # Replace '.' with '_' in the file name
      paste0(strsplit(input$file_name, ".", fixed = TRUE)[[1]][1],
             switch(input$format,
                    CSV = ".csv",
                    KML = ".kml",
                    R = ".R"
             ))
    },
    content = function(file){
      switch(input$format,
             CSV = write.csv(as(calc_fetch()$my_fetch_latlon, "data.frame"), file, row.names = FALSE),
             KML = kml(calc_fetch()$my_fetch_latlon, file.name = file),
             R = fetch_r_file(
               head(strsplit(input$polygon_shape$name, ".", fixed = TRUE)[[1]], -1),
               head(strsplit(input$point_shape$name, ".", fixed = TRUE)[[1]], -1),
                              input$dist, input$n_dirs, file))
    }
  )
})
