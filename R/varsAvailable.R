#' varsAvailable
#'
#' @param source currently only "TerraClimate" is implemented
#'
#' @return character vector
#' @export
#'
#' @examples
#' varsAvailable("TerraClimate")

varsAvailable <- function(source = "TerraClimate") {

  stopifnot(source == "TerraClimate")  # while no more sources are implemented

  if (source == "TerraClimate") {
    return(c("ws", "vpd", "vap", "tmin", "tmax", "swe", "srad", "soil", "g", "ppt", "pet", "def", "aet", "PDSI"))

  } else if (source == "CHELSA") {
    stop("sorry, 'CHELSA' not yet implemented")

  } else stop ("invalid 'source' argument")
}
