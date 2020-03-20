#' Calculate temperature, salinity, and density for each layer
#' 
#' @param t temperature vector
#' @param s Salinity vector
#' @param rho Density vector
#' @param z Depth vector
#' @param mld Mixed layer depth 


calculate_tsrho_by_layer <- function(t, s, rho, z, mld) {
  if(mld >= max(z)){
    t_above <- mean(t, na.rm = TRUE)
    t_below <- NA
    s_above <- mean(s, na.rm = TRUE)
    s_below <- NA
    rho_above <- mean(rho, na.rm = TRUE)
    rho_below <- NA
  } else {
    t_above <- mean(t[z < mld], na.rm = TRUE)
    t_below <- mean(t[z > mld], na.rm = TRUE)
    s_above <- mean(s[z < mld], na.rm = TRUE)
    s_below <- mean(s[z > mld], na.rm = TRUE)
    rho_above <- mean(rho[z < mld], na.rm = TRUE)
    rho_below  <- mean(rho[z > mld], na.rm = TRUE)
  }

  return(list(t_above = t_above, 
              t_below = t_below, 
              s_above = s_above, 
              s_below = s_below,
              rho_above = rho_above, 
              rho_below = rho_below))
}
