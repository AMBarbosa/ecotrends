#' ecotrendWrapper
#'
#' @param occ species occurrence coordinates (in this order: x, y or longitude, latitude), or an object from which coordinates can be extracted (e.g. a SpatVector of points)
#' @param vars variables
#' @param years year range; default 1979:2013
#' @param res spatial resolution (pixel size)
#'
#' @return
#' @export
#'
#' @examples


ecotrendWrapper <- function(occ, vars = "all", years = 1979:2013, res = 5) {
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
