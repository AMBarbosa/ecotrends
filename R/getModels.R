#' Get models
#'
#' @param occs species occurrence coordinates (2 columns in this order: x, y or longitude, latitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points)
#' @param rasts (multi-layer) SpatRaster with the variables to use in the models
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the models; see ?getRegion for suggestions
#' @param nbg integer value indicating the maximum number of background pixels to use in the models. The default is 10,000, or the total number of pixels in the modelling region if that's less.
#' @param nreps integer value indicating the number of replicates to compute for each model. One 1 is implemented currently.
#' @param collin logical value indicating whether multicollinearity among the variables should be reduced prior to modelling. The default is TRUE, in which case the collinear::collinear function is used.
#' @param file optional file name (including path, not including extension) if you want the output list of model objects to be saved on disk

#' @return a list of 'maxnet' model objects
#' @export
#'
#' @examples

getModels <- function(occs, rasts, region = NULL, nbg = 10000, nreps = 1, collin = TRUE, file = NULL) {

  if (nreps != 1) warning("argument 'nreps' is not yet implemented, currently ignored")

  if (methods::is(region, "SpatVector") && terra::geomtype(region) == "polygons") {
    rasts <- terra::mask(rasts, region)
  }

  dat <- fuzzySim::gridRecords(rasts, occs)
  npres <- sum(dat$presence == 1)
  dat <- fuzzySim::selectAbsences(dat, sp.cols = "presence", n = nbg - npres, df = TRUE, verbosity = 0)  # same bg points for all models

  var_cols <- names(dat)[-(1:4)]
  var_splits <- strsplit(var_cols, "_")
  var_names <- unique(sapply(var_splits, getElement, 1))
  years <- sort(unique(sapply(var_splits, getElement, 2)))

  mods <- vector("list", length(years))
  names(mods) <- years
  mod_count <- 0

  var_sel <- var_cols

  for (y in years) {

    mod_count <- mod_count + 1
    message("computing model ", mod_count, " of ", length(years), ": year ", y)

    if (collin) {
      var_sel <- collinear::collinear(dat, response = "presence", predictors = var_cols[grep(y, var_cols)])
    }

    mods[[y]] <- maxnet::maxnet(dat$presence, dat[ , var_sel])
  }

  if (!is.null(file)) {
    saveRDS(mods, paste0(file, ".rds"))
  }

  return(mods)
}
