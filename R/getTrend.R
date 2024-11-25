#' Get trend
#'
#' @description
#' This function uses [terra::app()] to apply the [Kendall::MannKendall()] function to each pixel of a multi-layer time series SpatRaster, testing for a monotonic (either increasing or decreasing) trend in the raster values.

#' @param rasts multi-layer SpatRaster with the output of [getPredictions()], or another time series of values for which to detect a trend. Note that >3 non-NA values (i.e. more than 3 years) are required for a trend to be computed. If there are >1 replicates per year, their pixel-wise mean is computed prior to analysing the trend.
#' @param occs SpatVector of species occurrence points, or their spatial coordinates (2 columns in this order: x, y or LONGitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object), and in the same coordinate reference system as 'rasts'. If provided, output pixels that do not overlap these points will be NA
#' @param alpha numeric value indicating the threshold significance level for Kendall's tau statistic or for Sen's slope. Default 0.05. Pixels with p-value above this will have NA value in the output.
#' @param conf.level numeric value to pass to [trend::sens.slope()] indicating the confidence level for the slope of the trend. Default 0.95.
#' @param full logical value indicating whether to output a multi-layer raster with the full results of the Mann-Kendall test (namely the Tau value, p-value, S, and variance of S) and the results of Sen's slope calculation (slope estimate, p-value, upper and lower confidence limit). If set to FALSE, a single-layer raster will be returned with the (significant) Sen's slope values.
#' @param file optional file name (including path, not including extension) if you want the outputs raster(s) to be saved on disk. If 'file' already exists in the working directory, the rasters are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return If full=FALSE, a single-layer SpatRaster where each pixel (or each pixel with occurrence points, if 'occs' is not NULL) has the value of Sen's slope (positive if increasing, negative if decreasing), or NA if the trend is non-significant (i.e., if the 2-sided p-value is larger than the specified 'alpha'). If full=TRUE (the default), additional layers are produced with associated statistics, including the lower and upper bounds of Sen's slope (given the input 'conf.level').
#'
#' @author A. Marcia Barbosa
#' @seealso [Kendall::MannKendall()], [trend::sens.slope()], spatialEco::raster.kendall()
#' @export
#' @importFrom terra app crs ifel mask nlyr project rast vect writeRaster
#' @importFrom Kendall MannKendall
#' @importFrom trend sens.slope
#'
#' @examples

getTrend <- function(rasts, occs = NULL, alpha = 0.05, conf.level = 0.95, file = NULL, full = TRUE, verbosity = 2) {

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
    if(sum(!is.na(x)) > 3) {  # otherwise error
      return(unlist(Kendall::MannKendall(x)))
    } else {
      return(c(tau = NA,
               sl = NA,
               S = NA,
               D = NA,
               varS = NA))
    } # and see warning below
  }

  senslope <- function(x) {
    if(sum(!is.na(x)) > 1) {  # otherwise error
      s <- trend::sens.slope(x[is.finite(x)], conf.level = conf.level)
      return(c(slope = unname(s$estimates),
               p.value = s$p.value,
               lower = s$conf.int[1],
               upper = s$conf.int[2]))
    } else {
      return(c(slope = NA,
               p.value = NA,
               lower = NA,
               upper = NA))
    } # and see warning below
  }

  if (terra::nlyr(rasts[[1]]) > 1)  # with >1 replicates
    # rasts <- lapply(rasts, function(x) getElement(x, "mean"))
    rasts <- lapply(rasts, terra::app, "mean")

  rasts <- terra::rast(rasts)  # from list or from SpatRasterDataset

  out <- terra::app(rasts, mannkend)
  out <- c(out, terra::app(rasts, senslope))

  if (all(!is.finite(values(out))))  warning("Insufficient data to assess trend.")

  out <- out[[-grep("D", names(out))]]  # denominator, tau=S/D (as per ?Kendall::MannKendall)

  # remove non-significant pixels:
  # if (alpha < 1)  out <- terra::ifel(out$sl < alpha, out, NA)  # tau p.val
  if (alpha < 1)  out <- terra::ifel(out$p.value < alpha, out, NA)  # Sen p.val

  names(out) <- c("tau", "tau_p.value", "S", "varS", "slope", "slope_p.value", "slope_lowerCI", "slope_upperCI")  # ifel() removed the names

  if (isFALSE(full))  out <- out$slope

  # remove non-occurrence pixels:
  if (!is.null(occs)) {

    if (inherits(occs, "sf")) {
      occs <- terra::vect(occs)
    }

    if (inherits(occs, "data.frame")) {
      if (verbosity > 0 && ncol(occs) > 2)
        message ("assuming 'occs' X-Y coordinates are in the first two columns,\nand in the same CRS as 'rasts'")
      occs <- terra::vect(occs,
                          geom = colnames(occs)[1:2],
                          crs = terra::crs(rasts))
    }

    if (inherits(occs, "SpatVector") && !terra::same.crs(occs, out)) {
      if (verbosity > 1) message ("projecting 'occs' to the same CRS as 'rasts'")
      occs <- terra::project(occs, terra::crs(rasts))
    }

    out <- terra::mask(out, occs)
  }

  if (!is.null(file)) {
    terra::writeRaster(out, filename = paste0(file, ".tif"), gdal = c("COMPRESS=DEFLATE"))
  }

  return(out)
}
