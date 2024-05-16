#' downloadVars
#'
#' @param source source to import the variables form, e.g. "TerraClimate" or "CHELSA"; currently only "TerraClimate" is implemented
#' @param vars character vector of the names of the variables to be imported
#' @param region optional length-four numeric vector, SpatExtent or SpatVector polygon delimiting the region of the world for which the variables should be downloaded. See ?getRegion for suggestions. The larger the region, the slower the download.
#' @param years year range to get the variables from; default 1979:2013
#'
#' @return
#' @export
#'
#' @examples

downloadVars <- function(source = "TerraClimate", vars = varsAvailable(source), region = c(-180, 180, -90, 90), years = 1979:2013) {

  e <- terra::ext(region)

  rast_n <- length(vars) * length(years)
  rasts <- vector("list", length = rast_n)
  rast_count <- 0

  for (v in 1:length(vars))  for (y in 1:length(years)) {
    rast_count <- rast_count + 1
    message("\ndownloading raster ", rast_count, " of ", rast_n)
    url <- paste0("http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/data/TerraClimate_", vars[v], "_", years[y], ".nc")
    message(url)

    rasts_monthly <- terra::rast(url, vsi = TRUE, win = e)

    rasts[[rast_count]] <- terra::app(rasts_monthly, "mean")

    names(rasts)[rast_count] <- paste0(vars[v], "_", years[y])
  }

  return(terra::rast(rasts))
}
