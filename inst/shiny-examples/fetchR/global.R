create_zip = function(poly_layer, point_layer, 
                      poly_layer_name, point_layer_name,
                      poly_dir_name, point_dir_name,
                      max_dist, directions, fn){
  
  setwd(dirname(fn))
  dir.create("Calculate_wind_fetch", showWarnings = FALSE)
  
  # Create a README in the parent directory
  readme_file(point_layer, poly_layer_name)
  
  # Create the custom R file in R/
  dir.create(file.path("Calculate_wind_fetch", "R"), showWarnings = FALSE)
  fetch_r_file(poly_layer_name, point_layer_name, max_dist, directions, fn)
  
  # Create the CSV, KML and Figures directories
  dir.create(file.path("Calculate_wind_fetch", "CSV"), showWarnings = FALSE)
  dir.create(file.path("Calculate_wind_fetch", "KML"), showWarnings = FALSE)
  dir.create(file.path("Calculate_wind_fetch", "Figures"), showWarnings = FALSE)
  
  # Delete the contents of the old directories (if they exist)
  if (file.exists(file.path("Calculate_wind_fetch", "Coastline"))){
    files = list.files(file.path("Calculate_wind_fetch", "Coastline"))
    file.remove(file.path("Calculate_wind_fetch", "Coastline", files))
  }
  
  if (file.exists(file.path("Calculate_wind_fetch", "Locations"))){
    files = list.files(file.path("Calculate_wind_fetch", "Locations"))
    file.remove(file.path("Calculate_wind_fetch", "Locations", files))
  }
  
  # Import the coastline and location shapefiles
  if (file.exists(poly_dir_name))
    file.rename(poly_dir_name, file.path("Calculate_wind_fetch", "Coastline"))
  
  if (file.exists(point_dir_name))
    file.rename(point_dir_name, file.path("Calculate_wind_fetch", "Locations"))
  
  # Zip the parent directory
  zip(fn, "./Calculate_wind_fetch")
}

fetch_r_file = function(poly_layer_name, point_layer_name, max_dist, directions, fn){
  
  cat('# This file was created by the fetchR_shiny web application:
# https://blasee.shinyapps.io/fetchR_shiny/.
# 
# If you encounter a problem when using this file, you can submit an issue here:
# https://github.com/blasee/fetchR/issues/new.
# 
# Ensure the working directory is set to the parent directory:
# setwd(file.path("PATH", "TO", "Calculate_wind_fetch"))

# Install and load packages -----------------------------------------------

# Install and load the latest CRAN release of fetchR
if(!require(fetchR)){
  install.packages("fetchR")
  library(fetchR)
}

# Read in the shapefiles --------------------------------------------------

# Read in the ', poly_layer_name, ' shapefile
my_coast = rgdal::readOGR("../Coastline", "', poly_layer_name, '")

# Read in the ', point_layer_name, 'shapefile
my_sites = rgdal::readOGR("../Locations", "', point_layer_name, '")

# Calculate Fetch ---------------------------------------------------------

# Polygon layer:       ', poly_layer_name, '
# Points layer:        ', point_layer_name, '
# Maximum distance:    ', max_dist, 'km
# Directions per 90°:  ', directions, '

my_fetch = fetch(my_coast, my_sites, ', max_dist, ', ', directions, ')

# Raw data ----------------------------------------------------------------

# Transform "my_fetch" to have lon/lat coordinates
my_fetch_latlon = spTransform(my_fetch, sp::CRS("+init=epsg:4326"))

# Create a data frame containing the raw data
my_fetch.df = as(my_fetch_latlon, "data.frame")

# Output raw data as a CSV
write.csv(my_fetch.df, "../CSV/raw_fetch.csv", row.names = FALSE)

# Output a summary of the exposure at each site as a CSV
write.csv(summary(my_fetch), "../CSV/fetch_summary.csv")

# Output PNG --------------------------------------------------------------

png("../Figures/fetch_plot.png", width = 720, height = 720)
plot(my_fetch, my_coast, asp = 1)
dev.off()

# Output to KML -----------------------------------------------------------

kml(my_fetch, folder.name = "Wind fetch", file.name = "../KML/wind_fetch.kml")

#  ------------------------------------------------------------------------

# To cite the fetchR package in publications
citation("fetchR")
',
sep = "", file = file.path("Calculate_wind_fetch", "R", "calculate_fetch.R"))
}

readme_file = function(point_layer, poly_layer_name){
  cat('
Calculate Wind Fetch in R with fetchR
=====================================

This file lists the software requirements and R packages required, and also
describes how to calculate wind fetch at the ', length(point_layer), 
' sites around ', poly_layer_name, '.

Software requirements
---------------------

* R (https://cran.r-project.org/bin/)

R packages
----------

* fetchR (>= 2.0-0) (https://cran.r-project.org/package=fetchR)

This will be automatically installed and loaded when the R file is run - see the
general usage section below.

General usage
-------------

Start an interactive R session and source the calculate_wind_fetch.R file:

  source(file.choose(), chdir = TRUE)

When prompted, navigate to the R/ folder within this parent directory and choose
the calculate_wind_fetch.R file. This will source the code into R and 
automatically calculate wind fetch for all the required sites.

Once the calculations have completed, the raw data, along with a summary of wind 
fetch for each site, will be output to separate CSV files within the CSV/ 
directory. A KML file will be written and exported to the KML/ directory, and a
figure will be output to the Figures/ directory.

EASY!

More information
----------------

 * fetchR R package README 
     https://github.com/blasee/fetchR#wind-fetch

 * fetchR vignette
     https://cran.r-project.org/web/packages/fetchR/vignettes/introduction-to-fetchR.html

 * fetchR web application README
     https://github.com/blasee/fetchR_shiny#calculate-wind-fetch-the-shiny-version

===================================

Submit any issues, bugs or suggestions at 
https://github.com/blasee/fetchR/issues/new.

Thank you for using fetchR to calculate wind fetch.', " Please don't forget to cite
this package in publications.

This file was automatically generated on ", 
      format(Sys.Date(), "%A, %B %d"), ' at ', format(Sys.time(), "%I:%M %p"), 
" by the
fetchR web application (https://blasee.shinyapps.io/fetchR_shiny/).",
sep = "", file = file.path("Calculate_wind_fetch", "README"))
}