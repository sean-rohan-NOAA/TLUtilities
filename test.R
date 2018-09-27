
rm(list = ls())

library(trawllight)
library(ggplot2)
library(plyr)
library(dplyr)
library(fishmethods)
library(TLUtilities)


# source TLUtilities functions for testing
sapply(paste("./R/", dir("./R/"), sep = ""), source)

#require(dplyr)

# Import csv file containing filepaths for light data DIRECTORIES. Each target directories should contain corr_Mk9Hauls.csv, deck1**.csv, and CastTimes.csv for a vessel/cruise combination. This list needs to be created by the user.
light.dir <- read.csv("../testing_space/imports/directories.csv", header = F, stringsAsFactors = F)


# Only use EBS shelf directories.
light.dir <- light.dir[which(grepl("ebs", light.dir[,1])),1]

# Let's examine what this does
print(head(light.dir))

# Wrapper function which runs TLUtilies::vertical_profiles(), trawllight::filter_stepwise(), and trawllight::calculate_attenuation() for every cast in each of the target directories. It is advisable to process only a few dierectories at a time due R memory limits and the potential for processing errors to occur. "Downcast" and "Upcast" should be processed separately. Here, I only use the 10th directory for Vessel 89, Cruise 200801
ebs <- process_all(dir.structure = light.dir[10:12],
                        cast.dir = "Downcast",
                        silent = T)

# ebs is a list containing four data frames: loess_eval, atten_values, light_ratios, resid_fit. Described below.
names(ebs)

# loess_eval contains information of the fit produced by calculate_attenuation for each cast
head(ebs$loess_eval)

# attenuation_values contains depth versus attenuation, by depth, for each cast
head(ebs$atten_values)
print(tail(ebs$atten_values))

# light_ratios contains ten columns.
head(ebs$light_ratios)

head(ebs$resid_fit)

# The columns are:
# Vessel, cruise, haul, and updown can be associated with georeferenced casts.
# cdepth = depth bin
# trans_llight = light measurements transformed from "tag units"
# quality = continuity check. 1 is "good," -999 is "bad"
# light_ratio = proportional light measurement at depth relative ot the shallowest light measurement. If the shallowest depth measurement is the reference depth (0-2 m depth bin), light_ratio = exp(-1 * Optical Depth)
# k_linear = attenuation coefficient between the shallowest light measurement and the depth bin.
# k_column = attenuation coefficient betweent he shallowest light mesaurement and the deepest light measurement.


# Now that we have column data, it's time to get the corresponding surface light data.
# Wrapper function which runs TLUtilities::time_adjustments() and TLUtilities::surface_light().
#ebs_surf <- process_all_surface(dir.structure = light.dir, time.buffer = 30)

ebs_surf <- process_all_surface(dir.structure = light.dir[10:12], time.buffer = 30, adjust.time = T)

haul_time_position <- readRDS("../testing_space/data/haul_time_position.rds")
str(haul_time_position)
head(ebs_surf)
uuu <- merge(subset(ebs$light_ratios, updown == "Downcast"), haul_time_position)
uuu <- merge(uuu, ebs_surf)


head(uuu.resid1$direct_residual)
head(uuu.resid2$resid_df$direct_residual)

uuu.resid$lm_dbin1
head(uuu.resid)
head(ebs_surf)
### Finding surfeace measurement errors

# Inspecting plots of model PAR versus surface light indicates there was a problem with trawl vessel 134, cruise 200601. Stan's notes indicate what the problem was, but here is a general approach to finding an error.

# First, I check for evidence that the photoelectric cell is obstructed. An obstructed photoelectric cell would cause a large decline in light measurements to occur for a prolonged period.

bbb <- read.csv(file = paste(light.dir[5], "\\deck1_0490940.csv", sep = ""), header = F)
head(bbb)
names(bbb) <- c("date", "time", "cdepth", "temp", "clight")
bbb$datetime <- paste(bbb$date, bbb$time)
bbb$datetime <- as.POSIXct(bbb$datetime, format = "%m/%d/%Y %H:%M:%S", tz = "America/Anchorage")
ggplot(data = bbb, aes(x = datetime, y = clight)) + geom_path()

# No evidence of obstruction, so let's check if the time stamps are off.

# Using astrocalc4r, I find the sunrise time for the latitude and longitude for the first haul of every day.
ccc <- subset(haul_time_position, vessel == 134 & cruise == 200601)
ccc <- subset(ccc, haul %in% aggregate(haul ~ yday(ccc$start_time), data = ccc, FUN = min)[,2])
ccc <- cbind(ccc,
       astrocalc4r(day = day(ccc$start_time),
                  month = month(ccc$start_time),
                  year = year(ccc$start_time),
                  hour = hour(ccc$start_time) + minute(ccc$start_time)/60,
                  timezone = rep(-8, nrow(ccc)),
                  lat = ccc$start_latitude,
                  lon = ccc$start_longitude,
                  seaorland = "maritime"))

ccc$sunrise2 <- as.POSIXct(paste(date(ccc$start_time), " ", floor(ccc$sunrise), ":", floor(ccc$sunrise%%1 * 60), ":", floor((ccc$sunrise%%1 * 60)%%1*60), sep = ""), tz = "America/Anchorage")

# Plot it.
ggplot() + geom_path(data = subset(bbb, month(datetime) <= 7 & day(datetime) < 15), aes(x = datetime, y = clight)) +
  geom_vline(data = subset(ccc, month(sunrise2) <= 7 & day(sunrise2) < 15), aes(xintercept = sunrise2), col = "red", linetype = 2)

# The dotted red lines are sunrise times for the starting coordinates of the haul. Sunrise times look good for June and the first part of July, but appear to be off after July 8.

ggplot() + geom_path(data = subset(bbb, month(datetime) >= 7 & day(datetime) > 5), aes(x = datetime - 12 * 3600, y = clight)) +
  geom_vline(data = subset(ccc, month(sunrise2) >= 7 & day(sunrise2) > 5), aes(xintercept = sunrise2), col = "red", linetype = 2)

# In this case, I already knew from Stan's notes that the archival tag timestamps were off by 12 hours. Subtracting 12*3600 from the timestamps fixes the problem, so I add the following block of code to time_adjustments.R

# if(cast.data$vessel[1] == 134 & cast.data$cruise[1] == 200601) {
#   print("Correcting 134-201101")
#   light.data$ctime[month(light.data$ctime) >=7 & day(light.data$ctime) > 8] <- light.data$ctime[month(light.data$ctime) >=7 & day(light.data$ctime) > 8] - 3600*12 # Time off by 1 hour
# }





# Correcting offset issue for 162-201101
# dir(paste0("../testing_space/", light.dir[15]))


# No evidence of obstruction, so let's check if the time stamps are off.

# Using astrocalc4r, I find the sunrise time for the latitude and longitude for the first haul of every day.
ccc <- subset(haul_time_position, vessel == 162 & cruise == 201101)
ccc <- subset(ccc, haul %in% aggregate(haul ~ yday(ccc$start_time), data = ccc, FUN = min)[,2])
ccc <- cbind(ccc,
             astrocalc4r(day = day(ccc$start_time),
                         month = month(ccc$start_time),
                         year = year(ccc$start_time),
                         hour = hour(ccc$start_time) + minute(ccc$start_time)/60,
                         timezone = rep(-8, nrow(ccc)),
                         lat = ccc$start_latitude,
                         lon = ccc$start_longitude,
                         seaorland = "maritime"))

ccc$sunrise2 <- as.POSIXct(paste(date(ccc$start_time), " ", floor(ccc$sunrise), ":", floor(ccc$sunrise%%1 * 60), ":", floor((ccc$sunrise%%1 * 60)%%1*60), sep = ""), tz = "America/Anchorage")

ggplot() + geom_path(data = bbb, aes(x = datetime, y = clight)) +
  geom_vline(data = ccc, aes(xintercept = sunrise2), col = "red", linetype = 2)

ggplot() + geom_path(data = bbb, aes(x = datetime + 8 *3600, y = clight)) +
  geom_vline(data = ccc, aes(xintercept = sunrise2), col = "red", linetype = 2)

ggplot() + geom_path(data = subset(bbb, month(datetime) <= 7 & day(datetime) < 15), aes(x = datetime, y = clight)) +
  geom_vline(data = subset(ccc, month(sunrise2) <= 7 & day(sunrise2) < 15), aes(xintercept = sunrise2), col = "red", linetype = 2)

# The dotted red lines are sunrise times for the starting coordinates of the haul. Sunrise times look good for June and the first part of July, but appear to be off after July 8.

ggplot() + geom_path(data = subset(bbb, month(datetime) >= 7 & day(datetime) > 5), aes(x = datetime - 12 * 3600, y = clight)) +
  geom_vline(data = subset(ccc, month(sunrise2) >= 7 & day(sunrise2) > 5), aes(xintercept = sunrise2), col = "red", linetype = 2)

### Demonstrating alternative algorithms to smooth raw light data
require(trawllight)
require(castr)
require(devtools)
install_github("jiho/castr")

test <- test_process_all(dir.structure = "D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/data/LightData/Data/year_09/ebs/v_89",
                 cast.dir = "Downcast",
                 silent = T)
test <- subset(test, vessel == 89 & cruise == 200901)

direct.orient <- readRDS(file = "D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/output/downcasts_algorithm.rds")
indirect.orient <- readRDS(file = "D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/output/downcasts_indirect_algorithm.rds")
loess.resid <- readRDS(file = "D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/output/loess_residuals.rds")


haulz <- unique(test$haul)
stepwise <- vector()
mod_fit <- vector()

pdf(file = "D:/test_downcasts.pdf", width = 10, height = 8)
for(i in 1:length(haulz)) {

  testA <- subset(test, haul == haulz[i])

  test2 <- testA

  test2$dbin <- findInterval(test2$cdepth, seq(0, max(test2$cdepth), 2), rightmost.closed = T, left.open = F) * 2 - 2/2
  test3 <- aggregate(trans_llight ~ vessel + cruise + haul + dbin, data = test2, FUN = median)

  if(nrow(test3) > 4) {

    test3.las2 <- loess.as2(x = test3$dbin, y = log10(test3$trans_llight))

    test4 <- filter_stepwise(test2, depth.col = "cdepth", light.col = "trans_llight", agg.fun = median)
    test4.las2 <- loess.as2(x = test4$cdepth, y = log10(test4$trans_llight))

    plot1 <- ggplot() +
      geom_point(data = testA, aes(y = cdepth, x = log10(trans_llight)), color = "black", size = rel(3), alpha = 0.5) +
      geom_point(data = test2, aes(y = dbin, x = log10(trans_llight)), color = "red") +
      scale_y_reverse(name = "Depth") +
      scale_x_continuous(name = "log10(light)") +
      ggtitle(haulz[i])

    plot2 <- ggplot() +
      geom_point(data = test4, aes(y = cdepth, x = log10(trans_llight)), color = "blue", size = rel(3), alpha = 0.5) +
      geom_point(data = test3, aes(y = dbin, x = log10(trans_llight)), color = "red") +
      geom_path(aes(y = seq(min(test3$dbin), max(test3$dbin), 0.2), x = predict(test3.las2, newdata = seq(min(test3$dbin), max(test3$dbin), 0.2))), color = "red") +
      geom_path(aes(y = seq(min(test4$cdepth), max(test4$cdepth), 0.2), x = predict(test4.las2, newdata = seq(min(test4$cdepth), max(test4$cdepth), 0.2))), color = "blue", linetype = 2) +
      scale_y_reverse(name = "Depth") +
      scale_x_continuous(name = "log10(light)") +
      ggtitle(" ")

    direct.orient.sub <- subset(direct.orient, haul == haulz[i] & (cruise == 200901 & vessel == 89))
    indirect.orient.sub <- subset(indirect.orient, haul == haulz[i] & (cruise == 200901 & vessel == 89))

    if(nrow(direct.orient.sub) >= 1) {
      direct.orient.sub <- subset(direct.orient.sub, cdepth == min(direct.orient.sub$cdepth))
      plot3 <- ggplot() + geom_density(aes(x = direct.orient$direct_residual[direct.orient$cdepth == min(direct.orient.sub$cdepth)])) +
        geom_vline(aes(xintercept = direct.orient.sub$direct_residual[1]), color = "red", linetype = 2) +
        ggtitle(paste0("Quality: ", direct.orient.sub$quality, ", Min. Depth: ", min(direct.orient.sub$cdepth))) +
        scale_x_continuous(name = "Direct residual") +
        scale_y_continuous(name = "Density")

    } else {
      plot3 <- ggplot() + geom_text(aes(x = 1, y = 1, label = "Minimum depth > 5 m")) + ggtitle(" ")
    }

    if(nrow(indirect.orient.sub) >= 1) {
      indirect.orient.sub <- subset(indirect.orient.sub, cdepth == min(indirect.orient.sub$cdepth))

      plot4 <- ggplot() + geom_density(aes(x = indirect.orient$light_residual[indirect.orient$cdepth == min(indirect.orient.sub$cdepth)])) +
      geom_vline(aes(xintercept = indirect.orient.sub$light_residual[1]), color = "red", linetype = 2) +
        scale_x_continuous(name = "Indirect residual") +
        scale_y_continuous(name = "Density") + ggtitle(" ")
    } else {
      plot4 <- ggplot() + geom_text(aes(x = 1, y = 1, label = "Minimum depth > 5 m")) + ggtitle(" ")
    }

    print(grid.arrange(plot1, plot2, plot3, plot4, nrow = 2))

    stepwise <- c(stepwise, mean(resid(test4.las2)^2))
    mod_fit <- c(mod_fit, mean(resid(test3.las2)^2))
  }
}

dev.off()


length(predict(test3.las2, newdata = seq(min(test3$dbin), max(test3$dbin), 0.2)))
length(seq(min(test3$dbin), max(test3$dbin), 0.2))
mean(stepwise)
mean(mod_fit)
ggplot()+ geom_path(aes(y = -seq(min(test3$dbin), max(test3$dbin), 0.2), x = predict(test3.las2, newdata = seq(min(test3$dbin), max(test3$dbin), 0.2))), color = "blue")
predict(test3.las2)
plot(residuals(test3.las2))

ggplot(data = test2, aes(y = cdepth, x = log10(trans_llight))) + geom_point()
ggplot(data = test2, aes(y = cdepth, x = castr::smooth(log10(trans_llight)))) + geom_point()

ggplot(data = test4, aes(y = dbin, x = log10(llight))) + geom_point() #+ geom_path(aes(y = dbin, x = predict(test3.las2)))

test.atten
ggplot() + geom_path(data = test.atten$attenuation, aes(x = -k_aicc, y = -depth))

test.atten$attenuation

ggplot(data = test3, aes(y = dbin, x = castr::smooth(log10(trans_llight)))) + geom_point()


bruv <- subset(test, haul == 58)
bruv$cdepth <- findInterval(bruv$cdepth, seq(0, max(bruv$cdepth), 2), rightmost.closed = T, left.open = F) * 2 - 2/2
bruv <- aggregate(formula = trans_llight ~ vessel + cruise + haul + updown + cdepth,
                              data = bruv,
                              FUN = median)
bruv <- bruv[order(bruv$cdepth),]

broh <- bruv

p2 <- 1
while(p2 < nrow(bruv) ) {
  if(nrow(bruv) >= (p2 + 1)) {
    if((bruv$trans_llight[p2 + 1] > bruv$trans_llight[p2])) {
      print(p2)
      bruv <- bruv[-p2,]
      p2 <- 0 # Index back to start
    }
  }
  p2 <- p2 + 1
}


ggplot() + geom_point(data=bruv, aes(x = log10(trans_llight), y = cdepth), color = "red", alpha = 0.5, size = rel(4)) +
  geom_point(data = broh, aes(x = log10(trans_llight), y = cdepth), color = "blue")


### Vessel 94, Cruise 201401

setwd("../testing_space/")

dir(light.dir[24])

# AKK
bbb <- read.csv(file = paste0(light.dir[21], "\\deck1_1190403.csv"), header = F)
ccc <- subset(haul_time_position, vessel == 162 & cruise == 201401)

bbb <- read.csv(file = paste0(light.dir[23], "\\deck1_1190403.csv"), header = F)
ccc <- subset(haul_time_position, vessel == 162 & cruise == 201501)

# VEST
bbb <- read.csv(file = paste0(light.dir[22], "\\deck1_0990424.csv"), header = F)
ccc <- subset(haul_time_position, vessel == 94 & cruise == 201401)

bbb <- read.csv(file = paste0(light.dir[24], "\\deck1_0990424.csv"), header = F)
ccc <- subset(haul_time_position, vessel == 94 & cruise == 201501)

names(bbb) <- c("date", "time", "cdepth", "temp", "clight")
bbb$datetime <- paste(bbb$date, bbb$time)
bbb$datetime <- as.POSIXct(bbb$datetime, format = "%m/%d/%Y %H:%M:%S", tz = "America/Anchorage")
ggplot(data = bbb, aes(x = datetime, y = clight)) + geom_path()

# No evidence of obstruction, so let's check if the time stamps are off.

# Using astrocalc4r, I find the sunrise time for the latitude and longitude for the first haul of every day.

#ccc <- subset(haul_time_position, vessel == 162 & cruise == 201401)
ccc <- subset(ccc, haul %in% aggregate(haul ~ yday(ccc$start_time), data = ccc, FUN = min)[,2])
ccc <- cbind(ccc,
             astrocalc4r(day = day(ccc$start_time),
                         month = month(ccc$start_time),
                         year = year(ccc$start_time),
                         hour = hour(ccc$start_time) + minute(ccc$start_time)/60,
                         timezone = rep(-8, nrow(ccc)),
                         lat = ccc$start_latitude,
                         lon = ccc$start_longitude,
                         seaorland = "maritime"))

ccc$sunrise2 <- as.POSIXct(paste(date(ccc$start_time), " ", floor(ccc$sunrise), ":", floor(ccc$sunrise%%1 * 60), ":", floor((ccc$sunrise%%1 * 60)%%1*60), sep = ""), tz = "America/Anchorage")
ggplot() + geom_path(data = subset(bbb, month(datetime) < 7), aes(x = datetime - 3600, y = clight)) +
  geom_vline(data = subset(ccc, month(sunrise2) < 7), aes(xintercept = sunrise2), col = "red", linetype = 2)

ggplot() + geom_path(data = bbb, aes(x = datetime, y = clight)) +
  geom_vline(data = ccc, aes(xintercept = sunrise2), col = "red", linetype = 2)

timeMismatch <- function() {
  bb1 <- read.csv(file = paste0(light.dir[23], "\\deck1_1190403.csv"), header = F)
  names(bb1) <- c("date", "time", "cdepth", "temp", "clight")
  bb1$vessel <- "v162"

  bb2 <- read.csv(file = paste0(light.dir[24], "\\deck1_0990424.csv"), header = F)
  names(bb2) <- c("date", "time", "cdepth", "temp", "clight")
  bb2$vessel <- "v94"

  bb <- rbind(bb1, bb2)

  bb$datetime <- paste(bb$date, bb$time)
  bb$datetime <- as.POSIXct(bb$datetime, format = "%m/%d/%Y %H:%M:%S", tz = "America/Anchorage")
  bb$datetime[bb$vessel == "v94"] <- bb$datetime[bb$vessel == "v94"] - 3600

  print(ggplot() + geom_path(data = subset(bb, month(datetime) >= 7 & day(datetime) > 15), aes(x = datetime, y = clight, color = vessel)))

}

timeMismatch()
