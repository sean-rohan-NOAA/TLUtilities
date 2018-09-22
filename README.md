TLUtilities
================

Introduction
------------

This package contains functions designed to process RACE light data using functions in the trawllight package. While trawllight provides functions to process light data, it is designed to work for a generic data structure, rather than being tailored to specifically processing RACE data. TLUtilities provides functions to read-in RACE data and iterate over casts to estimate optical parameters.

This document demonstrates how light data is processed using TLUtilities and trawllight.

Installing trawllight and TLUtilities
-------------------------------------

Use the devtools pacakge to install trawlllight and TLUtilities. Functions in the trawllight pacakage have full documentation. Not all functions in TLUtilities currently have documentation.

``` r
library(devtools)
# devtools::install_github("sean-rohan/trawllight")
# devtools::install_github("sean-rohan/TLUtilities")
library(trawllight)
library(TLUtilities)
```

Import directory structure
--------------------------

TLUtilities requires the user to pass a character vector indicating where light data are maintained. Each directory should contain a single file names CastTimes.csv, a single file named corr\_Mk9Hauls.csv, and any number (including zero) of files named deck\*\*.csv. The CastTimes.csv files contains survey event times associated with cast start/stop. The corr\_Mk9.Hauls.csv file contains data from a TDR-Mk9 archival tag with time-stamps shifted to match 'survey' time in cases where temporal drift occurred.

``` r
light.dir <- read.csv("D:/Projects/OneDrive/Thesis/Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea/data/fileinv_lightdata_directory.csv", stringsAsFactors = F, header = F)

# Select EBS shelf directories
light.dir <- light.dir[which(grepl("ebs", light.dir[,1])),1]

print(light.dir[1:3])
```

    ## [1] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_04\\ebs\\v_88"
    ## [2] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_04\\ebs\\v_89"
    ## [3] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_05\\ebs\\v_88"

Read-in and process trawl light data
------------------------------------

Run a wrapper function which runs `vertical_profiles`, `trawllight::convert_light`, `trawllight::filter_stepwise`, `trawllight::calculate_attenuation` for every cast in each of the target directories. The `vertical_profiles` function uses CastTimes to extract the light measurements from corr\_Mk9Hauls.csv which were obtained during upcasts or downcasts. A time buffer can be specified to extend the cast window. Other arguments can be passed to the functions which are used for processing each cast.

Directories should be processed in batches of 4-6 vessel/cruise combinations to avoid issues with R memory limits (which can substantially increase processing time or cause R to crash). Downcasts and Upcasts should be processed separately. Here, processing is demonstrated for one vessel and one year. Change indexing of light.dir to process multiple years simultaneously (i.e. `light.dir[1:4]`). See below for description of values returned.

``` r
print(light.dir[10])
```

    ## [1] "D:\\Projects\\OneDrive\\Thesis\\Chapter 1 - Visual Foraging Condition in the Eastern Bering Sea\\data\\LightData\\Data\\year_08\\ebs\\v_89"

``` r
ebs <- process_all(dir.structure = light.dir[10],
                   cast.dir = "Downcast",
                   time.buffer = 20,
                   silent = T)
```

    ## [1] "No cast data found!"

The warning "No cast data found!" indicates there were no useable data for one of the casts

Vertical profiles
-----------------

The `process_all()` function returns a list of four data frames: `loess_eval`, `atten_values`, `light_ratios`, and `resid_fit`.

``` r
print(names(ebs))
```

    ## [1] "loess_eval"   "atten_values" "light_ratios" "resid_fit"

`loess_eval` contains information about loess model fits between depth and log(light), with one record for each model that was fitted.

``` r
print(head(ebs$loess_eval))
```

    ##    span_fit nobs      enp        rse smooth_trace fit_method vessel cruise
    ## 1 0.2910569   36 6.635794 0.17961858     7.888946       aicc     89 200801
    ## 2 0.5535042   15 3.468756 0.08938001     4.087326       aicc     89 200801
    ## 3 0.6739448   14 3.215754 0.13379515     3.777037       aicc     89 200801
    ## 4 0.8883854   16 2.465050 0.13012491     2.810392       aicc     89 200801
    ## 5 0.6295183   21 3.198044 0.03607755     3.736152       aicc     89 200801
    ## 6 0.6168078   15 3.758839 0.13642258     4.444581       aicc     89 200801
    ##   haul
    ## 1    1
    ## 2    2
    ## 3    3
    ## 4    4
    ## 5    5
    ## 6    6

`resid_fit` contains depth-specific residuals for each fitted loess model.

``` r
print(head(ebs$resid_fit))
```

    ##      residual log_trans_llight cdepth vessel cruise haul
    ## 1 -0.13267069         5.771919      1     89 200801    1
    ## 2  0.12355795         5.375319     11     89 200801    1
    ## 3  0.07095586         5.243119     13     89 200801    1
    ## 4  0.05681863         4.978719     15     89 200801    1
    ## 5  0.07815925         4.714319     17     89 200801    1
    ## 6  0.15090459         4.449919     19     89 200801    1

`atten_values` contains instantaneous attenuation, by user-specified depth intervals, for each cast.

``` r
print(head(ebs$atten_values))
```

    ##   depth      k_aicc vessel cruise haul
    ## 1  1.25 -0.06615312     89 200801    1
    ## 2  1.75 -0.06340003     89 200801    1
    ## 3  2.25 -0.06109052     89 200801    1
    ## 4  2.75 -0.05922458     89 200801    1
    ## 5  3.25 -0.05780223     89 200801    1
    ## 6  3.75 -0.05682346     89 200801    1

`light_ratios` contains converted light measurements, for each depth bin and cast.

Read-in surface (deck) light data
---------------------------------
