#' Get region
#'
#' @description
#' This function suggests a region for building an ecological niche model around a given set of species occurrence point coordinates. Mind that this region does not consider survey effort, geographical barriers or other factors that should also be taken into account when delimiting a region for modelling.

#' @param occs species occurrence coordinates (2 columns in this order: x, y or LONGitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points)
#' @param type character indicating whether to use the "mean" pairwise [terra::distance()] among points (the default), or a proportion of the "width" (minimum diameter, computed with [terra::width()]) of the points' spatial extent
#' @param prop if type="width", proportion of the width to use for the [terra::buffer()] radius. Default 0.5
#' @param crs coordinate reference system behind the coordinates of 'occs', in one of the following formats: WKT/WKT2, authority:code (e.g. EPSG:4326), or PROJ-string notation (see [terra::crs()]). The default is EPSG:4326, i.e. unprojected longitude-latitude coordinates in geodetic degrees, World Geodetic System datum 1984 (WGS 84).
#'
#' @return SpatVector polygon
#' @author A. Marcia Barbosa
#' @seealso [terra::buffer()], [terra::width()]

#' @importFrom terra aggregate buffer crs distance vect width
#' @export
#'
#' @examples

getRegion <- function(occs,
                      type = "mean",  # can also be 'width'
                      prop = 0.5,
                      crs = "EPSG:4326")
  {

  occs <- as.data.frame(occs)
  pts <- terra::vect(occs, geom = colnames(occs), crs = crs)

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
