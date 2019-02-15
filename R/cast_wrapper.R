#' Applies a function to all casts in a data frame
#'
#'

cast_wrapper <- function(x, id.col, FUN, min.rows = 4, ...) {

  # Create a unique ID column over which to loop
  x$id.col <- eval(parse(text = paste0("paste(", paste(paste0("x$", id.col), collapse = ","),")")))
  unique_ids <- unique(x$id.col)
  output.df <- NULL
  rowind <- 0

for(i in 1:length(unique_ids)) {

  # Apply function to cast
  EEE <- subset(x, id.col == unique_ids[i])
  if(nrow(EEE) > min.rows) {
  EEE.out <- do.call(FUN, args = list(x = EEE, ...))

  if(is.null(output.df)) {
    output.df <- EEE.out
    rowind <- nrow(output.df)+1
    output.df[rowind:(nrow(output.df)+(nrow(x)*1.2)),] <- NA
  } else {
    output.df[rowind:(rowind + nrow(EEE.out)-1),] <- EEE.out[1:nrow(EEE.out),]
    rowind <- rowind + nrow(EEE.out)
    #output.df <- plyr::rbind.fill(output.df, EEE.out)
  }

  if(i %% 1000 == 0) {
    print(i)
  }
  }
}
  output.df <- output.df[,-which(names(output.df) == "id.col")]
  output.df <- output.df[-c(rowind:nrow(output.df)),]
  return(output.df)
}
