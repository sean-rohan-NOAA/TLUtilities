#' Calculate pycnocline depth as the maximum rate of increase in density at depths below the pycnocline and below the reference depth
#' 
#' Find the depth of the pycnocline as the depth where density is changing the fastest
#'
#' @param rho Numeric vector of density
#' @param z Numeric vector of depths
#' @mld Mixed layer depth
#' @ref.depth Reference depth for upper layer density

calculate_pycnocline <- function(rho, z, mld = NULL, ref.depth = 5) {
  
  # Don't calculate pycnocline if MLD goes to the bottom
  if(mld < max(z)) {
    rho <- rho[order(z)]
    z <- z[order(z)]
    
    # Filter by reference depth
    rho <- rho[z > ref.depth]
    z <- z[z > ref.depth]
    
    if(!is.null(mld)) {
      rho <- rho[z > mld]
      z <- z[z > mld]
    }
    
    delta.rho <- diff(rho)/diff(z)
    if(length(delta.rho) == 0) { 
      # Case where MLD is at the bottom
      return(NA)
    } else if(which.max(delta.rho) == 1) {
      # Case where pycnocline is at the shallowest depth
      return(z[which.max(delta.rho)]-0.5)
    } else {
      # All other cases
      return((z[which.max(delta.rho)-1] + z[which.max(delta.rho)])/2)
    }
  } else {
    # Fully-mixed water column
    return(NA)
  }
}