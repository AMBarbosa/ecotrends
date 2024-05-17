#' Get variables
#'
#' @param source source to import the raster variables from, e.g. "TerraClimate" (currently the only one implemented)
#' @param vars character vector of the names of the variables to be imported. Run varsAvailable() for options. The default is to download all available variables from the specified 'source'. Note that the download can take a long time, especially for many variables, long series of years, and/or large regions.
#' @param years year range to get the variables from (e.g. 1979:2013). Note that the download can take a long time for long series of years.
#' @param region optional length-four numeric vector (xmin, xmax, ymin, ymax geodetic coordinates in degrees), SpatExtent or SpatVector polygon delimiting the region of the world for which the variables should be downloaded. See ?getRegion for suggestions. The larger the region, the slower the download.
#' @param file optional file name (including the path, not including the filename extension) if you want the downloaded rasters to be saved on disk, in which case they are saved as a compressed multi-layer GeoTIFF
#'
#' @return multi-layer SpatRaster
#' @export
#'
#' @examples

getVariables <- function(source = "TerraClimate", vars = varsAvailable(source)$vars, years = varsAvailable(source)$years, region = c(-180, 180, -90, 90), file = NULL) {

  if (!is.null(file) && !exists(dirname(file))) {
    dir.create(dirname(file))
  }

  rast_n <- length(vars) * length(years)
  rasts <- vector("list", length = rast_n)
  rast_count <- 0

  if (source == "TerraClimate") {
    for (v in 1:length(vars))  for (y in 1:length(years)) {
      rast_count <- rast_count + 1
      message("\ndownloading raster ", rast_count, " of ", rast_n)
      url <- paste0("http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/data/TerraClimate_", vars[v], "_", years[y], ".nc")
      message(url)

      rasts_monthly <- terra::rast(url, vsi = TRUE, win = region)

      rasts[[rast_count]] <- terra::app(rasts_monthly, "mean")

      names(rasts)[rast_count] <- paste0(vars[v], "_", years[y])
    }
  }

  rasts <- terra::rast(rasts)  # converts list to multilayer raster

  if (!is.null(file)) {
    terra::writeRaster(rasts, filename = paste0(file, ".tif"), gdal = c("COMPRESS=DEFLATE"))
  }

  return(rasts)
}
