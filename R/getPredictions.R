#' Get predictions
#'
#' @param rasts (multi-layer) SpatRaster containing the variables (with the same names) used in the models
#' @param mods list of [maxnet] model objects, output of [getModels()]
#' @param file optional file name (including path, not including extension) if you want the output rasters to be saved on disk
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return multi-layer SpatRaster with the predicted values from the variables for each year
#' @author A. Marcia Barbosa
#' @export
#'
#' @examples

getPredictions <- function(rasts, mods, file = NULL, verbosity = 2) {

  if (paste0(file, ".tif") %in% list.files(getwd())) {
    stop ("'file' already exists in the current working directory; please delete it or choose a different file name.")
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
