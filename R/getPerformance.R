#' Get model performance
#'
#' @param rasts multi-layer SpatRaster with the output of [getPredictions()]
#' @param data data.frame `$data` output of [getModels()]
#' @param metrics character vector with the metrics to compute. Can be any subset of c("AUC", "TSS") -- the latter is computed at its optimal threshold. The default is both
#' @param plot logical value indicating whether plots should also be produced to illustrate the performance metrics
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available
#'
#' @return
#' @export
#' @importFrom terra mask nlyr vect
#' @importFrom modEvA AUC optiThresh threshMeasures
#'
#' @examples


getPerformance <- function(rasts, data, metrics = c("AUC", "TSS"), plot = TRUE, verbosity = 2) {

  pres_centroids <- data[data$presence == 1, c("x", "y")]
  mod_locs <- terra::vect(data[ , c("x", "y")], geom = c("x", "y"),
                          crs = terra::crs(rasts))
  rasts_mask <- terra::mask(rasts, mod_locs)

  n_mods <- terra::nlyr(rasts)
  perf <- matrix(data = NA, nrow = n_mods, ncol = length(metrics))
  colnames(perf) <- metrics

  for (m in 1:n_mods) {
    year <- names(rasts)[m]

    if (verbosity > 0) {
      message("evaluating model ", m, " of ", n_mods, ": ", year)
    }

    if ("AUC" %in% metrics) perf[m, "AUC"] <- modEvA::AUC(obs = pres_centroids, pred = rasts_mask[[m]], simplif = TRUE, plot = plot, main = year, verbosity = 0)

    if ("TSS" %in% metrics) {
      if (isFALSE(plot)) {
        perf[m, "TSS"] <- modEvA::threshMeasures(obs = pres_centroids, pred = rasts_mask[[m]], simplif = TRUE, measures = "TSS", thresh = "maxTSS", standardize = FALSE, plot = FALSE, verbosity = 0)[1, 1]
      } else {
        tss <- modEvA::optiThresh(obs = pres_centroids, pred = rasts_mask[[m]], measures = "TSS", pch = 20, cex = 0.3, main = year, verbosity = 0)$optimals.criteria[1, 1]
        perf[m, "TSS"] <- tss
        text(0.5, 0.05, substitute(paste(maxTSS == a), list(a = round(tss, 3))))
      }
    }
  }

  perf <- data.frame(year = names(rasts), perf)
  return(perf)
}

