#' Get model performance
#'
#' @param rasts multi-layer SpatRaster(s), output of [getPredictions()]
#' @param data data.frame, `$data` output of [getModels()]
#' @param metrics character vector with the metrics to compute. Can be any subset of c("AUC", "TSS"), the latter computed at its optimal threshold. The default is both. Performance metrics are computed with presence against all background (using 'modEvA' package functions with pbg=TRUE), so they evaluate the capacity of distinguishing presence from random, rather than presence from absence pixels (Phillips et al., 2006).
#' @param plot logical value indicating whether plots should also be produced to illustrate the performance metrics for each model. The default is FALSE; TRUE can be slow for large datasets.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return This function returns a data frame of the performance results for each model.
#' @export
#' @importFrom terra mask nlyr vect
#' @importFrom modEvA AUC optiThresh threshMeasures
#'
#' @references
#' Phillips, S.J., Anderson, R.P., Schapire, R.E. (2006) Maximum entropy modeling of species geographic distributions. Ecological Modelling, 190: 231-259. https://doi.org/10.1016/j.ecolmodel.2005.03.026
#'
#' @examples


getPerformance <- function(rasts, data, metrics = c("AUC", "TSS"), plot = FALSE, verbosity = 2) {

  bg_coords <- terra::vect(data[ , c("x", "y")], geom = c("x", "y"),
                          crs = terra::crs(rasts[[1]]))

  if (inherits(rasts, "SpatRaster")) {  # no replicates
    pres_coords <- data[data$presence == 1, c("x", "y")]
    rasts_mask <- terra::mask(rasts, bg_coords)
    n_years <- terra::nlyr(rasts)
    perf <- matrix(data = NA, nrow = n_years, ncol = length(metrics))
    colnames(perf) <- metrics

  } else {  # with replicates, 'rasts' is a list

    rasts_mask <- lapply(rasts, terra::mask, bg_coords)
    n_years <- length(rasts)
    n_reps <- terra::nlyr(rasts[[1]])
    perf <- matrix(data = NA, nrow = n_years * n_reps, ncol = length(metrics))
    colnames(perf) <- metrics
    out <- data.frame(year = rep(names(rasts), each = n_reps), rep = rep(rep(1:n_reps), length(rasts)), perf)

  }  # end if reps


  for (y in 1:n_years) {
    year <- names(rasts)[y]

    if (verbosity > 0) {
      message("evaluating year ", y, " of ", n_years, ": ", year)
    }

    if (inherits(rasts, "SpatRaster")) {  # no replicates
      if ("AUC" %in% metrics) perf[y, "AUC"] <- modEvA::AUC(obs = pres_coords, pred = rasts_mask[[y]], simplif = TRUE, plot = plot, main = year, verbosity = 0, pbg = TRUE)

      if ("TSS" %in% metrics) {
        if (isFALSE(plot)) {
          perf[y, "TSS"] <- modEvA::threshMeasures(obs = pres_coords, pred = rasts_mask[[y]], simplif = TRUE, measures = "TSS", thresh = "maxTSS", standardize = FALSE, plot = FALSE, verbosity = 0, pbg = TRUE)[1, 1]
        } else {
          tss <- modEvA::optiThresh(obs = pres_coords, pred = rasts_mask[[y]], measures = "TSS", pch = 20, cex = 0.3, main = year, verbosity = 0, pbg = TRUE)$optimals.criteria[1, 1]
          perf[y, "TSS"] <- tss
          text(0.5, 0.05, substitute(paste(maxTSS == a), list(a = round(tss, 3))))
        } # end if plot
      }  # end if TSS

      out <- data.frame(year = names(rasts), perf)

    } else {  # if replicates

      for (r in 1:n_reps) {

        # data[data$presence == 1 && data[ , paste0("pres_rep", r)] == 0, ] <- NA  # no, as this doesn't seem to be what Maxent normally does

        pres_coords <- data[data[ , "presence"] == 1 & data[ , paste0("pres_rep", r)] == 0, c("x", "y")]  # presences that were left out of the replicate that was modelled = test presences

        if ("AUC" %in% metrics)
          out[out$year == year & out$rep == r, "AUC"] <- modEvA::AUC(obs = pres_coords, pred = rasts_mask[[y]][[r]], simplif = TRUE, plot = plot, main = paste0(y, "_rep", r), verbosity = 0, pbg = TRUE)

        if ("TSS" %in% metrics) {
          if (isFALSE(plot)) {
            out[out$year == year & out$rep == r, "TSS"] <- modEvA::threshMeasures(obs = pres_coords, pred = rasts_mask[[y]][[r]], simplif = TRUE, measures = "TSS", thresh = "maxTSS", standardize = FALSE, plot = FALSE, verbosity = 0, pbg = TRUE)[1, 1]
          } else {
            tss <- modEvA::optiThresh(obs = pres_coords, pred = rasts_mask[[y]], measures = "TSS", pch = 20, cex = 0.3, main = paste0(y, "_rep", r), verbosity = 0, pbg = TRUE)$optimals.criteria[1, 1]
            out[out$year == year & out$rep == r, "TSS"] <- tss
            text(0.5, 0.05, substitute(paste(maxTSS == a), list(a = round(tss, 3))))
          } # end if plot
        }  # end if TSS
      }  # end for r

    }  # end if reps
  }  # end for y

  return(out)
}
