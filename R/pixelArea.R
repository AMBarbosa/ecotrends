#' Average pixel area
#'
#' @description
#' This function uses the [terra::cellSize()] function to compute (and optionally map) the area covered by each (optionally non-NA) pixel in a raster map; and then it computes either the mean or the centroid pixel area in that map, for an idea of pixel size in that region. Pixel size can vary widely across latitudes, especially in unprojected longitude-latitude rasters, but also in rasters projected to other non-equal-area coordinate reference systems.
#'
#' @param rast SpatRaster for which to compute the pixel area
#' @param type character value indicating whether the output value should be the "mean" (default) or "centroid" pixel area
#' @param unit numeric value indicating the units for the output value: either "m" (default) or "km" squared.
#' @param mask logical value (default TRUE) indicating whether to consider only the areas of non-NA pixels
#' @param map logical value (default TRUE) indicating whether to also plot a map
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return numeric value
#' @author A. Marcia Barbosa, wrapping 'terra' functions by Robert H. Hijmans
#' @seealso [terra::cellSize()], which this function wraps
#'
#' @export
#' @import terra
#'
#' @examples
#' r <- terra::rast(system.file("ex/elev.tif", package = "terra"))
#'
#' pixelArea(r)
#'
#' pixelArea(r, unit = "km")


pixelArea <- function(rast, # SpatRaster
                      type = "mean", # can also be "centroid"
                      unit = "m",  # can also be "km"
                      mask = TRUE,  # to use only non-NA pixels
                      map = TRUE,
                      verbosity = 2) {

  # by A. Marcia Barbosa (https://modtools.wordpress.com/)
  # version 1.4 (17 May 2024)

  r <- rast

  stopifnot(inherits(r, "SpatRaster"),
            type %in% c("mean", "centroid"))

  r_size <- terra::cellSize(r, unit = unit, mask = mask)
  if (map) terra::plot(r_size, main = paste0("Pixel area (", unit, "2)"))
  areas <- terra::values(r_size, mat = FALSE, dataframe = FALSE, na.rm = FALSE)  # na.rm must be FALSE for areas[centr_pix] to be correct

  if (type == "mean") {
    out <- mean(areas, na.rm = TRUE)
    if (verbosity > 0) message(paste0("Mean pixel area (", unit, "2):\n", out, "\n"))
    return(out)
  }

  if (type == "centroid") {
    r_pol <- terra::as.polygons(r * 0, aggregate = TRUE)
    centr <- terra::centroids(r_pol)
    if (map) {
      if (!mask) terra::plot(r_pol, lwd = 0.2, add = TRUE)
      terra::plot(centr, pch = 4, col = "blue", add = TRUE)
    }

    centr_pix <- terra::cellFromXY(r, terra::crds(centr))
    out <- areas[centr_pix]
    if (!is.finite(out)) message("The centroid of your region may not have a pixel value; consider using mask=FALSE, or type = 'mean'.")
    if (verbosity > 0) message(paste0("Centroid pixel area (", unit, "2):\n", out, "\n"))
    return(out)
  }
}
