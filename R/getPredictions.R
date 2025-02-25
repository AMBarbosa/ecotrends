#' Get predictions
#'
#' @param rasts (multi-layer) SpatRaster containing the variables (with the same names) used in the models.
#' @param mods output of [getModels()].
#' @param region optional SpatExtent or SpatVector polygon delimiting the region of 'rasts' within which to compute the predictions. The default is NULL, to use the entire extent of 'rasts'. Note that predictions may be unreliable outside the 'region' used for [getModels()], as they are extrapolating beyond the analysed conditions.
#' @param type character value to pass to [predict()] indicating the type of response to compute. Can be "cloglog" (the default and currently recommended), "logistic" (previously but no longer recommended) (Phillips et al., 2017), "exponential", or "link".
#' @param clamp logical value to pass to [predict()] indicating whether predictors and features should be restricted to the range seen during model training. Default TRUE.
#' @param file optional folder name (including path within the working directory) if you want the prediction rasters to be saved to disk. If 'file' already exists in the working directory (meaning that predictions were already computed), predictions are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return This function returns a SpatRasterDataset with one sub-dataset per period, each of which is a (multilayer) SpatRaster with the predictions of each replicate (if there are replicates) for that period.
#' @author A. Marcia Barbosa
#' @export
#' @importFrom terra crop predict rast sds writeRaster
#' @references
#' Phillips, S.J., Anderson, R.P., Dudik, M., Schapire, R.E., Blair, M.E., 2017. Opening the black box: an open-source release of Maxent. Ecography 40, 887-893. https://doi.org/10.1111/ecog.03049

#'
#' @examples
#' # Several data prep steps required.
#' # See https://github.com/AMBarbosa/ecotrends for a full worked example.

getPredictions <- function(rasts, mods, region = NULL, type = "cloglog", clamp = TRUE, file = NULL, verbosity = 2) {

  if (!is.null(file)) {

    if (file %in% list.dirs(getwd(), full.names = FALSE)) {
      if (verbosity > 0) message("Predictions imported from the specified 'file', which already exists in the current working directory. Please provide a different 'file' path/name if this is not what you want.")
      files <- list.files(file, recursive = TRUE)
      return(terra::sds(paste(file, files, sep = "/")))
    }

    #   if (paste(getwd(), file, sep = "/") %in% list.dirs(getwd(), recursive = TRUE)) {
    #     stop("Output 'file' exists in the working directory. Please rename or (re)move it, or use a different 'file' name or path.")
    # }

    if (!(dirname(file) %in% list.dirs(getwd()))) {
      # dir.create(dirname(file), recursive = TRUE)
      dir.create(file, recursive = TRUE, showWarnings = FALSE)
    }
  }  # end if file


  if (isTRUE(all.equal(names(mods), c("models", "data")))) {
    models <- mods$models
  }

  if (!inherits(rasts, "SpatRaster"))
    stop ("'rasts' must be a 'SpatRaster' object")

  if (!is.null(region)) {
    if (!(inherits(region, "SpatVector") || inherits(region, "SpatExtent")))
      stop ("'region' must be a 'SpatVector' or a 'SpatExtent' object")

    if (verbosity > 0)
      message("masking 'rasts' with 'region'...\n")

    rasts <- terra::crop(rasts, region, mask = TRUE, snap = "out")
  }

  n_periods <- length(models)
  n_reps <- length(models[[1]])

  preds <- vector("list", n_periods)
  names(preds) <- names(models)

  for (y in 1:n_periods) {
    period <- names(models)[y]

    if (verbosity > 0) {
      if (n_reps <= 1)
        message("predicting for period ", y, " of ", n_periods, ": ", period)
      else
        message("predicting for period ", y, " of ", n_periods, " (with replicates): ", period)
    }

    rasts_period <- rasts[[grep(period, names(rasts))]]

    # if (inherits(mods[[y]], "maxnet")) { # no replicates
    #   preds[[y]] <- terra::predict(rasts_period, mods[[y]], clamp = clamp, type = type, na.rm = TRUE)
    #
    # } else {  # with replicates, 'mods' is a list
      preds[[y]] <- vector("list", length(models[[y]]))
      # names(preds[[y]]) <- paste0("rep", 1:length(models[[y]]))
      names(preds[[y]]) <- names(models[[y]])
      for (r in 1:length(models[[y]])) {
        preds[[y]][[r]] <- terra::predict(rasts_period, models[[y]][[r]], clamp = clamp, type = type, na.rm = TRUE)
      # }
    }
  }  # end for y

  # if (inherits(mods[[y]], "maxnet")) {  # no replicates
  #   preds <- terra::rast(preds)  # to match output structure for replicates
  #   preds <- list(preds)
  #   preds <- terra::sds(preds)
  # } else {  # with replicates

    preds <- lapply(preds, terra::rast)

    if (length(preds[[y]]) > 1)  # i.e. if >1 replicates
      for (y in 1:length(preds)) {
        preds[[y]] <- c(preds[[y]][[r]], terra::app(preds[[y]][[r]], "mean"))
      } # else {
      #   names(preds[[y]]) <- "rep0"
      # }

    preds <- terra::sds(preds)
  # }


  if (!is.null(file)) {

    message("\nexporting output to 'file'...")

    # if (inherits(mods[[y]], "maxnet")) { # no replicates
    #   terra::writeRaster(preds[1], filename = paste0(file, "/", basename(file), ".tif"), gdal = c("COMPRESS=DEFLATE"))
    #
    # } else {
      for (i in 1:length(preds)) {
        terra::writeRaster(preds[i], filename = paste0(file, "/", names(preds)[i], ".tif"), gdal = c("COMPRESS=DEFLATE"))
      }
    # }
  }  # end if file

  return(preds)
}
