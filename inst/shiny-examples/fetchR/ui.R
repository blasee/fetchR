shinyUI(fluidPage(
  useShinyjs(),

  titlePanel("Calculate Wind Fetch"),
  br(),

  sidebarLayout(

    sidebarPanel(

      helpText("1) Upload a polygon shapefile. Each polygon represents a coastline boundary, island or other obstruction to wind."),
      fileInput('polygon_shape', 'Upload polygon shapefile',
                accept=c(".shp",".dbf",".sbn",".sbx",".shx",".prj"),
                multiple = TRUE, width = "100%"),

      helpText("2) Upload a points shapefile. Each point represents the location(s) at which the wind fetch will be calculated."),
      fileInput('point_shape', 'Upload points shapefile',
                accept=c(".shp",".dbf",".sbn",".sbx",".shx",".prj"),
                multiple = TRUE, width = "100%"),

      helpText("3) Set the maximum distance for all fetch vectors."),
      numericInput("dist",
                   label = "Maximum distance (km)",
                   value = 300,
                   min = 10,
                   max = 500,
                   step = 50,
                   width = '300px'),

      helpText("4) Set the number of directions to calculate per 90°"),
      numericInput("n_dirs",
                   label = "Directions per quadrant",
                   value = 9,
                   min = 1,
                   max = 20,
                   step = 1,
                   width = '300px'),
      br(),

      helpText("5) Calculate wind fetch!"),
      actionButton("submit", "Calculate fetch"),

      conditionalPanel("input.submit > 0",
                       hr(),
                       helpText("Download the data in CSV or KML format for use in other software,
               or reproduce it using a custom R script."),
                       textInput("file_name", "Filename:", "my_fetch"),
                       radioButtons('format', 'File format', c('CSV', 'KML', 'R'),
                                    inline = TRUE),
                       hr(),
                       downloadButton("dl_file")),

      width = 3
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Home",
                 plotOutput("polygon_map"),
                 h4("How does this application work?"),
                 p("This web application calculates the wind fetch for any marine site around the world using the",
                   a("fetchR", href = "https://cran.r-project.org/package=fetchR"),
                   "R package. Simply upload your polygon shapefiles (representing the coastlines etc.), and your points shapefiles (indicating where fetch is to be calculated), and then calculate the fetch! See the", a("README", href = "https://github.com/blasee/fetchR_shiny"), "for more details and a reproducible example using this application."),

                 p("This", strong("Home"), "tab plots the extent of the polygon shapefile, and the locations at which the wind fetch are to be calculated, once the shapefiles have been uploaded successfully."),
                 p("The", strong("Plot"), "tab shows a plot of the vectors that were used in calculating the fetch for each direction, at each site."),
                 p("The", strong("Summary"), "tab gives a summary of the wind fetch for each location, including the average fetch for each quadrant. The more angles used per quadrant will lead to better estimates of fetch, although the computation time will increase."),
                 p("The", strong("Distances"), "tab contains the fetch length for each vector that has gone into the fetch calculations, along with the latitude and longitude coordinates."),
                 p(strong("Please"), "don't forget to", a("cite the 'fetchR' package", href = "https://github.com/blasee/fetchR_shiny#citation"), "in publications.")
                 ),
        tabPanel("Plot",
                 plotOutput("fetch_plot",
                            height = "800px")),
        tabPanel("Summary",
                 tableOutput("summary")),
        tabPanel("Distances",
                 dataTableOutput("distances"))
      )
    )
  )
))
