#' Calculate density difference
#' 
#' Import and manipulate CTD data to only get cast data from good quality bottom-trawl survey hauls, then calculate density difference between Z <=5 m and z = 50
#' 
#' @param ctd.dat File path to CTD data. 
#' @param lower.depth Lower depth for calculating density difference. Default = 50 m
#' @param upper.depth Upper depth for calculating density difference. Default = 5 m averages density in the upper 5 m.

calculate_density_diff <- function(lower.depth = 50, 
                                   upper.depth = 5,
                                   ctd.dat = paste0(seantools::root.dir(), "Thesis/Chapter 1/data/CTD/output/2019-04-11_ebs_shelf_ctd_2008_2018.rds")) {
  print("Preparing CTD data")
  # Import and process CTD data
  dens.dat <- readRDS()
  names(dens.dat)[1] <- "stationid"
  dens.dat$stationid <- as.character(dens.dat$stationid)
  dens.dat <- subset(dens.dat, stationid %in% TLUtilities::survey_stations(region = "shelf"))
  dens.dat.unique <- unique(dplyr::select(dens.dat, stationid, year, date_ind))
  delta_sigma_t <- rep(NA, nrow(dens.dat.unique))
  
  for(i in 1:nrow(dens.dat.unique)) {
    sub1 <- subset(dens.dat, year == dens.dat.unique$year[i] & 
                     stationid == dens.dat.unique$stationid[i] & 
                     date_ind == dens.dat.unique$date_ind[i])
    dens.deep <- sub1$sigma_t[sub1$bindepth == lower.depth] # Density at 50 m as the lower depth
    dens.shal <- mean(sub1$sigma_t[sub1$bindepth <= upper.depth]) # Density at 5 m as the upper depth
    
    if(length(dens.deep) < 1) {
      dens.deep <- sub1$sigma_t[sub1$bindepth == max(sub1$bindepth)] 
    }
    delta_sigma_t[i] <- dens.deep - dens.shal
    
  }
  
  dens.out <- cbind(dens.dat.unique, delta_sigma_t)
  
  # Make sure that only good hauls are selected (basically, screen for HAUL_PERFORANCE < 0). Bad hauls happen before good hauls.
  dens.out <- merge(dens.out, plyr::ddply(dens.out, .(stationid, year), summarise, good_haul_time = max(date_ind)))
  dens.out <- subset(dens.out, date_ind == good_haul_time)
  
  return(dens.out)
}