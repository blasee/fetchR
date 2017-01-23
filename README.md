# Calculate average fetch for any coastal area around New Zealand

[![Build Status](https://travis-ci.org/blasee/fetchR.svg)](https://travis-ci.org/blasee/fetchR)

This package was designed to provide an objective measurement of fetch for any
coastal location around New Zealand. Calculating fetch by hand is inaccurate,
time-consuming and unreliable. The `fetchR` package provides a single function
to calculate the average fetch, all that is required is the latitude and 
longitude of the location in decimal degrees.

# Installation

The installation of `fetchR` requires the `rgeos` package successfully installed.

## From R

The following assumes you have an internet connection from R without any 
firewall/proxy/permission issues.

```r
install.packages("devtools")
library(devtools)
install_github("blasee/fetchR")
```

## Manual download (Windows)

There has been an [issue raised](../../issues/3) (thanks to Darren) about 
installing `fetchR` on a Windows platform, so here's an update if the above 
doesn't work. This does not require internet connectivity within R but requires
the `devtools` package to be installed (code above).

1. Download the .zip file to your computer straight from GitHub [located here](https://github.com/blasee/fetchR/archive/master.zip). Now you will be able to install the package within R.
2. in R: 
  + `devtools::install_local(file.path("PATH", "TO", "ZIP", "FILE", "fetchR-master.zip"))` 
  + or you can navigate to the file manually using pop-up menus:
  `devtools::install_local(file.choose())`
3. If these steps have been successful, fetchR will now be installed on your system and can now be used.

Further tips:

* Make sure you are using a [current version of R](https://cran.r-project.org/bin/windows/base/). 
  + You can check which version you are currently using by typing `R.Version()$version.string` into R.
* If you are using RStudio (recommended), make sure you are using a [current version](https://www.rstudio.com/products/rstudio/download/).
  + You can check your current version using the menus: Help --> About RStudio.
* You can keep packages up to date by typing `update.packages()` in R on a regular basis.

# Calculate average fetch

To calculate the average fetch for the marine site at latitude = -36.4 and 
longitude = 174.8 (to the nearest 100m):


```r
library(fetchR)
kawau_bay = fetch(-36.4, 174.8)
```

```
## Projecting location onto NZTM 2000 map projection
## checking coordinate is not on land
## calculating fetch
```

```r
# Contains the distances for each direction
head(kawau_bay)
```

```
   latitude longitude direction fetch
1 -36.39953  174.8306        90  2.74
2 -36.40347  174.8273       100  2.48
3 -36.40688  174.8248       110  2.35
4 -36.41251  174.8280       120  2.87
5 -36.41348  174.8206       130  2.38
6 -36.41755  174.8189       140  2.58
```

The summary function gives the location coordinates, average and median fetch
and summarises the average fetch length from the four compass quadrants.

```r
summary(kawau_bay)
```

```
Latitude:  -36.4
Longitude: 174.8
Average:   4.96km
Median:    2.86km

Average northerly fetch [315, 45):  2.5km
Average easterly fetch [45, 135):   6.1km
Average southerly fetch [135, 225): 6.7km
Average westerly fetch [225, 315):  4.8km

n_bearings = 9
```

# Plotting methods
Plotting the resulting vectors is easy with the default plot method.

```r
plot(kawau_bay)
```

![default fetch plot](./figures/fetch_plot.png)

## Output to KML
Many GIS applications involve KML files for collaboration, interaction and 
editing. The vectors in each direction can be exported to KML files using the 
`kml` function in the `plotKML` package.

```r
# Install and load plotKML library
if (!require(plotKML))
  install.packages("plotKML")
  
library(plotKML)

Create some labels indicating the fetch vector directions
labs = sapply(slot(kawau_bay, "lines"), slot, "ID")

# Save 'kawau_bay.kml' to the current directory
kml(kawau_bay, labels = labs)
```

![ggmap fetch](./figures/kml.png)

CC-By Land Information New Zealand. This product uses data sourced from Landcare Research under CC-BY, http://creativecommons.org/licenses/by/3.0/nz/