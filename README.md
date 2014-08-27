# Calculate average fetch for any coastal area around New Zealand

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

To calculate the average fetch for the marine site at latitude = -36.4, 
longitude = 174.8:

```R
library(fetchR)
fetch(174.8, -36.4)

# average fetch = 43.6 km

?fetchR
?fetch
```