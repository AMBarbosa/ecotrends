#' Get trend
#'
#' @description
#' This function uses [terra::app()] to apply the [Kendall::MannKendall()] function to each pixel of a multi-layer time series SpatRaster, testing for a monotonic (either increasing or decreasing) trend in the raster values.

#' @param rasts multi-layer SpatRaster with the output of [getPredictions()], or another time series of values for which to detect a trend
#' @param occs species occurrence coordinates (2 columns in this order: x, y or LONGitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points), and in the same coordinate reference system as 'rasts'. If provided, output pixels that do not overlap these points will be NA
#' @param alpha numeric value indicating the threshold significance level for Kendall's tau statistic. Default 0.05. Pixels with p-value above this will be NA in the output.
#' @param full logical value indicating whether to output a multi-layer raster with the full results of the Mann-Kendall test, namely the Tau value, p-value (significance), S and variance of S. If set to FALSE, a single-layer raster will be returned with the (significant) Tau values.
#'
#' @return SpatRaster where each pixel (or each pixel with points, if 'occs' is not NULL) has Kendall's tau statistic (positive if increasing, negative if decreasing), or NA if the trend is non-significant (i.e., if the 2-sided p-value is larger than the specified 'alpha'). If full=TRUE (the default), additional layers are produced with the p value, S, and variance of S.
#'
#' @author A. Marcia Barbosa
#' @seealso [Kendall::MannKendall()], [spatialEco::raster.kendall()]
#' @export
#' @import terra
#' @importFrom Kendall MannKendall
#'
#' @examples

getTrend <- function(rasts, occs = NULL, alpha = 0.05, full = TRUE) {

  # mannKendEst <- function(x) cor.test(x, 1:length(x), method = "kendall")$estimate
  # mannKendSig <- function(x) cor.test(x, 1:length(x), method = "kendall")$p.value
  #
  # tau <- terra::app(rasts, function(x) mannKendEst)
  # p <- terra::app(rasts, function(x) mannKendSig)


  # make MannKendall output a vector rather than a list, as required by terra::app:
  # mannkend <- function(x) do.call(rbind, lapply(x, function(x) unlist(Kendall::MannKendall(x))))  # https://stackoverflow.com/questions/14820764/split-vector-and-apply-mann-kendall-test

  tau <- terra::app(rasts, function(x) Kendall::MannKendall(x)$tau)
  p <- terra::app(rasts, function(x) Kendall::MannKendall(x)$sl)
  # tau <- terra::app(rasts, mannkend)

  if (alpha < 1) {
    out_tau <- terra::ifel(p < alpha, tau, NA)
  } else {
    out_tau <- tau
  }


  if (isFALSE(full)) {

    out <- out_tau

  } else {
    s <- terra::app(rasts, function(x) Kendall::MannKendall(x)$S)
    v <- terra::app(rasts, function(x) Kendall::MannKendall(x)$varS)

    if (alpha < 1) {
      out_p <- terra::ifel(p < alpha, p, NA)
      out_s <- terra::ifel(p < alpha, s, NA)
      out_v <- terra::ifel(p < alpha, v, NA)

    } else {
      out_p <- p
      out_s <- s
      out_v <- v
    }

    out <- c(out_tau, out_p, out_s, out_v)
    names(out) <- c("Tau", "p_value", "S", "S_variance")
  }


  if (!is.null(occs)) {
    if (inherits(occs, "data.frame")) {
      if (ncol(occs) > 2) message ("assuming 'occs' coordinates are in the first two columns")
      occs <- terra::vect(occs, geom = colnames(occs)[1:2])
    }
    out <- terra::mask(out, occs)
  }


  return(out)
}
