#' Get variable importance
#'
#' This function computes the permutation importance of each variable in each model, by shuffling each variable in turn (a given number of times) and computing the root mean squared difference between the actual model predictions and those obtained with the shuffled variable. Note that "importance" is a vague concept which can be measured in many other different ways.
#'
#' @param mods output of [getModels()].
#' @param nper integer value (default 10; increase for more accurate but computationally intensive results) indicating the number of permutations for shuffling each variable.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return A data frame with the permutation importance of each variable in each model replicate for each year, along with the cross-replicate mean and standard deviation.
#'
#' @seealso \code{varImportance} in package \pkg{predicts}; \code{bm_VariablesImportance} in package \pkg{biomod2}
#'
#' @author A. Marcia Barbosa
#' @export
#' @importFrom stats sd
#'
#' @examples


getImportance <- function(mods, nper = 10, verbosity = 2) {

  models <- mods$models
  n_years <- length(models)
  n_reps <- length(models[[1]])

  varimps <- vector("list", n_years)
  names(varimps) <- names(models)

  for (y in 1:n_years) {
    year <- names(models)[y]

    if (verbosity > 0) {
      if (n_reps <= 1)
        message("computing year ", y, " of ", n_years, ": ", year)
      else
        message("computing year ", y, " of ", n_years, " (with replicates): ", year)
    }

    dat <- mods$data[ , grep(year, names(mods$data))]
    varimps[[y]] <- vector("list", length(models[[y]]))
    names(varimps[[y]]) <- names(models[[y]])

    for (r in 1:n_reps){
      # varimps[[y]][[r]] <- predicts::varImportance(models[[y]][[r]], y = mods$data$presence, x = dat, n = nper, stat = "RMSE", type = "cloglog")
      varimps[[y]][[r]] <- varImpor(models[[y]][[r]], data = dat, nper = nper)
    }  # end for r

    varimps[[y]] <- do.call(cbind.data.frame, varimps[[y]])
  }  # end for y

  varimps <- do.call(rbind.data.frame, varimps)
  varimps$mean <- apply(varimps, 1, mean)
  varimps$sd <- apply(varimps, 1, sd)

  splits <- strsplit(rownames(varimps), "\\.")
  varimps <- data.frame(year = sapply(splits, getElement, 1),
                        variable = sapply(splits, getElement, 2),
                        varimps)
  rownames(varimps) <- NULL

  return(varimps)
}


varImpor <- function(model, data, nper) {
  original_predictions <- as.vector(predict(model, data, type = "cloglog"))
  importance_scores <- numeric(ncol(data))

  for (i in seq_along(importance_scores)) {
    permuted_scores <- numeric(nper)

    for (p in 1:nper) {
      permuted_data <- data
      permuted_data[, i] <- sample(permuted_data[, i])
      permuted_predictions <- as.vector(predict(model, permuted_data, type = "cloglog"))
      # permuted_scores[p] <- mean((original_predictions - permuted_predictions)^2)
      permuted_scores[p] <- mean(modEvA::errorMeasures(obs = original_predictions, pred = permuted_predictions)$RMSE)
      }

    importance_scores[i] <- mean(permuted_scores)
  }

  importance_scores <- importance_scores / sum(importance_scores) * 100
  names(importance_scores) <- colnames(data)
  return(importance_scores)
}
