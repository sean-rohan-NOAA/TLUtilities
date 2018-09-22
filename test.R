library(trawllight)
rm(list = ls())
# source("./R/vertical_profiles.R")
# source("./R/process_all.R")
# source("./R/process_all_surface.R")
# source("./R/time_adjustments.R")

# source TLUtilities functions for testing
sapply(paste("./R/", dir("./R/"), sep = ""), source)

#require(dplyr)

# Import csv file containing filepaths for light data DIRECTORIES. Each target directories should contain corr_Mk9Hauls.csv, deck1**.csv, and CastTimes.csv for a vessel/cruise combination. This list needs to be created by the user.
light.dir <- read.csv("D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/data/fileinv_lightdata_directory.csv", stringsAsFactors = F, header = F)


# Only use EBS shelf directories.
light.dir <- light.dir[which(grepl("ebs", light.dir[,1])),1]

# Let's examine what this does
print(head(light.dir))

# Wrapper function which runs TLUtilies::vertical_profiles(), trawllight::filter_stepwise(), and trawllight::calculate_attenuation() for every cast in each of the target directories. It is advisable to process only a few dierectories at a time due R memory limits and the potential for processing errors to occur. "Downcast" and "Upcast" should be processed separately. Here, I only use the 10th directory for Vessel 89, Cruise 200801
ebs <- process_all(dir.structure = light.dir[10],
                        cast.dir = "Downcast",
                        silent = F)

# ebs is a list containing four data frames: loess_eval, atten_values, light_ratios, resid_fit. Described below.
print(names(ebs))

# loess_eval contains information of the fit produced by calculate_attenuation for each cast
print(head(ebs$loess_eval))

# attenuation_values contains depth versus attenuation, by depth, for each cast
print(head(ebs$atten_values))
print(tail(ebs$atten_values))

# light_ratios contains ten columns.
print(head(ebs$light_ratios))

print(head(ebs$resid_fit))

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
test <- process_all_surface(dir.list = light.dir, time.buffer = 30)



# table(test$updown, test$cruise)
#
# unique(bruh$atten_values$haul)
# subset(bruh$light_ratio, haul == 9)
#
# light.dir
# View(filter_stepwise)
# View(calculate_attenuation)
#
#
# hi <- median
#
# x1 <- data.frame(let = c(rep("A", 11), rep("B", 11)),
#                  value = c(1:11, 51:61))
# aggregate(value ~ let, data = x1, FUN = median)
