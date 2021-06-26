#' Calculate bottom layer depth from temperature using a threshold
#' 
#' Based on the temperature recorded at a specified difference from the maximum depth for a profile.
#' 
#' @param temperature Numeric vector of temperatures
#' @param z Numeric vector of depths for each of the temperatures
#' @param ref_distance_from_max Numeric vector of distances from the maximum depth to use for the reference temperature.
#' @param min_temperature_diff Minimum temperature difference. If the difference in temperatures between the reference depths and shallow depths. If the difference is below this threshold, the function returns the minimum depth (i.e. column is considered fully mixed).
#' @param temp_threshold Threshold temperature difference.

calculate_bld_from_t <- function(temperature,
                                 z,
                                 ref_dist_from_max = 4,
                                 min_temperature_diff = 0.5,
                                 temp_threshold = 0.25) {
  
  bld <- NA
  z_above_bld <- NA
  
  if(diff(range(temperature[z < max(z)-ref_dist_from_max])) < min_temperature_diff) {
    bld <- min(z)
  } else {
    ref_temperature <- temperature[z %in% (max(z)-ref_dist_from_max)]
    z_above_bld <- max(z[temperature - ref_temperature > temp_threshold & z < max(z)-ref_dist_from_max])
    if(z_above_bld == min(z)) {
      z_below_bld <- min(z)
    } else{
      z_below_bld <- max(z[z < z_above_bld])
    }
    bld <- (z_below_bld + z_above_bld)/2    
  }
  
  # Corner case when temperature near bottom is higher than surface layer, but not stratified.
  if(is.infinite(z_above_bld)) {
    bld <- min(z)
  }
  
  # Case where bottom layer is right at the bottom
  if(is.infinite(bld)) {
    if(((rank(z)[z == min((max(z)-ref_dist_from_max))] - rank(z)[z == z_above_bld]) == 1)) {
      alt_index <- rank(z)[z == min((max(z)-ref_dist_from_max))]
      bld <- (z[rank(z) == alt_index] + z[rank(z) == (alt_index+1)])/2
    }
  }
  
  return(bld)
  
}