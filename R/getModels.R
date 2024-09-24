#' Get models
#'
#' @description
#' This function computes a [maxnet::maxnet()] ecological niche model per year, given a set of presence point coordinates and yearly environmental layers.

#' @param occs species occurrence coordinates (2 columns in this order: x, y or LONGitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points), and in the same coordinate reference system as 'rasts'
#' @param rasts (multi-layer) SpatRaster with the variables to use in the models. The layer names should be in the form 'varname_year', e.g. 'tmin_1981', as in the output of [getVariables()]
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the models. See [getRegion()] for suggestions. The default is NULL, to use the entire extent of 'rasts'. Note that 'region' should only include reasonably surveyed areas, as pixels that don't overlap presence points are taken by Maxent as available and not occupied by the species.
#' @param nbg integer value indicating the maximum number of background pixels to use in the models. The default is 10,000, or the total number of non-NA pixels in 'rasts' if that's less.
#' @param seed optional integer value to pass to [set.seed()] specifying the random seed to use for sampling the background pixels (if 'nbg' is smaller than the number of pixels in 'rasts').
#' @param collin logical value indicating whether multicollinearity among the variables should be reduced prior to computing each model. The default is TRUE, in which case the [collinear::collinear()] function is used.
#' @param maxcor numeric value to pass to [collinear::collinear()] (if collin = TRUE) indicating the maximum correlation allowed between any pair of predictor variables. The default is 0.75.
#' @param maxvif numeric value to pass to [collinear::collinear()] (if collin = TRUE) indicating the maximum VIF allowed for selected predictor variables. The default is 5.
#' @param classes character value to pass to [maxnet::maxnet.formula()] indicating the continuous feature classes desired. Can be "default" or any subset of "lqpht" (linear, quadratic, product, hinge, threshold) -- for example, "lqh" for just linear, quadratic and hinge features. See References for guidance.
#' @param regmult numeric value to pass to [maxnet::maxnet()] indicating the constant to adjust regularization. The default is 1. See References for guidance.
#' @param nreps integer value indicating the number of train-test data replicates for testing each model. The default (AND ONLY VALUE IMPLEMENTED SO FAR) is 0, for no train-test replicates
#' @param test numeric value indicating the proportion of pixels to set aside for testing each replicate model (if 'nreps' > 0). The default is 0.2, i.e. 20% (NOT YET IMPLEMENTED)
#' @param file optional file name (including path, not including extension) if you want the output list of model objects to be saved on disk. If 'file' already exists in the working directory (meaning that models were already computed), models are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.

#' @return A list of three elements:
#'
#' $models: a list of model objects of class [maxnet] computed on the entire dataset
#'
#' $replicates: a list of lists of model objects of class [maxnet], each computed on a different train-test data sample. NULL if nreps = 0
#'
#' $data: a data frame with the presences, remaining background points and their environmental values used in the models
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
#' @importFrom terra geomtype crop
#' @importFrom methods is
#' @importFrom fuzzySim gridRecords selectAbsences

#' @examples

getModels <- function(occs, rasts, region = NULL, nbg = 10000, seed = NULL, collin = TRUE, maxcor = 0.75, maxvif = 5, classes = "default", regmult = 1, nreps = 0, test = 0.2, file = NULL, verbosity = 2) {

  # add option for complete model (besides the replicates)??

  if (nreps > 0) warning("sorry, argument 'nreps' not yet implemented, currently ignored")
  reps <- NULL  # output placeholder

  if (!is(rasts, "SpatRaster")) warning("Note 'rasts' should be a SpatRaster object of package terra. While older formats may still work in some functions, they should be abandonded as they may cause problems downstream.")

  if (!is.null(file)) {
    if (paste0(file, ".rds") %in% list.files(getwd(), recursive = TRUE)) {
      if (verbosity > 0) message("Models imported from the specified 'file', which already exists in the current working directory. Please provide a different 'file' path/name if this is not what you want.")
      return(readRDS(paste0(file, ".rds")))
    }

    if (!(dirname(file) %in% list.files(getwd()))) {
      dir.create(dirname(file), recursive = TRUE)
    }
  }

  if (methods::is(region, "SpatVector") && terra::geomtype(region) == "polygons") {
    rasts <- terra::crop(rasts, region, mask = TRUE, snap = "out")
  }

  occs <- as.data.frame(occs)
  dat <- fuzzySim::gridRecords(rasts, occs)
  npres <- sum(dat$presence == 1)

  if (nbg < nrow(dat)) {
    dat <- fuzzySim::selectAbsences(dat, sp.cols = "presence", n = nbg - npres, seed = seed, df = TRUE, verbosity = 0)  # same bg points for all models
  }

  if (verbosity > 0 && nbg > nrow(dat)) {
    message("number of background points ('nbg') limited to the number of pixels\nin 'rasts' within 'region', which is ", nrow(dat), "\n")
  }

  var_cols <- names(dat)[-(1:4)]
  var_splits <- strsplit(var_cols, "_")
  var_names <- unique(sapply(var_splits, getElement, 1))
  years <- sort(unique(sapply(var_splits, getElement, 2)))

  mods <- vector("list", length(years))
  names(mods) <- years
  mod_count <- 0
  rep_count <- 0  # placeholder

  for (y in years) {

    mod_count <- mod_count + 1

    if (verbosity > 0) {
      message("computing model ", mod_count, " of ", length(years), ": ", y)
    }

    vars_year <- var_cols[grep(y, var_cols)]

    if (collin) {
      vars_sel <- collinear::collinear(dat, response = "presence", predictors = vars_year, max_cor = maxcor, max_vif = maxvif)
    } else {
      vars_sel <- vars_year
    }

    # drop variables without variation in modelling subset (otherwise maxnet() error):
    constants <- which(sapply(dat[ , vars_sel], function(x) length(unique(x)) <= 1))
    if (length(constants) > 0) {
      message(vars_sel[constants], " dropped for having no variation within the modelled data\n")
      vars_sel <- vars_sel[-constants]
    }

    mods[[y]] <- maxnet::maxnet(p = dat$presence, data = dat[ , vars_sel], f = maxnet::maxnet.formula(dat$presence, dat[ , vars_sel], classes = classes), regmult = regmult)
  }

  if (verbosity > 0) message("")  # introduces one blank line between messages and possible warning

  if (!is.null(file)) {
    saveRDS(mods, paste0(file, ".rds"))
  }

  return(list(models = mods, replicates = reps, data = dat))

}
