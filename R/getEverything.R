#' Get everything (package wrapper)
#'
#' @param occs species occurrence coordinates (in this order: x, y or LONgitude, LATitude), or an object from which coordinates can be extracted (e.g. a SpatVector of points)
#' @param vars character vector of the names of the variables to use - see varsAvailable()
#' @param years year range for the model time series; default 1979:2013
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the models; see ?getRegion for suggestions
#' @param res spatial resolution (pixel size), if larger than the original variable raster layers', in which case terra::aggregate() is used
#'
#' @return
#' @export
#'
#' @examples


getEverything <- function(occs, vars = "all", years = 1979:2013, region = NULL, res = 5) {

  stop("sorry, this function is still not implemented")

  message ("downloading variables...")
  if (res > 0.5) message ("aggregating variables to requested resolution...")
  message ("reducing collinearity...")
  message ("computing models...")
  message ("obtaining model predictions...")
  message ("computing suitability trend...")
  message ("done!")

  # output:
  # - models: list of model objects
  # - preds: list of pred rasters
  # - MKtest: Mann-Kendall test result
  # - trend: HS trend raster

}
