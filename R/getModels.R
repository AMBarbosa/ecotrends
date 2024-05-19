#' Get models
#'
#' @description
#' This function computes a [maxnet::maxnet()] ecological niche model per year, given a set of presence point coordinates and yearly environmental layers.

#' @param occs species occurrence coordinates (2 columns in this order: x, y or LONgitude, LATitude) in an object coercible to a data.frame (e.g. a data.frame, matrix, tibble, sf object or SpatVector of points), and in the same coordinate reference system as 'rasts'
#' @param rasts (multi-layer) SpatRaster with the variables to use in the models. The layer names should be in the form 'varname_year', e.g. 'tmin_1981', as in the output of [getVariables()]
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the models; see [getRegion()] for suggestions
#' @param nbg integer value indicating the maximum number of background pixels to use in the models. The default is 10,000, or the total number of pixels in the modelling region if that's less.
#' @param nreps integer value indicating the number of replicates to compute for each model. One 1 is implemented currently.
#' @param collin logical value indicating whether multicollinearity among the variables should be reduced prior to computing each model. The default is TRUE, in which case the [collinear::collinear()] function is used, with the default values and with the species presences as 'response'.
#' @param file optional file name (including path, not including extension) if you want the output list of model objects to be saved on disk
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.

#' @return a list of model objects of class [maxnet]
#' @author A. Marcia Barbosa
#' @export
#'
#' @examples

getModels <- function(occs, rasts, region = NULL, nbg = 10000, nreps = 1, collin = TRUE, file = NULL, verbosity = 2) {

  if (paste0(file, ".rds") %in% list.files(getwd())) {
    stop ("'file' already exists in the current working directory; please delete it or choose a different file name.")
  }

  if (nreps != 1) warning("sorry, argument 'nreps' not yet implemented, currently ignored")

  if (methods::is(region, "SpatVector") && terra::geomtype(region) == "polygons") {
    rasts <- terra::mask(rasts, region)
  }

  occs <- as.data.frame(occs)
  dat <- fuzzySim::gridRecords(rasts, occs)
  npres <- sum(dat$presence == 1)

  if (nbg < nrow(dat)) {
    dat <- fuzzySim::selectAbsences(dat, sp.cols = "presence", n = nbg - npres, df = TRUE, verbosity = 0)  # same bg points for all models
  }

  var_cols <- names(dat)[-(1:4)]
  var_splits <- strsplit(var_cols, "_")
  var_names <- unique(sapply(var_splits, getElement, 1))
  years <- sort(unique(sapply(var_splits, getElement, 2)))

  mods <- vector("list", length(years))
  names(mods) <- years
  mod_count <- 0

  for (y in years) {

    mod_count <- mod_count + 1

    if (verbosity > 0) {
      message("computing model ", mod_count, " of ", length(years), ": ", y)
    }

    vars_year <- var_cols[grep(y, var_cols)]

    if (collin) {
      vars_sel <- collinear::collinear(dat, response = "presence", predictors = vars_year)
    } else {
      vars_sel <- vars_year
    }

    mods[[y]] <- maxnet::maxnet(dat$presence, dat[ , vars_sel])
  }

  if (!is.null(file)) {
    saveRDS(mods, paste0(file, ".rds"))
  }

  return(mods)
}
