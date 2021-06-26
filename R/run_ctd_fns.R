#' Wrapper function for calculating mld, density difference between upper and lower water column, and pycnocline depth
#' 
#' @dat Data frame containing dat, stationid, cruise, totdepth, latitude, and longitude columns

run_ctd_fns <- function(dat) {
  profiles <- unique(dplyr::select(dat, stationid, cruise, totdepth, latitude, longitude))
  profiles$mld <- -99
  profiles$bld <- -99 ##
  profiles$density.diff <- -99
  profiles$pycnocline <- -99
  profiles$t_above <- -99
  profiles$t_below <- -99
  profiles$s_above <- -99
  profiles$s_below <- -99
  profiles$rho_above <- -99
  profiles$rho_below <- -99
  profiles$t_average <- -99
  profiles$s_average <- -99
  
  for(i in 1:nrow(profiles)) {
    profile.sel <- subset(dat, cruise == profiles$cruise[i] & stationid == profiles$stationid[i])
    print(paste(profiles$cruise[i], profiles$stationid[i]))
    profile.sel <- profile.sel[order(profile.sel$bindepth),]
    profiles$mld[i] <- calculate_cokelet_mld(rho = profile.sel$sigma_t, 
                                z = profile.sel$bindepth, 
                                totdepth = max(profile.sel$bindepth), 
                                ref.depth = 5)
    profiles$bld[i] <- calculate_bld(rho = profile.sel$sigma_t, 
                                     z = profile.sel$bindepth, 
                                     totdepth = max(profile.sel$bindepth))
    profiles$density.diff[i] <- calculate_cokelet_density_diff(mld = profiles$mld[i],
                                                      rho = profile.sel$sigma_t, 
                                                      z = profile.sel$bindepth)
    profiles$pycnocline[i] <- calculate_pycnocline(rho = profile.sel$sigma_t, 
                                             z = profile.sel$bindepth,
                                             mld = profiles$mld[i])

    tsrho.layers <- calculate_tsrho_by_layer(t = profile.sel$temperature,
                             s = profile.sel$salinity,
                             rho = profile.sel$sigma_t,
                             z = profile.sel$bindepth,
                             mld = profiles$mld[i])
    
    profiles$t_above[i] <- tsrho.layers$t_above
    profiles$t_below[i] <- tsrho.layers$t_below
    profiles$s_above[i] <- tsrho.layers$s_above
    profiles$s_below[i] <- tsrho.layers$s_below
    profiles$rho_above[i] <- tsrho.layers$rho_above
    profiles$rho_below[i] <- tsrho.layers$rho_below
    profiles$t_average[i] <- tsrho.layers$t_average
    profiles$s_average[i] <- tsrho.layers$s_average
    
  }
  return(profiles)
}
