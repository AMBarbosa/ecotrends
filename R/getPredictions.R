#' Get predictions
#'
#' @param rasts  (multi-layer) SpatRaster containing the variables (with the same names) used in the models
#' @param mods list of model objects produced with getModels()
#' @param file optional file name (including path, not including extension) if you want the output rasters to be saved on disk
#'
#' @return multi-layer SpatRaster
#' @author A. Marcia Barbosa
#' @export
#'
#' @examples

getPredictions <- function(rasts, mods, file = NULL) {

  n_mods <- length(mods)
  preds <- vector("list", n_mods)
  names(preds) <- names(mods)

  for (m in 1:n_mods) {
    year <- names(mods)[m]
    message("predicting with model ", m, " of ", n_mods, ": ", year)

    rasts_year <- rasts[[grep(year, names(rasts))]]

    preds[[m]] <- terra::predict(rasts_year, mods[[m]], type = "cloglog", na.rm = TRUE)
  }

  preds <- terra::rast(preds)

  if (!is.null(file)) {
    terra::writeRaster(preds, filename = paste0(file, ".tif"), gdal = c("COMPRESS=DEFLATE"))
  }

  return(preds)
}
