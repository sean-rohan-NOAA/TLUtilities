#' Vectorized version of Janiczek and DeYoung (1987) for R
#' 
#' @param IY Input year.
#' @param IM Input month
#' @param ID Input day
#' @param LO Longitude
#' @param FINIT LATITUDE
#' @param ZZ Which timezone (0 = GMT, 1 = standard zone time, 2 = local mean time)
#' @param SK Sky condition. (1 = Sun/moon visible, sky <70% overcast, 2 = sun/moon obscured by thin clouds, 3 = sun/moon obscured by average clouds, 10 = sun/moon obscured by dark stratus clouds (rare))
#' @param HR Time based on a 24 hour clock, as a numeric vector (e.g. enter 1330 for 13:30, 820 for 8:20) 
#' @param full.output If true, returns sun and moon separately.
#' @param match.mk In testing.
#' @return Illuminance (lux) at the Earth's surface.
#' @author Sean Rohan <sean.rohan@@noaa.gov>
#' @references Janiczek, P. M., and DeYoung, J.A. 1987. Computer programs for sun and moon illuminance with contingent tables and diagrams. US Nav. Observ. Circ. 171.

illumR <- function(IY, IM, ID, LO, FINIT, ZZ, SK, HR, full.output = FALSE, match.mk = FALSE) {

  # Temporary fix to handle discrepancy between f90 and R
  if(match.mk) {
  if(nchar(HR) == 4) {
    if(as.numeric(substr(HR, 3, 4)) != 0) {
      new_min<- HR%%100 * 0.625
      HR <- as.numeric(paste(c(substr(HR,1,2), 0, 0), sep = "", collapse = "")) + new_min
    }
  } else if(nchar(HR) == 3) {
    if(as.numeric(substr(HR, 2, 3)) != 0) {
      new_min<- HR%%100 * 0.625
      HR <- as.numeric(paste(c(substr(HR,1,1), 0, 0), sep = "", collapse = "")) + new_min
    }
  }
  }
  
  DEG <- function(x) {
    x + ((x-as.integer(x)) * 10)/6
  }
  
  RD <- 57.29577951
  DR <- 1/RD
  AA <- c(-0.01454, -0.10453, -0.20791, 0.00233)
  CE <- 0.91775
  SE <- 0.39715
  
  HH <- HR
  HINIT <- HH
  
 FF <- FINIT
 CC <- 360
 LI <- abs(LO)
 FO <- FF
 FF <- FF * DR
 SI <- sin(FF)
 CI <- cos(FF)
 JJ <- 367*IY-as.integer(7*(IY+as.integer((IM+9)/12))/4) + as.integer(275*IM/9) + ID - 730531
 
 ZT <- ZZ
 DT <- 0
 
 # Dealing with timezones
 if(ZZ == 0) {
   DT <- -LO/360
 } else if(ZZ == 1) {
   DT <- (LI-15*as.integer((LI+7.5)/15))/CC*sign(-LO)
 }
 
   # What does DEG() do???
   EE <- DEG(HR/100)/24 - DT - LO/360
   DD <- JJ-0.5+EE
   NN <- 1

 # SUN ----------------------------
 TT <- 280.46 + 0.98565 * DD
 TT <- TT - as.integer(TT/360) *360
 
 if(TT < 0) {
   TT <- TT + 360
 }
 
 GG <- (357.5 + 0.98560 * DD) * DR
 LS <- (TT + 1.91 * sin(GG)) * DR
 AS <- atan(CE * tan(LS)) * RD
 YY <- cos(LS)
 
 if(YY < 0) {
   AS <- AS + 180
 }
 
 SD <- SE * sin(LS)
 DS <- asin(SD)
 TT <- TT - 180
 #----------------------------
 
 TT <- TT + 360 * EE + LO
 HH <- TT - AS
 
 # ALTAZ--------------------------------
 CD <- cos(DS)
 CS <- cos(HH * DR)
 QQ <- SD * CI - CD * SI * CS
 PP <- -CD * sin(HH * DR)
 AZ <- atan(PP/QQ) * RD
 
 if(QQ < 0) {
   AZ <- AZ + 180
 }
 
 if(AZ < 0) {
   AZ <- AZ + 360
 }
 
 AZ <- AZ + 0.5
 HH <- asin(SD * SI + CD * CI *CS) * RD
 #--------------------------------------
 
 ZZ <- HH * DR
 HH <- HH - 0.95 * (NN-1) * cos(HH*DR)
 
 # REFR------------

 HA <- HH
 
 if(HH < (-5/6)) {
   # Do nothing
 } else {
   HA <- HH + 1/(tan((HH + 8.6/(HH+4.42))*DR))/60
 }
#-----------
 
 # ATMOS------
 UU <- sin(HA*DR)
 XX <- 753.66156
 SS <- asin(XX * cos(HA*DR)/(XX+1))
 MM <- XX*(cos(SS)-UU)+cos(SS)
 MM <- exp(-0.21*MM)*UU+0.0289*exp(-0.042*MM)*(1.0+(HA+90.0)*UU/57.29577951)
 #-----
 
 HA <- sign(HA)*(abs(HA)+0.5)
 
 IS <- 133775.0 * MM/SK
 IAZ <- AZ
 
 
 # MOON-----
 VV <- 218.32 + 13.1764*DD
 VV <- VV * VV/360*360
 if(VV < 0) {
   VV <- VV + 360
 }
 
 YY <- (134.96 + 13.06499 * DD) * DR
 OO <- (93.27 + 13.22935 * DD) * DR
 WW <- (235.7 + 24.38150 * DD) * DR
 SB <- sin(YY)
 CB <- cos(YY)
 XX <- sin(OO)
 SS <- cos(OO)
 SD <- sin(WW)
 CD <- cos(WW)
 VV <- (VV + (6.29-1.27*CD+0.43*CB)*SB+(0.66 + 1.27*CB)*SD-0.19*sin(GG)-0.23*XX*SS)*DR
 YY <- ((5.13-0.17*CD)*XX + (0.56*SB+0.17*SD)*SS)*DR
 SV <- sin(VV)
 SB <- sin(YY)
 CB <- cos(YY)
 QQ <- CB*cos(VV)
 PP <- CE*SV*CB-SE*SB
 SD <- SE*SV*CB+CE*SB
 AS <- atan(PP/QQ)*RD
 if(QQ < 0) {
  AS <- AS+180
 }
 DS <- asin(SD)
 # ----------------
 
 
 HH <- TT - AS
 
 # ALTAZ--------------------------------
 CD <- cos(DS)
 CS <- cos(HH * DR)
 QQ <- SD * CI - CD * SI * CS
 PP <- -CD * sin(HH * DR)
 AZ <- atan(PP/QQ) * RD
 
 if(QQ < 0) {
   AZ <- AZ + 180
 }
 
 if(AZ < 0) {
   AZ <- AZ + 360
 }
 
 AZ <- AZ + 0.5
 HH <- asin(SD * SI + CD * CI *CS) * RD
 #--------------------------------------
 
 ZZ <- HH * DR
 HH <- HH - 0.95 * (NN-1) * cos(HH*DR)
 
 # REFR------------
 
 HA <- HH
 
 if(HH < (-5/6)) {
   # Do nothing
 } else {
   HA <- HH + 1/(tan((HH + 8.6/(HH+4.42))*DR))/60
 }
 #-----------
 
 # ATMOS------
 UU <- sin(HA*DR)
 XX <- 753.66156
 SS <- asin(XX * cos(HA*DR)/(XX+1))
 MM <- XX*(cos(SS)-UU)+cos(SS)
 MM <- exp(-0.21*MM)*UU+0.0289*exp(-0.042*MM)*(1.0+(HA+90.0)*UU/57.29577951)
 #-----
 
 HA <- sign(HA)*(abs(HA)+0.5)
 
 EE <- acos(cos(VV-LS) * CB)
 PP <- 0.892*exp(-3.343/((tan(EE/2.0))^0.632))+0.0344*(sin(EE)-EE*cos(EE))
 PP <- 0.418*PP/(1.0-0.005*cos(EE)-0.03*sin(ZZ))
 IL <- PP*MM/SK
 ISUN <- IS
 IMOON <- IL
 IS <- IS+IL+0.0005/SK
 IAZ <- AZ
 IHA <- HA
 
 IHA <- 50 * (1-cos(EE)) + 0.5
 
 if(full.output) {
   IS <- list(SUN_ILL = ISUN, MOON_ILL = IMOON)
 }
 
 return(IS)
}
