#' modRegion
#'
#' @param occ species occurrence coordinates (in this order: x, y or longitude, latitude), or an object from which coordinates can be extracted (e.g. a SpatVector of points)
#' @param type character indicating whether to use the "mean" pairwise distance among points (the default), or a fraction of the "width" (minimum diameter) of the points' spatial extent
#' @param prop
#' @param map logical value indicating whether to plot (map) the result
#'
#' @return
#' @export
#'
#' @examples

modRegion <- function(occ,
                      type = "mean", # can also be 'width'
                      prop,
                      map = TRUE)
  {

}
