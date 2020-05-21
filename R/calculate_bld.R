#' Calculate bottom layer depth using a threshold method
#'
#' @param rho Numeric vector of densities
#' @param z Numeric vector of depths. Depths are positive.
#' @param ref.depth Thickness of bottom layer to use for calculating bottom layer density
#' @param totdepth Maximum depth sampled by the cast
#' @param threshold Density threshold

calculate_bld <- function(rho, z, totdepth, threshold = 0.1, ref.depth = 5) {
  rho <- rho[order(z)]
  z <- z[order(z)]
  z.max <- max(z)
  bottom.rho <- mean(rho[z >= (z.max - ref.depth)])
  bld.bin <- which(rho < (bottom.rho - threshold) & z < (z.max - ref.depth))
  
  if(length(bld.bin) > 0) {
    bld <- z[max(bld.bin)]
  } else {
    if(length(totdepth) > 0) {
      bld <- 0
    } else {
      bld <- NA
    }
  }
  return(bld)
}