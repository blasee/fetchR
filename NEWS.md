# fetchR 2.0-1-999

## Minor changes

* The shiny web application has been incorporated into **fetchR**. To use the 
  application locally you can now type `runExample()` or check out the 
  [online version](https://blasee.shinyapps.io/fetchR_shiny/).

* Use `on.exit` to close the KML file connection in `kml,Fetch` method.

* Site names are automatically read from the data associated with the shapefile.
  The names have to be in a column with a name matching the regular expression;
  "^[Nn]ames{0,1}$".

# fetchR 2.0-0

## Major changes

* **fetchR** is now generalised to incorporate `SpatialPolyons` representing any
marine location on Earth (#6). As a result, **fetchR** 2.0 is no longer limited 
to calculating wind fetch within New Zealand coastal areas.

### Rewrite the entire algorithm for calculating wind fetch. 

* The `rgeos::gBuffer` function is used to calculate the end points of the fetch 
vectors at their maximum distance.

* The interactions between the fetch vectors and the coastlines, or any of the 
polygons, are calculated with the `rgeos::gIntersection` function as opposed to
the slow, iterative algorithm used by the package's predecessors.

* Computation times have dramatically decreased.

## Minor changes

 Create a vignette for the package; `vignette("introduction-to-fetchR")`.
