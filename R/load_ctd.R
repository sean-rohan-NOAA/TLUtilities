#' Load CTD data from .rds files
#' 
#' @param loc File path for rds file. Columns should include: station, temperature, totdepth, bindepth, salinity, dyn_ht_anom, latitude, longitude, date_ind, year
#' 
#' 
load_ctd <- function(loc = paste0(seantools::root.dir(), "Thesis/Chapter 1/data/CTD/output/2019-04-11_ebs_shelf_ctd_2008_2018.rds")) {
  dat <- readRDS(loc)
  dat$cruise <- as.numeric(paste0(dat$year, "01"))
  names(dat)[which(names(dat)== "station")] <- "stationid"
  dat <- merge(dat, aggregate(date_ind ~ stationid + cruise, data = dat, FUN = min))
  dat <- subset(dat, stationid %in% TLUtilities::survey_stations(region = "shelf"))
  return(dat)
}
