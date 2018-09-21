#' MCorrect tag time
#'
#' Make adjustments to correct inconsistencies between tag time and survey time.

time_adjustments <- function(light.data, cast.data) {
  # Add vessel/cruise combination corrections for processing.
  # Offsets for tags set to the wrong time zone
  if(cast.data$cruise[1] == 201601) {
    print("Correcting 2016")
    light.data$ctime <- light.data$ctime + 3600
  } else if(cast.data$vessel[1] == 162 & cast.data$cruise[1] == 201101) {
    print("Correcting 162-201101")
    light.data$ctime <- light.data$ctime + (3600*8)
  }
  return(light.data)
}
