Calculate wind fetch using the shiny application
================================================

The [**fetchR**](https://cran.r-project.org/package=fetchR) package is designed to calculate fetch lengths at locations anywhere on Earth, using **R**. The shiny application of **fetchR** allows users to make these calculations *without* requiring **R** by using the [online web application](https://blasee.shinyapps.io/fetchR_shiny/).

How to use the **fetchR** web application
=========================================

The [**fetchR**](https://cran.r-project.org/package=fetchR) web application requires two shapefiles; one for the coastlines and other boundaries, and one for the locations at which to calculate wind fetch. The following example details the steps required for calculating fetch with a reproducible example using data from the [Land Information New Zealand (LINZ) Data Service](https://data.linz.govt.nz/)[1].

1) Upload a polygon shapefile to the application
------------------------------------------------

This shapefile must:

-   be a Polygons ESRI shapefile, and;
-   have a valid map projection

As an example, download the [high resolution New Zealand coastlines and islands polygons shapefile](https://data.linz.govt.nz/layer/1153-nz-coastlines-and-islands-polygons-topo-150k/) as a GIS shapefile with the NZGD2000 / New Zealand Transverse Mercator 2000 (EPSG:2193) map projection. Once the contents have been unzipped, the files can then be uploaded to the web application.

![](./figures/upload_poly.png)

2) Upload a points shapefile
----------------------------

This shapefile must:

-   be a Point (or MultiPoint) ESRI shapefile

Every point represents a location at which the wind fetch will be calculated. This shapefile can be created from any GIS software, or directly within **R**.

### Create an ESRI shapefile in **R**

As a example, create an ESRI Point shapefile in **R** for three locations around coastal New Zealand.

``` r
# This example requires the rgdal package to be loaded
if(!require(rgdal)){
  install.packages("rgdal")
  library(rgdal)
}

# Create a data frame with the latitudes, longitudes and names of the
# locations.
fetch.df = data.frame(
  lon = c(174.8, 174.2, 168.2),
  lat = c(-36.4, -40.9, -46.7),
  name = c("Kawau Bay", "Chetwode Islands", "Foveaux Strait"))

fetch.df

# Create a SpatialPoints object for the fetch locations
fetch_locs = SpatialPointsDataFrame(fetch.df[, 1:2], 
                                    fetch.df[, -(1:2), drop = FALSE],
                                    proj4string = CRS("+init=epsg:4326"))
```

It is important to include a 'name' or 'Name' column in the data frame that gives the names for each of the locations. If there is no such column in the data within the shapefile, then the web application will not return specific, meaningful names.

``` r
writeOGR(fetch_locs, "NZ_locations", "fetch_locations", "ESRI Shapefile")
```

These files can now be uploaded to the web application.

![](./figures/upload_point.png)

##### Note

While the polygon layer requires a map projection, this is not a requirement for the point layer. If the point layer is not projected, it is automatically transformed to have the same map projection as the polygon layer before any wind fetch calculations take place.

3) Set maximum distance and number of directions
------------------------------------------------

Set the required maximum distance (km) and number of equiangular directions to calculate per quadrant (i.e. per 90 degrees). The default is to calculate the wind fetch for 9 directions per 90 degrees, or; one fetch vector for every 10 degrees of angular separation.

Finally, calculate fetch! Navigate through the various tabs to see the fetch vectors, a summary of the wind exposure, and a table containing the raw data (in longitude / latitude coordinates). Once the calculations have completed, the shiny application allows the user to export the raw data as a CSV file, download a KML, or reproduce the results using a customized **R** project directory.

Citation
========

``` r
citation("fetchR")
```

    ## 
    ## To cite package 'fetchR' in publications use:
    ## 
    ##   Blake Seers (2017). fetchR: Calculate Wind Fetch in R. R package
    ##   version 2.0-2. https://cran.r-project.org/package=fetchR
    ## 
    ## A BibTeX entry for LaTeX users is
    ## 
    ##   @Manual{,
    ##     title = {fetchR: Calculate Wind Fetch in R},
    ##     author = {Blake Seers},
    ##     year = {2017},
    ##     note = {R package version 2.0-2},
    ##     url = {https://cran.r-project.org/package=fetchR},
    ##   }

[1] This requires a (free) [registration to the LINZ Data Service](https://data.linz.govt.nz/accounts/register/) and acceptance of the [terms of conditions](https://data.linz.govt.nz/terms-of-use/) and [privacy policy](https://data.linz.govt.nz/privacy-policy/). The data sourced from Land Information New Zealand has not been adapted and is protected under CC-By Land Information New Zealand.
