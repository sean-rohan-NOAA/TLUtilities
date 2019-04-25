csv_rbind <- function(directory, string) {
  file.list <- grep(pattern = string, x = dir(directory))

  if(substr(directory, nchar(directory), nchar(directory)) != "/") {
    if(substr(directory, nchar(directory), nchar(directory)) != "\\") {
      directory <- paste0(directory, "/")
    }
  }

  for(i in 1:length(file.list)) {
    if(i == 1) {
      out.df <- read.csv(file = paste0(directory, dir(directory)[file.list[i]]), stringsAsFactors = F)
      out.df$fname <- dir(directory)[file.list[i]]
    } else {
      out.comb <- read.csv(file = paste0(directory, dir(directory)[file.list[i]]), stringsAsFactors = F)
      out.comb$fname <- dir(directory)[file.list[i]]
      out.df <- rbind(out.df, out.comb)
    }
  }
  return(out.df)
}
