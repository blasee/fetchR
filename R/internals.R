# Internal functions ------------------------------------------------------

# Create a list of Line objects
#
# This function takes a single location along with the end points for each 
# direction and returns a list of Line objects for further processing.
# 
# @param d \code{SpatialPoints} object indicating the site location
# @param end_points the end points for each direction of interest
#
#' @importFrom sp Line

create_line_list = function(d, end_points){
  # 1) Create the matrix of all the lons and lats
  all_mat = rbind(do.call("rbind", rep(list(d@coords), nrow(end_points)))[, 1:2], 
                  end_points)
  
  # 2) Split this matrix into a list
  all_list = split(all_mat, 1:nrow(end_points))
  
  # 3) Create a list of 2x2 matrices indicating the start and end lons and lats
  all_list_mat = lapply(all_list, matrix, ncol = 2)
  
  # 4) Create a list of Line objects
  lapply(all_list_mat, Line)
}

# Create SpatialLines objects
#
# This function takes a single location along with the end points for each 
# direction and returns a SpatialLines object.
# 
# @param d the location of interest
# @param end_points the end points for each direction of interest
# @param directions the directions to be used for the SpatialLines ID's
#
#' @importFrom sp CRS proj4string SpatialLines Lines Line

create_sp_lines = function(line_list, directions, polygon){
  
  ## Create a list of Lines objects with ID's for each direction
  lines_list = vector("list", length(line_list))
  for (i in seq_along(line_list)){
    lines_list[[i]] = Lines(list(line_list[[i]]), ID = directions[i])
  }
  
  names(lines_list) = directions
  
  ## Create a SpatialLines object to calculate intersections
  SpatialLines(lines_list, 
               proj4string = CRS(proj4string(polygon)))
}