#' Find and apply time offset to Mk9 light data
#'
#' @param light Data frame containing Mk9 data. Must include columns: ldate_time (POSIXct), ldepth (numeric)
#' @param mbt Data frame containing MBT data. Must include columns: date_time (POSIXct), depth (numeric)
#' @param try.offsets A vector of offsets to try. Default is seq(-8,8,0.5)
#' @param results.file Character vector specifying the filepath where information about the offset and correlation between Mk9 and MBT depths are stored.
#'
#' @return The input light data frame with date_time adjusted according to the offset.
#'
#' @author Sean Rohan \email{sean.rohan@@noaa.gov}
#'

find_mk9_offset <- function(light, mbt, try.offsets = seq(-8,8,0.5), results.file = NULL) {

  if(!(("ldate_time" %in% names(light)) & ("ldepth" %in% names(light)))) {
    stop("find_mk9_offset: Columns named ldate_time and/or ldepth are missing from the light argument.")
  }

  if(!(("date_time" %in% names(mbt)) & ("depth" %in% names(mbt)))) {
    stop("find_mk9_offset: Columns named date_time and/or depth are missing from the mbt argument.")
  }
  # Initilize vector to store correlations from different offsets
  try.cor <- vector(length = length(try.offsets))

  # Loop through offsets
  for(i in 1:length(try.offsets)) {
    # Create offset to try
    light$ldate_time_offset <- light$ldate_time + try.offsets[i]*3600
    offset.df <- dplyr::inner_join(light, mbt, by = c("ldate_time_offset" = "date_time"))
    try.cor[i] <- cor(offset.df$ldepth, offset.df$depth)
  }

  print(paste0("Offset for Mk9 is " , try.offsets[which.max(try.cor)], " hrs, with correlation between Mk9 and MBT depth of ", try.cor[which.max(try.cor)], "."))

  # Remove try column
  light <- light[,-which(colnames(light) == "ldate_time_offset")]

  # Transform based on the best offset
  light$ldate_time <- light$ldate_time + try.offsets[which.max(try.cor)]*3600

  # Write offset and correlation to .txt file
  if(!is.null(results.file)) {
    fconn <- file(results.file)
    writeLines(c(as.character(Sys.Date()),
                 paste0("Offset: " , try.offsets[which.max(try.cor)], " hrs"),
                 paste0("Corr: ", try.cor[which.max(try.cor)])),fconn)
    close(fconn)
  }

  return(light)

}

