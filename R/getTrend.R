#' Get trend
#'
#' @description
#' This function uses [terra::app()] to apply the [Kendall::MannKendall()] function to each pixel of a multi-layer time series SpatRaster, testing for a monotonic (either increasing or decreasing) trend in the raster values.

#' @param rasts multi-layer SpatRaster with the output of getPredictions(), or another time series of values for which to detect a trend.
#' @param alpha numeric value indicating the threshold significance level for Kendall's tau statistic. Default 0.05
#'
#' @return SpatRaster layer where each pixel has Kendall's tau statistic (positive if increasing, negative if decreasing), or NA if the trend is non-significant (i.e., if the 2-sided p-value is larger than the specified 'alpha').
#'
#' @author A. Marcia Barbosa
#' @seealso [Kendall::MannKendall()], [spatialEco::raster.kendall()]
#' @export
#'
#' @examples

getTrend <- function(rasts, alpha = 0.05) {

  # mannKendEst <- function(x) cor.test(x, 1:length(x), method = "kendall")$estimate
  # mannKendSig <- function(x) cor.test(x, 1:length(x), method = "kendall")$p.value
  #
  # tau <- terra::app(rasts, function(x) mannKendEst)
  # p <- terra::app(rasts, function(x) mannKendSig)

  tau <- terra::app(rasts, function(x) Kendall::MannKendall(x)$tau)
  p <- terra::app(rasts, function(x) Kendall::MannKendall(x)$sl)

  out <- terra::ifel(p < alpha, tau, NA)

  return(out)
}
