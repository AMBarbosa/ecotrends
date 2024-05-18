#' Get variables
#'
#' @description
#' This function downloads a specified time series of variables from a specified environmental data source, optionally (to save download time) within a specified region. Currently "TerraClimate" (Abatzoglou et al., 2018) is the only implemented data source.

#' @param source source to import the raster variables from, e.g. "TerraClimate" (currently the only one implemented)
#' @param vars character vector of the names of the variables to be imported. Run varsAvailable() for options. The default is to download all available variables from the specified 'source'. Note that the download can take a long time, especially for many variables, long series of years, and/or large regions.
#' @param years year range to get the variables from (e.g. 1979:2013). Note that the download can take a long time for long series of years.
#' @param region optional length-four numeric vector (xmin, xmax, ymin, ymax geodetic coordinates in degrees), SpatExtent or SpatVector polygon delimiting the region of the world for which the variables should be downloaded. See ?getRegion for suggestions. The larger the region, the slower the download.
#' @param file optional file name (including the path, not including the filename extension) if you want the downloaded rasters to be saved on disk, in which case they are saved as a compressed multi-layer GeoTIFF
#'
#' @return multi-layer SpatRaster
#' @author A. Marcia Barbosa
#' @seealso [varsAvailable()]
#' @references
#' Abatzoglou, J.T., S.Z. Dobrowski, S.A. Parks, K.C. Hegewisch (2018) Terraclimate, a high-resolution global dataset of monthly climate and climatic water balance from 1958-2015. Scientific Data, 5, Article number: 170191. doi: 10.1038/sdata.2017.191(2018). Database URL: https://www.climatologylab.org/terraclimate.html

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

  return(rasts[[sort(names(rasts))]])
}
