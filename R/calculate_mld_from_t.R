#' Calculate mixed layer depth from temperature using a threshold
#' 
#' Based on the temperature recorded at a specified reference depth, calculates the mixed layer depth using only temperature.
#' 
#' @param temperature Numeric vector of temperatures
#' @param z Numeric vector of depths for each of the temperatures
#' @param reference_depth Numeric vector of reference depth, can either be a single depth or multiple depths.
#' @param min_temperature_diff Minimum temperature difference. If the difference in temperatures between the reference depths and other depths is below this threshold. If the difference is below this threshold, the function returns the maximum depth (i.e. column is considered fully mixed).
#' @param temp_threshold Threshold temperature difference 
#' @param assign_inversion Substitutes maximum depth when temperature deep in the water column is higher than reference. Rare occurrence that may be an artifact of the survey sampling scheme.

calculate_mld_from_t <- function(temperature,
                                 z,
                                 reference_depth = 5,
                                 min_temperature_diff = 0.5,
                                 temp_threshold = 0.25,
                                 assign_inversion) {
  
  if(diff(range(temperature[z >= max(reference_depth)])) < min_temperature_diff) {
    mld <- max(z)
  } else {
    ref_index <- which(z %in% reference_depth)
    ref_temperature <- mean(temperature[ref_index])
    z_below_mld <- min(z[ref_temperature - temperature > temp_threshold & z > max(reference_depth)])
    z_above_mld <- max(z[z < min(z_below_mld) & z >= max(reference_depth)])
    mld <- (z_below_mld + z_above_mld)/2
    
    # Corner case when temperature near bottom is higher than surface layer, but not stratified.
    if(is.infinite(z_below_mld)) {
      mld <- max(z)
    }
    
  }
  
  return(mld)
  
}