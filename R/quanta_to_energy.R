#' Convert quanta to radiometric units

quanta_to_energy <- function(x, wavelength) {
  return(x*1e-6*6.02214076*10^23*(3e8/(wavelength*10e-9))*6.63e-34)
}