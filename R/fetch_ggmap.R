# Have arguments 
# zoom, 
# ... passed on to geom_segment (linetype and colour etc.)
# quiet
# 
# 
# 
# library(ggmap)
# 
# my_map = ggmap(get_map(c(my_fetch@location_long, my_fetch@location_lat), 
#                        maptype = "satellite", zoom = 9))
# 
# my_map + geom_segment(data = NULL, aes(x = my_fetch@location_long, 
#                                        xend = my_fetch$longitude,
#                                        y = my_fetch@location_lat,
#                                        yend = my_fetch$latitude),
#                       na.rm = TRUE, colour = "red")