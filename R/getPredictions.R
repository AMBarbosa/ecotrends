#' Get predictions
#'
#' @param rasts (multi-layer) SpatRaster containing the variables (with the same names) used in the models
#' @param mods list of [maxnet] model objects, output of [getModels()]
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the predictions. The default is NULL, to use the entire extent of 'rasts'. Note that predictions may be unreliable outside the 'region' used for [getModels()]
#' @param file optional file name (including path, not including extension) if you want the prediction rasters to be saved on disk. If 'file' already exists in the working directory, the rasters are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return multi-layer SpatRaster with the predicted values from the variables for each year
#' @author A. Marcia Barbosa
#' @export
#' @import terra
#'
#' @examples

getPredictions <- function(rasts, mods, region = NULL, file = NULL, verbosity = 2) {

  if (paste0(file, ".tif") %in% list.files(getwd(), recursive = TRUE)) {
    # stop ("'file' already exists in the current working directory; please delete it or choose a different file name.")
    if (verbosity > 0) message("Predictions imported from the specified 'file', which already exists in the current working directory. Please provide a different 'file' path/name if this is not what you want.")
    return(terra::rast(paste0(file, ".tif")))
  }

  if (!inherits(rasts, "SpatRaster"))
    stop ("'rasts' must be a 'SpatRaster' object")

  if (!is.null(region)) {
    if (!(inherits(region, "SpatVector") || inherits(region, "SpatExtent")))
      stop ("'region' must be a 'SpatVector' or a 'SpatExtent' object")

    if (verbosity > 0)
      message("masking 'rasts' with 'region'...")

    rasts <- terra::crop(rasts, region, mask = TRUE, snap = "out")
  }

  n_mods <- length(mods)
  preds <- vector("list", n_mods)
  names(preds) <- names(mods)

  for (m in 1:n_mods) {
    year <- names(mods)[m]

    if (verbosity > 0) {
      message("predicting with model ", m, " of ", n_mods, ": ", year)
    }

    rasts_year <- rasts[[grep(year, names(rasts))]]

    preds[[m]] <- terra::predict(rasts_year, mods[[m]], type = "cloglog", na.rm = TRUE)
  }

  preds <- terra::rast(preds)

  if (!is.null(file)) {
    terra::writeRaster(preds, filename = paste0(file, ".tif"), gdal = c("COMPRESS=DEFLATE"))
  }

  return(preds)
}
