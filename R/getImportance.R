#' Get variable importance
#'
#' This function computes the permutation importance of each variable in each model, by shuffling each variable in turn (a given number of times) and computing the root mean squared difference between the actual model predictions and those obtained with the shuffled variable. Values are then normalized to a percentage by dividing each by the sum of all values and multiplying by 100. Note that "importance" is a vague concept which can be measured in many other different ways.
#'
#' @param mods output of [getModels()].
#' @param nper integer value (default 10; increase for more accurate but computationally intensive results) indicating the number of permutations for shuffling each variable.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#' @param plot logical value specifying whether to produce a line (spaghetti) plot of the mean importance of each variable along the years. Note that this plot currently does not reflect the deviations around this mean; and that it may become hard to read if there are many variables or if their importances overlap.
#'
#' @return A data frame with the permutation importance (expressed as percentage) of each variable in each model replicate for each year, along with the cross-replicate mean and standard deviation.
#'
#' @seealso \code{varImportance} in package \pkg{predicts}; \code{bm_VariablesImportance} in package \pkg{biomod2}
#'
#' @author A. Marcia Barbosa
#' @export
#' @importFrom stats sd
#' @importFrom grDevices hcl.colors
#'
#' @examples


getImportance <- function(mods, nper = 10, verbosity = 2, plot = TRUE) {

  models <- mods$models
  n_years <- length(models)
  n_reps <- length(models[[1]])

  importance_scores <- vector("list", n_years)
  names(importance_scores) <- names(models)

  for (y in 1:n_years) {
    year <- names(models)[y]

    if (verbosity > 0) {
      if (n_reps <= 1)
        message("computing year ", y, " of ", n_years, ": ", year)
      else
        message("computing year ", y, " of ", n_years, " (with replicates): ", year)
    }  # end if verbosity

    dat <- mods$data[ , grep(year, names(mods$data))]
    importance_scores[[y]] <- vector("list", length(models[[y]]))
    names(importance_scores[[y]]) <- names(models[[y]])

    for (r in 1:n_reps){
      # importance_scores[[y]][[r]] <- predicts::varImportance(models[[y]][[r]], y = mods$data$presence, x = dat, n = nper, stat = "RMSE", type = "cloglog")
      importance_scores[[y]][[r]] <- varImpor(models[[y]][[r]], data = dat, nper = nper)
    }  # end for r

    importance_scores[[y]] <- do.call(cbind.data.frame, importance_scores[[y]])
  }  # end for y

  importance_scores <- do.call(rbind.data.frame, importance_scores)
  importance_scores$mean <- apply(importance_scores, 1, mean)
  importance_scores$sd <- apply(importance_scores, 1, sd)

  # move year and variable from row names to new columns:
  splits <- strsplit(rownames(importance_scores), "\\.")
  importance_scores <- data.frame(year = sapply(splits, getElement, 1),
                        variable = sapply(splits, getElement, 2),
                        importance_scores)
  rownames(importance_scores) <- NULL

  if (plot) {
    importance_scores$year <- as.numeric(importance_scores$year)
    plot(x = range(importance_scores$year),
         y = range(importance_scores[ , c("mean", "sd")]),
         type = "n", xlab = "Year", ylab = "", las = 2,
         bty = "n", main = "Mean variable importance")
    vars <- substr(importance_scores$variable, 1, nchar(importance_scores$variable) - 5)  # remove year from variable names
    cols <- hcl.colors(length(unique(vars)), "Set2")
    for (v in unique(vars)) {
      clr <- cols[which(vars == v)]
      dat <- importance_scores[vars == v, ]
      mn <- dat$mean
      lines(dat$year, mn, col = clr)
      year_range <- range(dat$year)
      space <- ifelse(diff(year_range) <= 10, 1, 0.1 * diff(year_range))
      text(x = max(year_range) + space,
           y = dat$mean[length(dat$mean)],
           labels = v, cex = 0.8, col = clr, xpd = NA)  # note text overlaps may occur - to be enhanced!
    } # end for v
  }  # end if plot

  return(importance_scores)
}


varImpor <- function(model, data, nper) {
  original_predictions <- as.vector(predict(model, data, type = "cloglog"))

  importance_scores <- numeric(ncol(data))

  for (v in seq_along(importance_scores)) {
    permuted_scores <- numeric(nper)

    for (p in 1:nper) {
      permuted_data <- data
      permuted_data[, v] <- sample(permuted_data[, v])
      permuted_predictions <- as.vector(predict(model, permuted_data, type = "cloglog"))
      permuted_scores[p] <- sqrt(mean((original_predictions - permuted_predictions)^2))  # RMSE
    }

    importance_scores[v] <- mean(permuted_scores)
  }  # end for v

  # normalize and convert to percentage:
  importance_scores <- importance_scores / sum(importance_scores) * 100

  names(importance_scores) <- colnames(data)

  return(importance_scores)
}
