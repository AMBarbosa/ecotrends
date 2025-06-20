#' Get variables
#'
#' @description
#' This function downloads a specified time series of variables from a specified environmental data source, optionally (to save download time) within a specified region. Currently "TerraClimate" (Abatzoglou et al., 2018) is the only implemented data source.

#' @param source source to import the raster variables from, e.g. "TerraClimate" (currently the only one implemented)
#' @param vars character vector of the names of the variables to be imported. Run varsAvailable() for options. The default is to download all available variables from the specified 'source'. Note that the download can take a long time, especially for many variables, long series of years, and/or large regions.
#' @param years year range to get the variables from (e.g. 1979:2013). Note that the download can take a long time for long series of years.
#' @param region optional length-four numeric vector (xmin, xmax, ymin, ymax geodetic coordinates in degrees), SpatExtent or SpatVector polygon delimiting the region of the world for which the variables should be downloaded. See e.g. fuzzySim::getRegion() for suggestions. The larger the region, the longer the download time.
#' @param file optional file name (including the path, not including the filename extension) if you want the downloaded variable rasters to be saved on disk, in which case they are saved as a compressed multi-layer GeoTIFF. If 'file' already exists in the working directory, variables are imported from there.
#' @param verbosity integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available.
#'
#' @return multi-layer SpatRaster
#' @author A. Marcia Barbosa
#' @seealso [varsAvailable()]
#' @references
#' Abatzoglou, J.T., S.Z. Dobrowski, S.A. Parks, K.C. Hegewisch (2018) Terraclimate, a high-resolution global dataset of monthly climate and climatic water balance from 1958-2015. Scientific Data, 5, Article number: 170191. doi: 10.1038/sdata.2017.191(2018). Database URL: https://www.climatologylab.org/terraclimate.html

#' @export
#' @importFrom terra app rast writeRaster
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'
#' # note these downloads may take long!
#'
#' vars <- ecotrends::getVariables(vars = c("tmin", "tmax", "ppt", "pet", "ws"),
#' years = 1981:1990, region = terra::ext(-11, -4, 37, 45), file = paste0(tempdir(), "/variables"))
#'
#' # tempdir() is here to comply with CRAN policy, but you should normally
#' # use a directory that you can access again when reopening R
#' # to avoid downloading the variables again every time
#'
#' names(vars)
#'
#' terra::plot(vars[[1:6]])
#'
#' }
#' }

getVariables <- function(source = "TerraClimate", vars = varsAvailable(source)$vars, years = varsAvailable(source)$years, region = c(-180, 180, -90, 90), file = NULL, verbosity = 2) {

  if (!is.null(file)) {
    if (paste0(file, ".tif") %in% list.files(getwd(), recursive = TRUE, include.dirs = TRUE)) {
      if (verbosity > 0) message("Variables imported from the specified 'file', which already exists in the current working directory. Please provide a different 'file' path/name if this is not what you want.")
      return(terra::rast(paste0(file, ".tif")))
    }

    if (!(dirname(file) %in% list.files(getwd(), include.dirs = TRUE))) {
      dir.create(dirname(file), recursive = TRUE)
    }
  }

  rast_n <- length(vars) * length(years)
  rasts <- vector("list", length = rast_n)
  rast_count <- 0

  if (source == "TerraClimate") {
    for (v in 1:length(vars))  for (y in 1:length(years)) {
      rast_count <- rast_count + 1
      # url <- paste0("http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/data/TerraClimate_", vars[v], "_", years[y], ".nc")
      url <- paste0("https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_", vars[v], "_", years[y], ".nc")  # "Batch Downloads", https://www.climatologylab.org/wget-terraclimate.html


      if (verbosity > 0) {
        message("\ndownloading raster ", rast_count, " of ", rast_n)
        message(url)
      }

      vsi <- ifelse(.Platform$OS.type == "unix", TRUE, FALSE)
      rasts_monthly <- terra::rast(url, vsi = vsi, win = region)

      rasts[[rast_count]] <- terra::app(rasts_monthly, "mean")

      names(rasts)[rast_count] <- paste0(vars[v], "_", years[y])
    }
  }

  rasts <- terra::rast(rasts)  # converts list to multilayer raster

  if (!is.null(file)) {
    terra::writeRaster(rasts, paste0(file, ".tif"), gdal = c("COMPRESS=DEFLATE"))
  }

  return(rasts[[sort(names(rasts))]])  # reordered by year

}
