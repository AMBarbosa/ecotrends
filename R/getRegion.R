#' getRegion
#'
#' @param occs species occurrence coordinates (in this order: x, y or LONgitude, LATitude) in geodetic degrees, or an object from which such coordinates can be extracted (e.g. a SpatVector of points)
#' @param type character indicating whether to use the "mean" pairwise distance among points (the default), or a fraction of the "width" (minimum diameter) of the points' spatial extent
#' @param prop if type="width", proportion of the width to use. Default 0.5
#'
#' @return
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
