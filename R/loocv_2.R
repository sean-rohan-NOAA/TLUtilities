#' Perform leave-one-out cross-validation and spatial interpolation on EBS data
#' 
#' Sean K. Rohan <sean.rohan@@noaa.gov>
#' Last update: February 28, 2019
#' Spatial interpolation with interpolation method selection based on leave-one-out cross validation
#'
#' @param dat Data frame that contains latitude, longitude, and a variable to be interpolated.
#' @param var.col Name of the variable column that is to be interpolated
#' @param lat.col Name of the latitude column
#' @param lon.col Name of the longitude column
#' @param in.proj Projection for the input data
#' @param interp.proj Projection for the interpolation/output
#' @param scale.vars Should variable be scaled?
#' @param center Passed to \code{scale} if scale.vars == TRUE
#' @param scale Passed to \code{scale}  if scale.vars == TRUE
#' @param nm Maximum number of neighboring stations to use for interpolation.
#' @param pre Prefix for name of the output file. Default (NA) uses variable name from var.col

loocv_2 <- function(dat, var.col, lat.col, lon.col, in.proj = "+proj=longlat +datum=NAD83", interp.proj = "+init=epsg:3338 +datum=NAD83 +units=m", scale.vars = FALSE, center = TRUE, scale = TRUE, nm = Inf, pre = NA, ...) {

  names(dat)[which(names(dat) == var.col)] <- "var.col"
  names(dat)[which(names(dat) == lat.col)] <- "lat.col"
  names(dat)[which(names(dat) == lon.col)] <- "lon.col"
  
  # Scale variables
  if(scale.vars) {
    var.col.scaled <- scale(dat$var.col, center = center, scale = scale)
    dat$var.col <- var.col.scaled
  }

  # Initialize raster and mask for interpolation
  # Initialize raster for interpolation on a 5 km x 5 km grid
    sp_interp.raster <- raster(xmn=-1625000,xmx=-35000,ymn=379500,ymx=1969500,nrow=318,ncol=318)
    projection(sp_interp.raster) <- "+init=epsg:3338 +datum=NAD83 +units=m" # Define interpolation raster

  # RMSE function
  RMSE <- function(observed, predicted) {
    sqrt(mean((predicted - observed)^2))
  }

  #===========================================
  # START CROSS-VALIDATION to find optimal interpolation method for each year
  #===========================================

  # Initialize optical depth spatial data frame for kriginging
  sp_interp.df <- unique(dat)
  sp::coordinates(sp_interp.df) <- c(x = "lon.col", y = "lat.col")
  sp::proj4string(sp_interp.df) <- sp::CRS(in.proj)
  sp_interp.df <- sp::spTransform(sp_interp.df, sp::CRS("+init=epsg:3338 +datum=NAD83 +units=m"))

  null.rmse <- RMSE(mean(sp_interp.df$var.col), sp_interp.df$var.col)

  iter <- nrow(sp_interp.df)

  # Initialize vectors to store bootstrap RMSE
  idw.rmse.mean <- rep(NA, iter)
  tps.rmse.mean <- rep(NA, iter)
  exp.rmse.mean <- rep(NA, iter)
  sph.rmse.mean <- rep(NA, iter)
  bes.rmse.mean <- rep(NA, iter)
  cir.rmse.mean <- rep(NA, iter)
  gau.rmse.mean <- rep(NA, iter)
  mat.rmse.mean <- rep(NA, iter)
  ste.rmse.mean <- rep(NA, iter)
  nn.rmse.mean <- rep(NA, iter)
  stationid <- rep(NA, iter)
  cruise <- rep(NA, iter)

  for(i in 1:iter) {
    fit_test <- sp_interp.df[i,]
    train <- sp_interp.df[-i,]
    stationid[i] <- fit_test$stationid
    cruise[i] <- fit_test$cruise

    # Nearest-neighbor
    nn_fit <- gstat::gstat(formula = var.col~1, locations = train, set = list(idp = 0), nmax = nm)
    nn.predict <- predict(nn_fit, fit_test)
    nn.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = nn.predict$var1.pred))

    # IDW
    idw_fit <- gstat::gstat(formula = var.col~1, locations = train, nmax = nm)
    idw.predict <- predict(idw_fit, fit_test)
    idw.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = idw.predict$var1.pred))

    # Ordinary kriging
    exp.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Exp")))
    exp.k_fit <- gstat(formula = var.col~1, locations = train, model = exp.vgfit_train, nmax = nm)
    exp.k.predict <- predict(exp.k_fit, fit_test)
    exp.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = exp.k.predict$var1.pred))

    sph.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Sph")))
    sph.k_fit <- gstat::gstat(formula = var.col~1, locations = train, model = sph.vgfit_train, nmax = nm)
    sph.k.predict <- predict(sph.k_fit, fit_test)
    sph.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = sph.k.predict$var1.pred))

    bes.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Bes")))
    bes.k_fit <- gstat::gstat(formula = var.col~1, locations = train, model = bes.vgfit_train, nmax = nm)
    bes.k.predict <- predict(bes.k_fit, fit_test)
    bes.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = bes.k.predict$var1.pred))

    gau.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Gau")))
    gau.k_fit <- gstat::gstat(formula = var.col~1, locations = train, model = gau.vgfit_train, nmax = nm)
    gau.k.predict <- predict(gau.k_fit, fit_test)
    gau.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = gau.k.predict$var1.pred))

    cir.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Cir")))
    cir.k_fit <- gstat::gstat(formula = var.col~1, locations = train, model = cir.vgfit_train, nmax = nm)
    cir.k.predict <- predict(cir.k_fit, fit_test)
    cir.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = cir.k.predict$var1.pred))

    mat.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Mat")))
    mat.k_fit <- gstat::gstat(formula = var.col~1, locations = train, model = mat.vgfit_train, nmax = nm)
    mat.k.predict <- predict(mat.k_fit, fit_test)
    mat.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = mat.k.predict$var1.pred))

    ste.vgfit_train <- gstat::fit.variogram(variogram(idw_fit), vgm(c("Ste")))
    ste.k_fit <- gstat::gstat(formula = var.col~1, locations = train, model = ste.vgfit_train, nmax = nm)
    ste.k.predict <- predict(ste.k_fit, fit_test)
    ste.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = ste.k.predict$var1.pred))

    # TPS
    tps_fit <- fields::Tps(coordinates(train), train$var.col)
    tps.predict <- predict(tps_fit, coordinates(fit_test))
    tps.rmse.mean[i] <- mean(RMSE(observed = fit_test$var.col, predicted = tps.predict[,1]))

  }

  sp_compare.rmse <- data.frame(nn = nn.rmse.mean,
                                idw = idw.rmse.mean,
                                Exp = exp.rmse.mean,
                                Sph = sph.rmse.mean,
                                Cir = cir.rmse.mean,
                                Gau = gau.rmse.mean,
                                Bes = bes.rmse.mean,
                                Mat = mat.rmse.mean,
                                Ste = ste.rmse.mean,
                                Tps = tps.rmse.mean,
                                cruise = cruise,
                                stationid = stationid)
  
  
  # Name for the output file if not provided
  if(is.na(pre)) {
    pre <- var.col
  }

  write.csv(sp_compare.rmse, file = paste0("./output/", Sys.Date(), "_rmse_loocv_", pre, ".csv"), row.names = F)
  print(colMeans(sp_compare.rmse[,c(1:10)]))

  # Calulate RMSE from cross validation
  best.method <- names(sp_compare.rmse)[which.min(colMeans(sp_compare.rmse[,c(1:10)]))]
  print(paste("Using", best.method))

  #===========================================
  # INTERPOLATE
  #===========================================

  if(best.method %in% c("idw", "Exp", "Sph", "Bes", "Gau", "Cir", "Mat", "Ste")) {
    best.k_fit <- gstat::gstat(formula = var.col~1, locations = sp_interp.df , nmax = nm)

    if(best.method != "idw") {
      best.vgfit <- gstat::fit.variogram(gstat::variogram(best.k_fit), gstat::vgm(best.method))
      best.k_fit <- gstat::gstat(formula = var.col~1, locations = sp_interp.df, model = best.vgfit, nmax = nm)
    }

    output_raster <- predict(best.k_fit, as(sp_interp.raster, "SpatialGrid"))
    output_raster <- raster(output_raster)

  } else if(best.method == "Tps") { # Spatial interpolation using thin-plate spline
    tps_fit <- fields::Tps(sp::coordinates(sp_interp.df), sp_interp.df$var.col)
    output_raster <- raster::interpolate(sp_interp.raster, tps_fit)

  } else {
    print("Invalid interpolation method")
  }
  
  # Return to original scale
  if(scale.vars) {
    output_raster <- output_raster * attr(var.col.scaled, 'scaled:scale') + attr(var.col.scaled, 'scaled:center')
  }
  
  return(output_raster)
}
