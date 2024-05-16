#' ecoTrend
#'
#' @param occ species occurrence coordinates (in this order: x, y or longitude, latitude), or an object from which coordinates can be extracted (e.g. a SpatVector of points)
#' @param vars variables
#' @param years year range
#' @param res spatial resolution (pixel size)
#' @param features feature classes for the Maxent model
#'
#' @return
#' @export
#'
#' @examples


ecoTrend <- function(occ, vars = "all", years = 1979:2013, res = 5, features = "lq") {
  message ("downloading variables...")
  if (res > 0.5) message ("aggregating variables to requested resolution...")
  message ("reducing collinearity...")
  message ("computing models...")
  message ("obtaining model predictions...")
  message ("computing suitability trend...")
  message ("done!")
}
