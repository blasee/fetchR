<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Build Status](https://travis-ci.org/blasee/fetchR.svg)](https://travis-ci.org/blasee/fetchR)

Why *fetchR*?
=============

Wind fetch is an important measurement in coastal applications. It provides a measurement for the unobstructed length of water over which wind from a certain direction can blow over. The higher the wind fetch from a certain direction, the more energy is imparted onto the surface of the water resulting in a larger sea state. Therefore, the larger the fetch, the larger the exposure to wind and the more likely the site experiences larger sea states.

Averaging the wind fetch for numerous directions at the same location is therefore a reasonable measure of the overall wind exposure. This process of calculating wind fetch can be extremely time-consuming and tedious, particularly if a large number of fetch vectors are required at many locations. The *fetchR* **R** package calculates wind fetch for any marine location on Earth. There are also plot methods to help visualise the wind exposure at the various locations, and methods to output the fetch vectors to a KML file for further investigation.

Install *fetchR*
================

``` r
if (!require(devtools))
  install.packages("devtools")

devtools::install_github("blasee/fetchR")
```

How *fetchR* Works
==================

The *fetchR* package calculates wind fetch using the single `fetch` function. The `fetch` function requires two things:

1.  Polygons representing the coastline, surrounding islands and any other obstructions to wind, such as exposed reefs.

2.  Points representing the location(s) at which the wind fetch is to be calculated.

The coastline (and other obstructions') polygons, and the points representing the locations must have an associated coordinate reference system (CRS). In **R** these are represented by spatial objects from the class `"SpatialPolygons"` and `"SpatialPoints"` respectively.

##### Coastline Polygons

There are two feasible ways to get coastline polygons into **R**:

1.  Create a `SpatialPolygons` object manually using the information contained within the `maps` and `mapdata` **R** packages.

2.  Read in an ESRI shapefile.

Calculating Wind Fetch Anywhere in New Zealand --- A Reproducible Example
=========================================================================

This example shows the steps on how to download a high-resolution shapefile of New Zealand, prepare the data in **R** and how to calculate fetch at any marine site around New Zealand.

#### Download the New Zealand Coastlines and Islands MultiPolygon Shapefile

Download the [high-resolution shapefile of New Zealand's coastline and surrounding islands](https://data.linz.govt.nz/layer/1153-nz-coastlines-and-islands-polygons-topo-150k/) as a GIS shapefile with the WGS84 (EPSG:4326 Lat/Long) map projection.

###### Note

This requires a (free) [registration to the LINZ data service](https://data.linz.govt.nz/accounts/register/) and acceptance of the [terms and conditions](https://data.linz.govt.nz/terms-of-use/) and [privacy policy](https://data.linz.govt.nz/privacy-policy/).

#### Unzip the MultiPolygon Shapefile

The downloaded file is an 8.6MB ZIP file that needs to be extracted. For this example a `nz_poly_latlon` directory is created in our current working directory to house the contents of the downloaded zip file. The unzipping can be done manually or within R, as shown below.

``` r
# Assuming the ZIP was downloaded to a 'Downloads' folder in the user's home 
# directory
nz_zip = file.path("~", "Downloads",
                   "lds-nz-coastlines-and-islands-polygons-topo-150k-SHP.zip")

if (!file.exists(dl_folder)){
  stop("can't find file: ", nz_zip)
} else{
  dir.create("./nz_poly")
  unzip(nz_zip, exdir = "./nz_poly")
}
```

#### Create the Polygons in **R**

Read in the shapefile to create a `SpatialPolygons` object in **R**.

``` r
nz_poly_latlon = rgdal::readOGR("./nz_poly")
#> OGR data source with driver: ESRI Shapefile 
#> Source: "./nz_poly", layer: "nz-coastlines-and-islands-polygons-topo-150k"
#> with 9207 features
#> It has 7 fields
```

#### Create the Location(s) in **R**

Create a `data.frame` containing the information on the location(s) at which the wind fetch is to be calculated, and then create a `SpatialPoints` object.

``` r
fetch.df = data.frame(
  lon = c(174.8, 174.2, 168.2),
  lat = c(-36.4, -40.9, -46.7),
  name = c("Kawau Bay", "Chetwode Islands", "Foveaux Strait"))

fetch_locs = sp::SpatialPoints(fetch.df[, 1:2], 
                               sp::CRS(sp::proj4string(nz_poly_latlon)))
```

#### Choose the Map Projection

These locations are all within the WGS84 bounds of the [NZGD2000 / New Zealand Transverse Mercator 2000 projection](http://spatialreference.org/ref/epsg/nzgd2000-new-zealand-transverse-mercator-2000/) that covers the mainland of New Zealand. This suggests that this is a reasonable map projection for calculating fetch at these three locations.

Transform the map projection of the polygons in **R** to the NZTM 2000 map projection.

``` r
nz_proj_latlon = sp::spTransform(nz_poly_latlon,
                                 sp::CRS("+init=epsg:2193"))
```

###### Note

The original shapefile could have been downloaded in the NZTM 2000 coordinate reference system and this step would then be unnecessary.

Calculate Wind Fetch with *fetchR*
==================================

``` r
# Load the fetchR R package
library(fetchR)

# Calculate fetch using 9 fetch vectors per 90 degrees (one per 10 degrees on
# the compass rose), with a maximum distance of 300km.
my_fetch_proj = fetch(
  polygon_layer = nz_proj_latlon, ## SpatialPolygons object
  site_layer = fetch_locs,        ## SpatialPoints object
  site_names = fetch.df$name,     ## Site names
  max_dist = 300,                 ## Maximum fetch distance
  n_directions = 9,               ## No. fetch vectors per 90°
  quiet = FALSE)                  ## Suppress messages?
#> projecting site_layer onto the polygon_layer CRS
#> checking site locations are not on land
#> calculating fetch for Kawau Bay (1 out of 3)
#> calculating fetch for Chetwode Islands (2 out of 3)
#> calculating fetch for Foveaux Strait (3 out of 3)

my_fetch_proj
#> Is projected : TRUE
#> Max distance : 300 km
#> Directions   : 36
#> Sites        : 3
#> 
#>                  North East South West Average
#> Kawau Bay          2.3  8.6   6.7  4.8     5.6
#> Chetwode Islands 158.9 75.4  12.1 17.1    65.9
#> Foveaux Strait    27.6 89.5 112.4 96.8    81.6
```

The `my_fetch` object contains all the information on the lengths of each fetch vector at each site. The coordinates can be transformed back to the original latitude/longitude coordinates and the `as` method is provided to get a data frame containing all the raw data.

``` r
my_fetch_latlon = spTransform(my_fetch_proj, sp::CRS(proj4string(nz_poly_latlon)))
```

``` r
as(my_fetch_latlon, "data.frame")
```

    #>        site    fetch direction quadrant   lon   lat  lon_end   lat_end
    #> 1 Kawau Bay 2.134062         0    North 174.8 -36.4 174.7996 -36.38077
    #> 2 Kawau Bay 2.041550        10    North 174.8 -36.4 174.8035 -36.38182
    #> 3 Kawau Bay 2.493078        20    North 174.8 -36.4 174.8090 -36.37875
    #> 4 Kawau Bay 2.681698        30    North 174.8 -36.4 174.8145 -36.37885
    #> 5 Kawau Bay 3.379180        40    North 174.8 -36.4 174.8237 -36.37631
    #> 6 Kawau Bay 3.860117        50     East 174.8 -36.4 174.8324 -36.37714

...

    #>               site    fetch direction quadrant   lon   lat  lon_end
    #> 103 Foveaux Strait 89.15018       300     West 168.2 -46.7 167.2373
    #> 104 Foveaux Strait 85.47843       310     West 168.2 -46.7 167.3981
    #> 105 Foveaux Strait 43.09312       320    North 168.2 -46.7 167.8671
    #> 106 Foveaux Strait 36.51614       330    North 168.2 -46.7 167.9883
    #> 107 Foveaux Strait 41.24122       340    North 168.2 -46.7 168.0479
    #> 108 Foveaux Strait 38.52043       350    North 168.2 -46.7 168.1433
    #>       lat_end
    #> 103 -46.25417
    #> 104 -46.16885
    #> 105 -46.38837
    #> 106 -46.40624
    #> 107 -46.34467
    #> 108 -46.35614

Visualise the Fetch Vectors
===========================

There are two primary ways that *fetchR* allows you to visualise the fetch vectors that were used for calculating wind fetch:

1.  The default `plot` method in **R**

2.  Output a KML file for further investigation / collaboration

The following two sections show examples of how these can be achieved.

Plot Within **R**
-----------------

The `Fetch` object can be supplied to the `plot` method in **R**, along with the coastline polygons (`SpatialPolygons`) object to visualise the fetch vectors.

``` r
plot(my_fetch_latlon, nz_poly_latlon, col = "red", axes = TRUE)
```

![](figures/README-all_fetch_plot-1.png)

![](figures/README-fetch_plots-1.png)![](figures/README-fetch_plots-2.png)![](figures/README-fetch_plots-3.png)

Output to a KML
---------------

``` r
kml(my_fetch, colour = "white")
```

![Output to KML](/figures/kml.png)
