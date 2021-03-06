#' Find surface light measurements during casts
#'
#' Uses cast start and end times to find concurrent measurements obtained by the deck-mounted archival tag, including a buffer. The buffer is added around the start and end times, so a 30 second buffer = one minute.
#'
#' @param light.data Light measurements from the surface/deck archival tag.
#' @param cast.data Haul event times indicating the start and end times for net deployment and retrival.
#' @param time.buffer Time buffer before and after the start of the cast.
#' @param agg.fun Function applied to calculate central tendency metric for light measurements sampled during the cast time window. Default trawllight::geometric.mean
#' @param ...


surface_light <- function(light.data, cast.data, time.buffer = 30, agg.fun = trawllight::geometric.mean, ...) {

  # Select and rename light and time columns
  if(ncol(light.data) >= 6) {
  light.data <- light.data[,5:6]
  colnames(light.data) <- c("surf_llight", "ctime")
  light.data$surf_trans_llight <- convert_light(light.data$surf_llight, ...)
  light.data$vessel <- rep(cast.data$vessel[1], nrow(light.data))
  light.data$cruise <- rep(cast.data$cruise[1], nrow(light.data))

  for(i in 1:nrow(cast.data)) {
    # Assign upcast or downcast to tag time
    light.data$updown[light.data$ctime > (cast.data$downcast_start[i] - time.buffer) &
                        light.data$ctime < (cast.data$downcast_start[i] + time.buffer)] <- "Downcast"
    light.data$updown[light.data$ctime > (cast.data$upcast_start[i] - time.buffer) &
                        light.data$ctime < (cast.data$upcast_end[i] + time.buffer)] <- "Upcast"
    light.data$haul[light.data$ctime > (cast.data$downcast_start[i] - time.buffer) &
                      light.data$ctime < (cast.data$upcast_end[i] + time.buffer)] <- cast.data$haul[i]
  }

  # Remove measurements outside of time window
  light.data <- subset(light.data, !is.na(updown))
  llight <- aggregate(surf_trans_llight ~ haul + updown + vessel + cruise, data = light.data, FUN = agg.fun)
  ctime <- aggregate(ctime ~ haul + updown + vessel + cruise, data = light.data, FUN = mean)
  ctime$ctime <- lubridate::with_tz(ctime$ctime, "America/Anchorage")
  light.data <- merge(llight, ctime)

  return(light.data)
  } else {
    warning(paste("surface_light: Deck light measurements not found for" , cast.data$vessel[1], "-", cast.data$cruise[1]))
    return(NULL)
  }
}
