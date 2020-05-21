#' Calculate density difference between reference depth and 30 m below mixed-layer depth (or bottom)
#' 
#' @param rho Density vector
#' @param z Depth vector (positive depths)
#' @param mld Vector of mixed layer depth
#' @param ref.depth Reference depth for calculating mixed layer density.
#' @param mld.buffer Depth difference between upper and lower

# Calculate density difference between the reference depth (5 m) and MLD + buffer (30 m below mld), following Cokelet (2016)
calculate_cokelet_density_diff <- function(rho, z, mld, ref.depth = 5, mld.buffer = 30) {
  rho.upper <- NA
  rho.lower <- NA
  if(min(abs(z-ref.depth)) < 3){
    rho.upper <- mean(rho[z <= ref.depth])
  }
  lower.ref <- mld + 30
  if(lower.ref < max(z)) {
    rho.lower <- mean(rho[z > lower.ref])
  } else {
    rho.lower <- rho[z == max(z)]
  }
  diff.rho <- rho.lower - rho.upper
  return(diff.rho)
}
