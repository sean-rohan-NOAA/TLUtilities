TLUtilities
================

GitHub Documents
----------------

This is an R Markdown format used for publishing markdown documents to GitHub. When you click the **Knit** button all R code chunks are run and a markdown file (.md) suitable for publishing to GitHub is generated.

Including Code
--------------

You can include R code in the document as follows:

``` r
library(trawllight)
rm(list = ls())
# source("./R/vertical_profiles.R")
# source("./R/process_all.R")
# source("./R/process_all_surface.R")
# source("./R/time_adjustments.R")

# source TLUtilities functions for testing
sapply(paste("./R/", dir("./R/"), sep = ""), source)
```

    ##         ./R/process_all.R ./R/process_all_surface.R ./R/surface_light.R
    ## value   ?                 ?                         ?                  
    ## visible FALSE             FALSE                     FALSE              
    ##         ./R/time_adjustments.R ./R/vertical_profiles.R
    ## value   ?                      ?                      
    ## visible FALSE                  FALSE

``` r
#require(dplyr)

# Import csv file containing filepaths for light data DIRECTORIES. Each target directories should contain corr_Mk9Hauls.csv, deck1**.csv, and CastTimes.csv for a vessel/cruise combination. This list needs to be created by the user.
light.dir <- read.csv("D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/data/fileinv_lightdata_directory.csv", stringsAsFactors = F, header = F)


# Only use EBS shelf directories.
light.dir <- light.dir[which(grepl("ebs", light.dir[,1])),1]

# Let's examine what this does
print(head(light.dir))
```

    ## [1] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_04\\ebs\\v_88" 
    ## [2] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_04\\ebs\\v_89" 
    ## [3] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_05\\ebs\\v_88" 
    ## [4] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_05\\ebs\\v_89" 
    ## [5] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_06\\ebs\\v_134"
    ## [6] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_06\\ebs\\v_88"

Including Plots
---------------

You can also embed plots, for example:

![](README_files/figure-markdown_github/pressure-1.png)

Note that the `echo = FALSE` parameter was added to the code chunk to prevent printing of the R code that generated the plot.
