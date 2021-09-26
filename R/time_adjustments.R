#' Correct tag time in cases where offsets were incorrect
#'
#' For use processing AOPs from AFSC/RACE/GAP data structure. Make adjustments to correct inconsistencies between tag time and survey time.
#' 
#' @param light.data Data frame with light data
#' @param cast.data Data frame containing case data.
#' @export

time_adjustments <- function(light.data, cast.data) {
  # Add vessel/cruise combination corrections for processing.
  # Offsets for tags set to the wrong time zone
  if(cast.data$cruise[1] == 201601) {
    print("Correcting 2016")
    light.data$ctime <- light.data$ctime + 3600 # Time off by 1 hour
  }

  if(cast.data$vessel[1] == 94 & cast.data$cruise[1] == 201501) {
    print("Correcting 94-201501")
    light.data$ctime <- light.data$ctime - 3600
  }

  if(cast.data$vessel[1] == 94 & cast.data$cruise[1] == 201401) {
    print("Correcting 94-201401")
    light.data$ctime <- light.data$ctime - 3600
  }

  if(cast.data$vessel[1] == 162 & cast.data$cruise[1] == 201101) {
    print("Correcting 162-201101")
    light.data$ctime <- light.data$ctime - (3600*8)
  }

  if(cast.data$vessel[1] == 134 & cast.data$cruise[1] == 200601) {
    print("Correcting 134-200601")
    light.data$ctime[lubridate::month(light.data$ctime) >=7 & lubridate::day(light.data$ctime) > 8] <- light.data$ctime[lubridate::month(light.data$ctime) >=7 & lubridate::day(light.data$ctime) > 8] - 3600*12 # Time off by 1 hour
  }

  return(light.data)
}
