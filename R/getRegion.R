#' Get region
#'
#' @description
#' This function suggests a region for building an ecological niche model around a given set of species occurrence point coordinates. Mind that this region does not consider survey effort, geographical barriers or other factors that should also be taken into account when delimiting a region for modelling.

#' @param occs species occurrence coordinates (in this order: x, y or LONgitude, LATitude) in geodetic degrees, or an object from which such coordinates can be extracted (e.g. a SpatVector of points)
#' @param type character indicating whether to use the "mean" pairwise distance among points (the default), or a fraction of the "width" (minimum diameter) of the points' spatial extent
#' @param prop if type="width", proportion of the width to use. Default 0.5
#'
#' @return
#' @author A. Marcia Barbosa
#' @seealso [terra::buffer()], [terra::width()]
#' @export
#'
#' @examples

getRegion <- function(occs,
                      type = "mean",  # can also be 'width'
                      prop = 0.5)
  {

  message("assuming occs CRS is OGC:CRS84 (EPSG:4326) (WGS84)")
  pts <- terra::vect(occs, geom = colnames(occs), crs = "OGC:CRS84")

  if (type == "mean") {
    mdist <- mean(terra::distance(pts))
    buf <- terra::buffer(pts, width = mdist)
  }

  else if (type == "width") {
    wdth <- terra::width(terra::aggregate(pts))
    buf <- terra::buffer(pts, width = wdth * prop)
  }

  return(terra::aggregate(buf))
}
