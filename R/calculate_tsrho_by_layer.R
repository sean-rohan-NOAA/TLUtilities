#' Calculate temperature, salinity, and density for each layer
#' 
#' @param t temperature vector
#' @param s Salinity vector
#' @param rho Density vector
#' @param z Depth vector
#' @param mld Mixed layer depth 


calculate_tsrho_by_layer <- function(t, s, rho, z, mld) {
  if(mld >= max(z)){
    t_above <- mean(t)
    t_below <- NA
    s_above <- mean(s)
    s_below <- NA
    rho_above <- mean(rho)
    rho_below <- NA
  } else {
    t_above <- mean(t[z < mld])
    t_below <- mean(t[z > mld])
    s_above <- mean(s[z < mld])
    s_below <- mean(s[z > mld])
    rho_above <- mean(rho[z < mld])
    rho_below  <- mean(rho[z > mld])
  }

  return(list(t_above = t_above, 
              t_below = t_below, 
              s_above = s_above, 
              s_below = s_below,
              rho_above = rho_above, 
              rho_below = rho_below))
}
