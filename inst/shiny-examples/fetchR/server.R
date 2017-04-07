options(shiny.maxRequestSize = 50 * 1024^2)

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
    dir_name = unique(dirname(inFile$datapath))

    # New names for the files (matching the input names)
    outfiles = file.path(dir_name, inFile$name)
    walk2(infiles, outfiles, ~file.rename(.x, .y))

    x <- try(readOGR(dir_name, strsplit(inFile$name[1], "\\.")[[1]][1]), TRUE)

    validate(need(class(x) != "try-error", "Could not read shapefile."))

    validate(need(is(x, "SpatialPolygons"),
                  "Please provide a 'Polygon' shapefile."))

    validate(need(is.projected(x),
                  "Please project the shapefile onto a suitable map projection."))
    list(x = x,
         dir_name = tail(strsplit(dir_name, "/")[[1]], 1))
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
    dir_name = unique(dirname(inFile$datapath))

    # New names for the files (matching the input names)
    outfiles = file.path(dir_name, inFile$name)
    walk2(infiles, outfiles, ~file.rename(.x, .y))

    x <- try(readOGR(dir_name, strsplit(inFile$name[1], "\\.")[[1]][1]), TRUE)

    validate(need(class(x) != "try-error", "Could not read shapefile."))

    validate(need(is(x, "SpatialPoints"),
                  "Please provide a '[Multi]Point' shapefile."))
    list(x = x,
         dir_name = tail(strsplit(dir_name, "/")[[1]], 1))
  })

  output$polygon_map <- renderPlot({

    poly_layer = polyShapeInput()$x
    point_layer = pointShapeInput()$x

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

    poly_layer = polyShapeInput()$x
    point_layer = pointShapeInput()$x

    validate(need(all(input$n_dirs <= 20,
                      input$n_dirs > 0),
                  "Directions per quadrant: please choose a number between 1 and 20."))

    withCallingHandlers({
      html("text", "")
      my_fetch = fetch(poly_layer,
                       point_layer,
                       max_dist = input$dist,
                       n_directions = input$n_dirs,
                       quiet = TRUE)
      message("")
    },
    message = function(m){
      emph_text = paste0("<strong>", m$message, "</strong>")
      html(id = "text", html = emph_text)
    })

    list(my_fetch = my_fetch,
         my_fetch_latlon = spTransform(my_fetch, CRS("+init=epsg:4326")))
  })

  output$fetch_plot = renderPlot({
    plot(calc_fetch()$my_fetch, polyShapeInput()$x)
  })

  output$summary = renderTable({
    poly_layer = polyShapeInput()$x
    point_layer = pointShapeInput()$x

    if (is.null(input$polygon_shape) &
        input$submit == 0)
      return(NULL)

    summary(calc_fetch()$my_fetch)
  },
  rownames = TRUE, colnames = TRUE)

  output$distances = renderDataTable({
    poly_layer = polyShapeInput()$x
    point_layer = pointShapeInput()$x

    if (is.null(input$polygon_shape) &
        input$submit == 0)
      return(NULL)

    calc_fetch.df = as(calc_fetch()$my_fetch_latlon, "data.frame")
    class(calc_fetch.df$direction) = "integer"
    calc_fetch.df
  })

  output$dl_file = downloadHandler(
    filename = function(){
      paste0(strsplit(input$file_name, ".", fixed = TRUE)[[1]][1],
             switch(input$format,
                    CSV = ".csv",
                    KML = ".kml",
                    R = ".zip"
             ))
    },
    content = function(file){
      switch(input$format,
             CSV = write.csv(as(calc_fetch()$my_fetch_latlon, "data.frame"), file, row.names = FALSE),
             KML = kml(calc_fetch()$my_fetch_latlon, file.name = file),
             R = create_zip(
               polyShapeInput()$x,
               pointShapeInput()$x,
               head(strsplit(input$polygon_shape$name, ".", fixed = TRUE)[[1]], -1),
               head(strsplit(input$point_shape$name, ".", fixed = TRUE)[[1]], -1),
               polyShapeInput()$dir_name,
               pointShapeInput()$dir_name,
               input$dist, input$n_dirs, file))
    }
  )
})
