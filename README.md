
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ecotrends

<!-- badges: start -->
<!-- badges: end -->

The goal of `ecotrends` is to **compute a time series of ecological
niche models**, using species occurrence data and environmental
variables, and then analyse the **trend in environmental suitability
over time**, as in [Arenas-Castro & Sillero
(2021)](https://doi.org/10.1016/j.scitotenv.2021.147172).

This package is part of the [MontObEO
project](https://montobeo.wordpress.com/).

## Installation

You can install `ecotrends` from GitHub with:

``` r
devtools::install_github("AMBarbosa/ecotrends")
```

## Users manual

You’ll need some **species presence coordinates**. The code below
downloads some example occurrence data from GBIF, and then performs
**just a basic automatic cleaning**:

``` r
library(geodata)
library(fuzzySim)

occ_raw <- geodata::sp_occurrence(genus = "Chioglossa", 
                                  species = "lusitanica", 
                                  fixnames = FALSE)

occ_clean <- fuzzySim::cleanCoords(occ_raw, 
                                   coord.cols = c("decimalLongitude", "decimalLatitude"), 
                                   uncert.col = "coordinateUncertaintyInMeters",
                                   uncert.limit = 10000, 
                                   year.col = "year", 
                                   year.min = 1970, 
                                   abs.col = "occurrenceStatus", 
                                   plot = FALSE)

occ_coords <- occ_clean[ , c("decimalLongitude", "decimalLatitude")]
```

You should also **delimit a region for modelling**. You can provide your
own spatial extent or polygon – e.g., a biogeographical region within
which your species was more or less evenly surveyed. Alternatively or
additionally, you can use the `getRegion` function to compute a
“reasonably sized” area around your species occurrences:

``` r
library(ecotrends)

reg <- ecotrends::getRegion(occs = occ_coords)

plot(reg, col = "wheat")
points(occ_coords, cex = 0.3)
```

Now let’s **download some variables** with which to build a **yearly
time series** of ecological niche models for this species in this
region. You can first use the `varsAvailable` function to check which
variables and years are available, and then the `getVariables` function
to download the ones you choose. Mind that the download may take a long
time:

``` r
ecotrends::varsAvailable()

vars <- ecotrends::getVariables(vars = c("tmin", "tmax", "ppt", "pet", "ws"), 
                                years = 1990:1981, 
                                region = reg, 
                                file = "variable_rasters")

# or, after you've downloaded the variables with the above 'file' argument:
# vars <- terra::rast("variable_rasters.tif")

names(vars)
plot(vars[[1:6]])
```

The variable raster layers have a given pixel size *at the Equator*, but
actual pixel sizes can vary widely across latitudes. So, let’s **check
the average pixel size in our study region**, as well as the spatial
uncertainty values of our occurrence coordinates:

``` r
sqrt(ecotrends::pixelArea(vars))

summary(occ_clean$coordinateUncertaintyInMeters, na.rm = TRUE)
```

You can see there are several occurrence points with spatial uncertainty
larger than the pixel size, so it might be a good idea to **coarsen the
spatial resolution** of the variable layers:

``` r
vars_agg <- terra::aggregate(vars, fact = 2)

sqrt(ecotrends::pixelArea(vars_agg))
```

This is much closer to the spatial resolution of many of the species
occurrences. We can now **compute yearly ecological niche models** with
these occurrences and variables:

``` r
mods <- ecotrends::getModels(occ_coords, 
                             vars_agg, 
                             region = reg, 
                             collin = TRUE, 
                             file = "models")
```

Let’s now **compute the model predictions** for each year:

``` r
preds <- ecotrends::getPredictions(vars_agg, 
                                   mods, 
                                   file = "predictions")

plot(preds)
```

Finally, you can use the `getTrend` function to **check for a monotonic
temporal trend in suitability** in each pixel:

``` r
trend <- getTrend(preds, 
                  alpha = 0.05)

plot(trend, 
     col = hcl.colors(100, "spectral"), 
     main = "Suitability trend")
```

Positive values indicate increasing suitability, and negative values
indicate decreasing suitability over time. Pixels with no value have no
significant trend.
