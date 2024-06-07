#' Get trend
#'
#' @description
#' This function uses [terra::app()] to apply the [Kendall::MannKendall()] function to each pixel of a multi-layer time series SpatRaster, testing for a monotonic (either increasing or decreasing) trend in the raster values.

#' @param rasts multi-layer SpatRaster with the output of [getPredictions()], or another time series of values for which to detect a trend
#' @param occs species occurrence coordinates (2 columns in this order: x, y or LONGitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points), and in the same coordinate reference system as 'rasts'. If provided, output pixels that do not overlap these points will be NA
#' @param alpha numeric value indicating the threshold significance level for Kendall's tau statistic. Default 0.05. Pixels with p-value above this will be NA in the output.
#' @param full logical value indicating whether to output a multi-layer raster with the full results of the Mann-Kendall test, namely the Tau value, p-value (significance), S and variance of S. If set to FALSE, a single-layer raster will be returned with the (significant) Tau values.
#' @param file optional file name (including path, not including extension) if you want the outputs raster(s) to be saved on disk. If 'file' already exists in the working directory, the rasters are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return SpatRaster where each pixel (or each pixel with points, if 'occs' is not NULL) has Kendall's tau statistic (positive if increasing, negative if decreasing), or NA if the trend is non-significant (i.e., if the 2-sided p-value is larger than the specified 'alpha'). If full=TRUE (the default), additional layers are produced with the p value, S, and variance of S.
#'
#' @author A. Marcia Barbosa
#' @seealso [Kendall::MannKendall()], [spatialEco::raster.kendall()]
#' @export
#' @importFrom terra app ifel mask rast vect writeRaster
#' @importFrom Kendall MannKendall
#'
#' @examples

getTrend <- function(rasts, occs = NULL, alpha = 0.05, file = NULL, full = TRUE, verbosity = 2) {

  if (!is.null(file)) {
    if (paste0(file, ".tif") %in% list.files(getwd(), recursive = TRUE)) {
      if (verbosity > 0) message("Trend raster(s) imported from the specified 'file', which already exists in the current working directory. Please provide a different 'file' path/name if this is not what you want.")
      return(terra::rast(paste0(file, ".tif")))
    }

    if (!(dirname(file) %in% list.files(getwd()))) {
      dir.create(dirname(file), recursive = TRUE)
    }
  }

  # use Spacedman's Kendall::MannKendall adaptation to deal with NAs (https://gis.stackexchange.com/a/464198)
  # this additionally outputs an unlisted vector, appropriate for terra::app
  mannkend <- function(x) {
    if(sum(!is.na(x)) > 3) {
      return(unlist(Kendall::MannKendall(x)))
    } else {
      return(c(tau = NA, sl = NA, S = NA, D = NA, varS = NA))
    }
  }

  out <- terra::app(rasts, mannkend)

  out <- out[[-grep("D", names(out))]]  # denominator, tau=S/D (as per ?Kendall::MannKendall)

  # remove non-significant pixels:
  if (alpha < 1)  out <- terra::ifel(out$sl < alpha, out, NA)

  names(out) <- c("tau", "p_value", "S", "varS")  # ifel() removed the names

  if (isFALSE(full))  out <- out$tau

  # remove non-occurrence pixels:
  if (!is.null(occs)) {
    if (inherits(occs, "data.frame")) {
      if (ncol(occs) > 2) message ("assuming 'occs' coordinates are in the first two columns")
      occs <- terra::vect(occs, geom = colnames(occs)[1:2])
    }
    out <- terra::mask(out, occs)
  }

  if (!is.null(file)) {
    terra::writeRaster(out, filename = paste0(file, ".tif"), gdal = c("COMPRESS=DEFLATE"))
  }

  return(out)
}
