
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ecotrends

<!-- badges: start -->
<!-- badges: end -->

The goal of `ecotrends` is to **compute a time series of ecological
niche models**, using species occurrence data and environmental
variables, and then map the existence and direction of **linear temporal
trends in environmental suitability**, as in [Arenas-Castro & Sillero
(2021)](https://doi.org/10.1016/j.scitotenv.2021.147172).

This package is part of the [MontObEO
project](https://montobeo.wordpress.com/).

## Installation

You can install `ecotrends` from GitHub with:

``` r
devtools::install_github("AMBarbosa/ecotrends")
```

## Usage

You’ll need some **species presence coordinates**. The code below
downloads some example occurrence data from GBIF, and then performs
**just a basic automatic cleaning**:

``` r
library(geodata)
library(fuzzySim)

occ_raw <- geodata::sp_occurrence(genus = "Chioglossa", 
                                  species = "lusitanica", 
                                  fixnames = FALSE)

occ_clean <- fuzzySim::cleanCoords(data = occ_raw, 
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

reg <- ecotrends::getRegion(occs = occ_coords,
                            type = "mean")

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
                                years = 1981:1990, 
                                region = reg, 
                                file = "outputs/variables")

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
larger than our pixel size, so it might be a good idea to **coarsen the
spatial resolution** of the variable layers:

``` r
vars_agg <- terra::aggregate(vars, 
                             fact = 2)

sqrt(ecotrends::pixelArea(vars_agg))
```

This is much closer to the spatial resolution of many of the species
occurrences. We can now **compute yearly ecological niche models** with
these occurrences and variables, optionally saving the results to a
file:

``` r
mods <- ecotrends::getModels(occs = occ_coords, 
                             rasts = vars_agg, 
                             region = reg,
                             collin = TRUE, 
                             maxcor = 0.75,
                             maxvif = 5,
                             classes = "default", 
                             regmult = 1, 
                             file = "outputs/models")
```

Let’s now **compute the model predictions** for each year, optionally
delimiting them to the modelled region, and optionally saving results to
a file:

``` r
preds <- ecotrends::getPredictions(rasts = vars_agg, 
                                   mods = mods$models, 
                                   region = reg,
                                   type = "cloglog",
                                   clamp = TRUE,
                                   file = "outputs/predictions")

plot(preds, range = c(0, 1))
```

You can **evaluate the fit** of these predictions to the model training
data:

``` r
perf <- ecotrends::getPerformance(rasts = preds, 
                                  data = mods$data,
                                  plot = TRUE)

perf
```

Finally, you can use the `getTrend` function to **check for a linear
(monotonic) temporal trend in suitability** in each pixel, optionally
providing your occurrence coordinates if you want the results to be
restricted to the pixels that overlap them:

``` r
trend <- ecotrends::getTrend(rasts = preds,
                             occs = occ_coords,
                             alpha = 0.05,
                             full = TRUE,
                             file = "outputs/trend")

plot(trend, 
     col = hcl.colors(100, "spectral"))
```

See `?Kendall::MannKendall` (including the *Value* section) to know more
about these statistics. If you want just the first raster layer (with
the significant Tau values), set `full = FALSE` above. Positive Tau
values indicate increasing suitability, and negative values indicate
decreasing suitability over time. Pixels with no value have no
significant linear trend (or no occurrence points, if `occs` are
provided).
