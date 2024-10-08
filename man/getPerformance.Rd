% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getPerformance.R
\name{getPerformance}
\alias{getPerformance}
\title{Get model performance}
\usage{
getPerformance(
  rasts,
  data,
  metrics = c("AUC", "TSS"),
  plot = TRUE,
  verbosity = 2
)
}
\arguments{
\item{rasts}{multi-layer SpatRaster with the output of \code{\link[=getPredictions]{getPredictions()}}}

\item{data}{data.frame \verb{$data} output of \code{\link[=getModels]{getModels()}}}

\item{metrics}{character vector with the metrics to compute. Can be any subset of c("AUC", "TSS") -- the latter is computed at its optimal threshold. The default is both}

\item{plot}{logical value indicating whether plots should also be produced to illustrate the performance metrics}

\item{verbosity}{integer value indicating the amount of messages to display. The default is 2, for the maximum number of messages available}
}
\description{
Get model performance
}
