<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Build Status](https://travis-ci.org/blasee/fetchR.svg)](https://travis-ci.org/blasee/fetchR)

Wind fetch
==========

Wind fetch is an important measurement in coastal applications. It provides a measurement for the unobstructed length of water over which wind from a certain direction can blow over. The higher the wind fetch from a certain direction, the more energy is imparted onto the surface of the water resulting in a larger sea state. Therefore, the larger the fetch, the larger the exposure to wind and the more likely the site experiences larger sea states.

Why **fetchR**?
===============

Averaging the wind fetch for numerous directions at the same location is a reasonable measure of the overall wind exposure. This process of calculating wind fetch can be extremely time-consuming and tedious, particularly if a large number of fetch vectors are required at many locations. The **fetchR** package calculates wind fetch for any marine location on Earth. There are also plot methods to help visualise the wind exposure at the various locations, and methods to output the fetch vectors to a KML file for further investigation.

Installation
============

You can install the latest version of **fetchR** from GitHub.

``` r
if (!require(devtools))
  install.packages("devtools")

devtools::install_github("blasee/fetchR", build_vignettes = TRUE)

# Load the fetchR package
library(fetchR)
```

Calculating wind fetch with **fetchR**
======================================

If you already have a `SpatialPolygons` object representing the coastline and surrounding islands, and a `SpatialPoints` object representing the locations, then calculating wind fetch with **fetchR** is easy. You can just pass these two arguments into the `fetch` function.

``` r
# Calculate wind fetch by passing in the projected SpatialPolygons object (nz_poly_proj)
# and the projected SpatialPoints object (fetch_locs_proj) to the fetch function.
my_fetch_proj = fetch(nz_poly_proj, fetch_locs_proj)

my_fetch_proj
```

    #> Is projected : TRUE
    #> Max distance : 300 km
    #> Directions   : 36
    #> Sites        : 3
    #> 
    #>                  North East South West Average
    #> Kawau Bay          2.3  8.6   6.7  4.8     5.6
    #> Chetwode Islands 158.9 75.4  12.1 17.1    65.9
    #> Foveaux Strait    27.6 89.5 112.4 96.8    81.6

The `my_fetch_proj` provides a summary of the fetch for all the four quadrants, along with an overall average of the fetch length at all the sites.

Visualise the fetch vectors
===========================

``` r
# Plot the fetch vectors, along with the coastline and surrounding islands
plot(my_fetch_proj, nz_poly_proj)
```

![Fetch vectors at all the sites](./README_figures/all_fetch.png)

![Fetch vectors at Kawau Bay](./README_figures/kawau.png)

![Fetch vectors at the Chetwode Islands](./README_figures/chetwode.png)

![Fetch vectors at Foveaux Strait](./README_figures/foveaux.png)

Export to a KML file
====================

``` r
# Export the fetch vectors to a KML file for further investigation
kml(my_fetch_proj)
```

Note that the distances calculated in Google Earth are (almost) the same as the distances calculated with **fetchR**. This can be seen in the KML output as the fetch vector at 90 degrees for the Foveaux Strait site is 300km (the maximum distance by default) in both **fetchR** and Google Earth, although these algorithms differ.

![Output to KML](./README_figures/kml.png)

Get started with **fetchR**
===========================

Read the short introductory vignette to get you started with **fetchR**, and have a look at the simple, reproducible example in the `fetch` function.

``` r
# Read the short vignette
vignette("introduction-to-fetchR")

# Reproduce a simple example
example(fetch)
```
