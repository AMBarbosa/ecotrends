#' Get models
#'
#' @description
#' This function computes yearly [maxnet::maxnet()] ecological niche models, given a set of presence point coordinates and yearly environmental layers.

#' @param occs species occurrence coordinates (2 columns in this order: x, y or LONGitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points), and in the same coordinate reference system as 'rasts'
#' @param rasts (multi-layer) SpatRaster with the variables to use in the models. The layer names should be in the form 'varname_year', e.g. 'tmin_1981', as in the output of [getVariables()]. Note that, if a variable has no spatial variation in a given year, it is excluded (as it cannot have an effect) in that year's model, so in practice not all models will include the exact same set of variables. If verbosity > 1, messages will report which variables were excluded from each year.
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the models. The default is NULL, to use the entire extent of 'rasts' with pixel values. Note that 'region' should ideally include only reasonably surveyed areas that are accessible to the species, as pixels that don't overlap presence points are taken by Maxent as available and unoccupied.
#' @param nbg integer value indicating the maximum number of background pixels to select randomly for use in the models. The default is 10,000, or the total number of non-NA pixels in 'rasts' if that's less.
#' @param seed optional integer value to pass to [set.seed()] specifying the random seed to use for sampling the background pixels (if 'nbg' is smaller than the number of pixels in 'rasts') and for extracting the test samples (if nreps > 0).
#' @param bias argument to pass to [fuzzySim::selectAbsences()] specifying if/how the selection of unoccupied background points should be biased to incorporate survey effort. Can be TRUE to make selection more likely towards the vicinity of occurrence points (which may indicate that those areas have been surveyed); or a SpatRaster of weights (bias layer), with the same coordinate reference system as 'occs' and 'rasts', with higher values where selection should be proportionally more likely, and zero or NA where points should not be placed. Default FALSE.
#' @param collin logical value indicating whether multicollinearity among the variables should be reduced prior to computing each model. The default is TRUE, in which case the [collinear::collinear()] function is used. Note that, if the collinearity structure varies among years, the set of included variables may also vary. If verbosity > 1, messages will report which variables were excluded from each year.
#' @param maxcor numeric value to pass to [collinear::collinear()] (if collin = TRUE) indicating the maximum correlation allowed between any pair of predictor variables. The default is 0.75.
#' @param maxvif numeric value to pass to [collinear::collinear()] (if collin = TRUE) indicating the maximum VIF allowed for selected predictor variables. The default is 5.
#' @param classes character value to pass to [maxnet::maxnet.formula()] indicating the continuous feature classes desired. Can be "default" or any subset of "lqpht" (linear, quadratic, product, hinge, threshold) -- for example, "lqh" for just linear, quadratic and hinge features. See References for guidance.
#' @param regmult numeric value to pass to [maxnet::maxnet()] indicating the constant to adjust regularization. The default is 1. See References for guidance.
#' @param nreps integer value indicating the number of train-test datasets for testing the models. The default is 10. With nreps = 0, there is no division of the dataset into train and test samples, so models are trained on the entire dataset for each year. If nreps > 0, presences are randomly assigned to the train and test sample in each replicate (in the proportion defined by the 'test' argument), while the background remains the same.
#' @param test (if nreps > 0) numeric value indicating the proportion of presences to set aside for testing each model. The default is 0.2, i.e. 20%.
#' @param file optional file name (including path, not including extension) if you want the output list of model objects to be saved on disk. If 'file' already exists in the working directory (meaning that models were already computed), models are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.

#' @return A list of three elements:
#'
#' $models: a list of lists of model objects of class [maxnet]. Each element of the list corresponds to a year, and each sub-element a replicate.
#'
#' $data: a data frame with the presences, remaining background points and their environmental values used in the model(s).
#' @seealso [maxnet::maxnet()]
#'
#' @references
#' Elith J., Phillips S.J., Hastie T., Dudik M., Chee Y.E., Yates, C.J. (2011) A Statistical Explanation of MaxEnt for Ecologists. Diversity and Distributions 17:43-57. http://dx.doi.org/10.1111/j.1472-4642.2010.00725.x
#'
#' Merow C., Smith M.J., Silander J.A. (2013) A practical guide to MaxEnt for modeling species' distributions: what it does, and why inputs and settings matter. Ecography 36:1058-1069. https://doi.org/10.1111/j.1600-0587.2013.07872.x

#' @author A. Marcia Barbosa
#' @export
#' @importFrom collinear collinear
#' @importFrom maxnet maxnet maxnet.formula
#' @importFrom terra crop same.crs
#' @importFrom fuzzySim gridRecords selectAbsences

#' @examples

getModels <- function(occs, rasts, region = NULL, nbg = 10000, seed = NULL, bias = FALSE, collin = TRUE, maxcor = 0.75, maxvif = 5, classes = "default", regmult = 1, nreps = 10, test = 0.2, file = NULL, verbosity = 2) {

  if (!inherits(rasts, "SpatRaster")) warning("Note 'rasts' should be a SpatRaster object of package terra. While older formats may still work in some functions, they should be abandonded as they may cause problems downstream.")

  if (!is.null(file)) {
    if (paste0(file, ".rds") %in% list.files(getwd(), recursive = TRUE)) {
      if (verbosity > 0) message("Models imported from the specified 'file', which already exists in the current working directory. Please provide a different 'file' path/name if this is not what you want.")
      return(readRDS(paste0(file, ".rds")))
    }

    if (!(dirname(file) %in% list.files(getwd()))) {
      dir.create(dirname(file), recursive = TRUE)
    }
  }

  if (!is.null(region)) {
    # if (methods::is(region, "SpatVector") && terra::geomtype(region) == "polygons") {
    if (!(inherits(region, "SpatVector") || inherits(region, "SpatExtent"))) {
      stop("'region' must be a SpatExtent or a SpatVector polygon.")
    }
    rasts <- terra::crop(rasts, region, mask = TRUE, snap = "out")
  }

  occs <- as.data.frame(occs)
  dat <- fuzzySim::gridRecords(rasts, occs)
  npres <- sum(dat$presence == 1)

  set.seed(seed)  # for nbg and nreps

  if (nbg < nrow(dat)) {
    if (inherits(bias, "SpatRaster") && !terra::same.crs(bias, rasts))
      warning("'bias' and 'rasts' don't have the same CRS.")
    dat <- fuzzySim::selectAbsences(dat, sp.cols = "presence", n = nbg - npres, bias = bias, df = TRUE, verbosity = 0)  # same bg points for all models; presences all included
  }

  if (verbosity > 0 && nbg > nrow(dat)) {
    message("number of background points ('nbg') limited to the number of pixels\nin 'rasts' within 'region', which is ", nrow(dat))
  }

  var_cols <- names(dat)[-(1:4)]
  var_splits <- strsplit(var_cols, "_")
  var_names <- unique(sapply(var_splits, getElement, 1))
  years <- sort(unique(sapply(var_splits, getElement, 2)))

  mods <- vector("list", length(years))
  names(mods) <- years
  mod_count <- 0
  rep_count <- 0

  message()  # blank line
  if (verbosity > 1) message (npres, " presence pixels")
  if (nreps > 0) {
    n_test_pres <- round(npres * test)
    # if (verbosity > 1) message (n_test_pres, " of which reserved for each test sample")
    if (verbosity > 1) message ("(", npres - n_test_pres, " training and ", n_test_pres, " test presences in each replicate)")
  }
  message()  # blank line

  for (y in years) {

    mod_count <- mod_count + 1

    if (verbosity > 0) {
      if (nreps <= 1)
        message("computing model ", mod_count, " of ", length(years), ": ", y)
      else
        message("computing model ", mod_count, " of ", length(years), " (with replicates): ", y)
    }

    vars_year <- var_cols[grep(y, var_cols)]

    # drop variables without variation in modelling subset (otherwise maxnet() error):
    constants <- which(sapply(dat[ , vars_year, drop = FALSE], function(x) length(unique(x)) <= 1))
    if (length(constants) > 0) {
      if (verbosity > 0) message(" - variables dropped for having no variation within the modelled data: ", paste(vars_year[constants], collapse = ", "))
      vars_year <- vars_year[-constants]
    }

    if (collin) {
      vars_sel <- collinear::collinear(dat, response = "presence", predictors = vars_year, max_cor = maxcor, max_vif = maxvif, quiet = TRUE)
      if (length(vars_sel) < length(vars_year) && verbosity > 1) message(" - variables dropped due to multicollinearity: ", paste(setdiff(vars_year, vars_sel), collapse = ", "))
    } else {
      vars_sel <- vars_year
    }


    vars_mod <- dat[ , vars_sel, drop = FALSE]

    if (nreps <= 0) {
      mods[[y]][[1]] <- maxnet::maxnet(p = dat$presence, data = vars_mod, f = maxnet::maxnet.formula(dat$presence, vars_mod, classes = classes), regmult = regmult)
      names(mods[[y]]) <- "rep0"

    } else {
      pres_inds <- which(dat$presence == 1)

      mods[[y]] <- vector("list", nreps)
      names(mods[[y]]) <- paste0("rep", 1:nreps)

      for (r in 1:nreps) {
        pres_test <- sample(pres_inds, n_test_pres)
        name <- paste0("pres_rep", r)
        dat[ , name] <- dat$presence
        dat[pres_test, name] <- 0  # not NA, because that doesn't seem to be what Maxent normally does
        mods[[y]][[r]] <- maxnet::maxnet(p = dat[ , name], data = vars_mod,
                                         f = maxnet::maxnet.formula(dat[ , name],
                                                                    vars_mod,
                                                                    classes = classes),
                                         regmult = regmult)
      }  # end for r
    }  # end if reps
  }  # end for y

  if (verbosity > 0) message()  # introduces one blank line between messages and possible warning

  out <- list(models = mods, data = dat)

  if (!is.null(file)) {
    saveRDS(out, paste0(file, ".rds"))
  }

  return(out)
}
