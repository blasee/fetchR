# Calculate average fetch for any coastal area around New Zealand

[![Build Status](https://travis-ci.org/blasee/fetchR.svg)](https://travis-ci.org/blasee/fetchR)

This package was designed to provide an objective measurement of fetch for any
coastal location around New Zealand. Calculating fetch by hand is inaccurate,
time-consuming and unreliable. The `fetchR` package provides a single function
to calculate the average fetch, all that is required is the longitude and 
latitude of the location in decimal degrees.

# Installation in R

```R
install.packages("devtools")
library(devtools)
install_github(username = "blasee", repo = "fetchR")
```

# Calculate average fetch

To calculate the average fetch for the marine site at latitude = -36.4 and 
longitude = 174.8 (to the nearest 100m):

```R
library(fetchR)
fetch(174.8, -36.4)

# average fetch:           6.531 km
# median fetch:            3.05 km
# most exposed directions: 70

?fetchR
?fetch
```
A png of the map and vectors used in calculating the fetch is saved to the 
working directory. The `zoom` argument can be used to produce various figures.
Below are two examples of figures produced from the marine site stated above 
with default `zoom` and `zoom = 15`.

![default zoom][default_zoom]
![zoom 15][less_zoom]

[default_zoom]: figures/default_zoom.png
[less_zoom]: figures/less_zoom.png
