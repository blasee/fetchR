vectordestination <-
function(lonlatpoint, travelvector) {
Rearth <- 6372795
Dd <- travelvector$magnitude / Rearth
Cc <- travelvector$direction

if (class(lonlatpoint) == "SpatialPoints") {
lata <- coordinates(lonlatpoint)[1,2] * (pi/180)
lona <- coordinates(lonlatpoint)[1,1] * (pi/180)
}
else {
lata <- lonlatpoint[2] * (pi/180)
lona <- lonlatpoint[1] * (pi/180)
}
latb <- asin(cos(Cc) * cos(lata) * sin(Dd) + sin(lata) 
* cos(Dd))
dlon <- atan2(cos(Dd) - sin(lata) * sin(latb), sin(Cc) 
* sin(Dd) * cos(lata))
lonb <- lona - dlon + pi/2

lonb[lonb >  pi] <- lonb[lonb >  pi] - 2 * pi
lonb[lonb < -pi] <- lonb[lonb < -pi] + 2 * pi

latb <- latb * (180 / pi)
lonb <- lonb * (180 / pi)

data.frame(longitude = lonb, latitude = latb)
}
