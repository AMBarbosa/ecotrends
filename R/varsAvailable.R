#' Variables available
#'
#' @param source the source database where to check available variables. By default (i.e. if left NULL), all implemented sources are used. Currently "TerraClimate" (https://www.climatologylab.org/terraclimate.html) is the only implemented source.
#'
#' @return a named nested list with one element per data source, each of which containing two elements: a character vector of the names of the variables available from that source, and an integer vector of the years for which those variables are available.
#' @seealso [getVariables()]
#' @references
#' Abatzoglou, J.T., S.Z. Dobrowski, S.A. Parks, K.C. Hegewisch (2018) Terraclimate, a high-resolution global dataset of monthly climate and climatic water balance from 1958-2015. Scientific Data, 5, Article number: 170191. doi: 10.1038/sdata.2017.191(2018). Database URL: https://www.climatologylab.org/terraclimate.html

#' @author A. Marcia Barbosa
#' @export
#'
#' @examples
#' varsAvailable()

varsAvailable <- function(source = NULL) {

  if (is.null(source))  source <- c("TerraClimate")  # more to be added later

  out <- list(TerraClimate = vector("list", length = 2))  # more to be added

  names(out$TerraClimate) <- c("vars", "years")

  out$TerraClimate$vars <- c("ws", "vpd", "vap", "tmin", "tmax", "swe", "srad", "soil", "g", "ppt", "pet", "def", "aet", "PDSI")

  out$TerraClimate$years <- 1958:2020

  return(out)
}
