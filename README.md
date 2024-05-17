
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ecotrends

<!-- badges: start -->
<!-- badges: end -->

The goal of `ecotrends` is to compute a time series of ecological niche
models, using species occurrence data and environmental variables, and
then analyse the trends in environmental suitability over time.

## Installation

You can install `ecotrends` from GitHub with:

``` r
devtools::install_github("AMBarbosa/ecotrends")
```

## Users manual

You’ll need some species presence coordinates. The code below downloads
some example occurrence data from GBIF, and then performs **just a basic
cleaning**:

``` r
library(terra)
library(geodata)
library(fuzzySim)

occ_raw <- geodata::sp_occurrence(genus = "Chioglossa", species = "lusitanica", fixnames = FALSE)

occ_clean <- fuzzySim::cleanCoords(occ_raw, coord.cols = c("decimalLongitude", "decimalLatitude"), uncert.col = "coordinateUncertaintyInMeters", uncert.limit = 10000, year.col = "year", year.min = 1970, abs.col = "occurrenceStatus", plot = TRUE)

occ_coords <- occ_clean[ , c("decimalLongitude", "decimalLatitude")]
```

You should also delimit a region for modelling. You can provide your own
spatial extent or polygon – e.g., a biogeographical region within which
your species was more or less evenly surveyed. Another option is to use
the `getRegion` function to compute a “reasonably sized” region around
the existing occurrences:

``` r
library(ecotrends)

reg <- ecotrends::getRegion(occs = occ_coords)

plot(reg, col = "wheat")
points(occ_coords)
```

Now let’s download some variables with which to build a yearly time
series of ecological niche models for this species in this region. You
can first use the `varsAvailable` function to check which variables are
available, and then the `getVariables` function to download the ones you
choose. Mind that the download may take a long time:

``` r
ecotrends::varsAvailable()

vars <- ecotrends::getVariables(vars = c("tmin", "tmax", "ppt", "pet", "ws"), years = 1990:1981, region = reg, file = "variable_rasters")

names(vars)
plot(vars[[1]])
plot(vars[[length(vars)]])
```

The variable raster layers have a nominal pixel size at the Equator, but
actual pixel sizes vary widely across latitudes. So, let’s check the
average pixel size in our study region, and the spatial uncertainties of
our occurrence coordinates:

``` r
sqrt(ecotrends::pixelArea(vars, unit = "m"))

summary(occ_clean$coordinateUncertaintyInMeters, na.rm = TRUE)
```

You can see there are several occurrence points with spatial uncertainty
larger than the pixel size, so it might be a good idea to aggregate the
variable layers:

``` r
vars_agg <- terra::aggregate(vars, fact = 2)

sqrt(ecotrends::pixelArea(vars, unit = "m"))
```

This is much closer to the spatial resolution of many of the species
occurrences. You can now compute models with these occurrences and
variables:

``` r
mods <- ecotrends::getModels(occ_coords, vars_agg, region = reg, nbg = 10000, nreps = 1, collin = TRUE, file = "models")
```

Let’s now get the model predictions for each of the provided years:

``` r
preds <- ecotrends::getPredictions(vars_agg, mods, file = "predictions")

plot(preds)
```

From this, you can use the `getTrend` function to compute the trend:

``` r
# [UNDER CONSTRUCTION]
```
