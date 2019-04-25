# Raw light

raw_light <- function(dir.structure,
                      time.buffer = 20,
                      silent = T,
                      column = T,
                      adjust.time = T,
                      ...) {

  # Step 1. Input directory and CastTimes and corr_MK9_hauls files
  ind <- 1
  out <- rep(-1, 1e7)

  for(i in 1:length(dir.structure)) {
    if(column) {
      if(file.exists(paste(dir.structure[i], "/corr_MK9hauls.csv", sep = "")) &
         file.exists(paste(dir.structure[i], "/CastTimes.csv", sep = ""))) {

        corr_mk9hauls <- read.csv(paste(dir.structure[i], "/corr_MK9hauls.csv", sep = ""))
        casttimes <- read.csv(paste(dir.structure[i], "/CastTimes.csv", sep = ""))

        corr_mk9hauls$ctime <- as.POSIXct(strptime(corr_mk9hauls$ctime,
                                                   format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage"))
        casttimes$downcast_start <- as.POSIXct(strptime(casttimes$downcast_start,
                                                        format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage")) - time.buffer
        casttimes$downcast_end <- as.POSIXct(strptime(casttimes$downcast_end,
                                                      format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage")) + time.buffer
        casttimes$upcast_start <- as.POSIXct(strptime(casttimes$upcast_start,
                                                      format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage")) - time.buffer
        casttimes$upcast_end <- as.POSIXct(strptime(casttimes$upcast_end,
                                                    format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage")) + time.buffer

        for(j in 1:nrow(casttimes)) {
          if(!silent) {
            print(paste("Cruise: ", casttimes$cruise[j], ", Vessel: ", casttimes$vessel[j], ", Haul: ", casttimes$haul[j], sep = ""))
          }
          vert <- vertical_profiles(light.data = corr_mk9hauls,
                                    cast.data = subset(casttimes, haul == casttimes$haul[j]))


          if(nrow(vert) > 0) {
            out[ind:(ind+nrow(vert)-1)] <- vert$llight
            ind <- ind + nrow(vert)
          }
        }
      }
    } else {
      if(!file.exists(paste(dir.structure[i], "/CastTimes.csv", sep = ""))) {
        stop(paste("raw_light: CastTimes.csv not found in" , paste(dir.structure[i])))
      }

      # Import CastTImes
      print(paste("Processing", dir.structure[i]))
      casttimes <- read.csv(paste(dir.structure[i], "/CastTimes.csv", sep = ""))

      # Find names of deck files
      deck.files <- list.files(path = dir.structure[i], pattern = "^deck.*\\.csv", full.names = T)

      # Check for CastTimes
      if(length(deck.files) < 1) {
        warning(paste("raw_light: Deck light measurements not found in" , paste(dir.structure[i])))
      } else {

        #Import first deck file
        deck.data <- read.csv(file = deck.files[1], header = F)
        deck.data$ctime <- paste(deck.data[,1], deck.data[,2], sep = " ")

        # Import additional deck files if multiple exist in one directory
        if(length(deck.files) > 1) {
          for(b in 2:length(deck.files)) {
            deck.data <- rbind(deck.data, read.csv(file = deck.files[b], header = F))
          }
        }

        # Convert times into POSIXct
        deck.data$ctime <- as.POSIXct(strptime(deck.data$ctime, format = "%m/%d/%Y %H:%M:%S", tz = "America/Anchorage"))

        # Convert cast times to POSIXct format, add 30 second offset to each cast time to avoid truncating cast data
        casttimes$downcast_start <- as.POSIXct(strptime(casttimes$downcast_start,
                                                        format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage"))
        casttimes$downcast_end <- as.POSIXct(strptime(casttimes$downcast_end,
                                                      format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage"))
        casttimes$upcast_start <- as.POSIXct(strptime(casttimes$upcast_start,
                                                      format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage"))
        casttimes$upcast_end <- as.POSIXct(strptime(casttimes$upcast_end,
                                                    format = "%Y-%m-%d %H:%M:%S", tz = "America/Anchorage"))

        if(adjust.time) {
          # Correct cases where there is a mismatch between survey time and tag time
          deck.data <- time_adjustments(light.data = deck.data,
                                        cast.data = casttimes)
        }
        if(nrow(deck.data) > 0) {


          if(ncol(deck.data) >= 6) {
            deck.data <- deck.data[,5:6]
            colnames(deck.data) <- c("surf_llight", "ctime")
            deck.data$vessel <- rep(casttimes$vessel[1], nrow(deck.data))
            deck.data$cruise <- rep(casttimes$cruise[1], nrow(deck.data))

            for(j in 1:nrow(casttimes)) {
              # Assign upcast or downcast to tag time
              deck.data$updown[deck.data$ctime > (casttimes$downcast_start[j] - time.buffer) &
                                 deck.data$ctime < (casttimes$downcast_start[j] + time.buffer)] <- "Downcast"
              deck.data$updown[deck.data$ctime > (casttimes$upcast_start[j] - time.buffer) &
                                 deck.data$ctime < (casttimes$upcast_end[j] + time.buffer)] <- "Upcast"
              deck.data$haul[deck.data$ctime > (casttimes$downcast_start[j] - time.buffer) &
                               deck.data$ctime < (casttimes$upcast_end[j] + time.buffer)] <- casttimes$haul[j]
            }

            # Remove measurements outside of time window
            deck.data <- subset(deck.data, !is.na(updown))
            out[ind:(ind+nrow(deck.data)-1)] <- deck.data$surf_llight
            ind <- ind + nrow(deck.data)
          }
        }

      }

    }
  }
  return(out[out > 0])
}


