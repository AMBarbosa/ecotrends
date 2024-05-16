#' Title
#'
#' @param occ species occurrence coordinates (2 columns in this order: x, y or longitude, latitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points)
#' @param rst (multi-layer) SpatRaster with the variables to use in the models
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rst' within which to compute the models; see ?getRegion for suggestions
#' @param nbg integer value indicating the maximum number of background pixels to use in the models. The default is 10,000, or the total number of pixels in the modelling region if that's less.
#' @param collinear logical value indicating whether multicollinearity among the variables should be reduced prior to modelling. The default is TRUE, in which case the collinear::collinear function is used.
#' @param path optional file path if you want the model objects to be saved on disk
#'
#' @return a list of 'maxnet' model objects
#' @export
#'
#' @examples

getModels <- function(occ, rst, region = NULL, res = NULL, nbg = 10000, collinearity = TRUE, path = NULL) {

}
