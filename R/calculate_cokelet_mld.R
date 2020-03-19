#' Calculate mixed layer depth using a threshold method
#' 
#' Following Danielsson et al. 2011 and Cokelet 2016.
#'
#' @param rho Numeric vector of densities
#' @param z Numeric vector of depths. Depths are positive.
#' @param ref.depths Depths to use for calculating upper water column density
#' @param totdepth Maximum depth sampled by the cast
#' @param threshold Density threshold for changes.

calculate_cokelet_mld <- function(rho, z, ref.depths, totdepth, threshold = 0.1) {
  rho <- rho[order(z)]
  z <- z[order(z)]
  surf.rho <- mean(rho[z >= ref.depths[1] & z <= ref.depths[length(ref.depths)]])
  mld.bin <- which(rho > (surf.rho + threshold))
  if(length(mld.bin) > 0) {
    mld <- z[mld.bin[1]]
  } else {
    if(length(totdepth) > 0) {
      mld <- totdepth[1]
    } else {
      mld <- NA
    }
  }
  return(mld)
}