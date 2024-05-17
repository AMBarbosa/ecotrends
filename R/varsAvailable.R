#' varsAvailable
#'
#' @param source the source database where to check available variables. By default (i.e. if left NULL), all implemented sources are used. Currently "TerraClimate" is the only implemented source.
#'
#' @return character vector
#' @export
#'
#' @examples
#' varsAvailable()

varsAvailable <- function(source = NULL) {

  if (is.null(source))  source <- c("TerraClimate")  # more to be added later

  out <- list(TerraClimate = vector("list", length = 2))

  names(out$TerraClimate) <- c("vars", "years")

  out$TerraClimate$vars <- c("ws", "vpd", "vap", "tmin", "tmax", "swe", "srad", "soil", "g", "ppt", "pet", "def", "aet", "PDSI")

  out$TerraClimate$years <- 1958:2020

  return(out)
}
