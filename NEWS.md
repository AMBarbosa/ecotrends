# ecotrends 0.17


-   getPerformance()

    -   implemented output for replicates (still test performance only)



# ecotrends 0.16


-   getPerformance()

    -   added pbg = TRUE to modEvA functions (requires modEvA >= 3.20)
    -   'plot' default changed to FALSE, as it can be slow for large datasets
    -   started implementing for models with replicates
    -   name of first column of output changed to 'model' rather than 'year', to accomodate replicates



# ecotrends 0.15

-   getPredictions()

    -   implemented for models with replicates



# ecotrends 0.14

-   getModels()

    -   added 'bias' argument (requires fuzzySim >= 4.25)



# ecotrends 0.13

-   getModels()

    -   integrated test + nreps arguments in output 'data'
    -   named list of replicate models



# ecotrends 0.12

-   getModels()

    -   implemented 'test' and 'nreps' arguments in output 'models'
    -   help file mentions that constant variables and different collinearity structures may produce models with different sets of variables among years


-   getPredictions()

    -   currently stops if input 'mods' has replicates



# ecotrends 0.11

-   getModels()

    -    messages saying which variables removed by collinear()
    -    constants checked before (rather than after) collin
    -    added drop=FALSE to fix error when only one selected predictor



# ecotrends 0.10

-   getModels()

    -    improved code to check 'region'


-   README

    -    some more additions for improved clarity



# ecotrends 0.9

-   getTrend()

    -    warning if no values produced due to small sample size
    -    'occs' can be of class 'SpatVector' or 'sf', in which case they aren't converted to data.frame and their CRS is taken
    -    'occs' projected (with message) if not same CRS as 'rasts'


-   README

    -    some additions for improved clarity



# ecotrends 0.8

-   getModels()

    -    drop non-varying predictors (with message) to avoid maxnet() error
    -    message if n pixels < nbg


-   getPredictions()

    -   'data' CRS set to the same as 'rasts', to avoid warning "[mask] CRS do not match"
    -    added bibliographic reference for type="cloglog" recommended default


-   getRegion()

    -   removed in favour of a more complete version which was already being programmed in package {fuzzySim}
    
    

# ecotrends 0.7

-   getModels()

    -   warning if input 'rasts' is not SpatRaster, which will work here but fail elsewhere
    
    

# ecotrends 0.6

-   getPerformance()
    
    -   new function


-   getModels()

    -   output now includes three elements: $models, $replicates, $data (needed for getPerformance)

    
-   getTrend()

    -    added arguments 'file', 'verbosity'


-   getVariables(), getModels(), getPredictions(), getTrend(), README

    -   implemented 'file' including a folder path, e.g. "outputs/models"
    -   folder created if not in getwd()
    

-   all functions
    
    -   replaced instances of @import with @importFrom in roxygen skeleton



# ecotrends 0.5

-   getModels()

    -   added argument 'seed = 1' for the background sample
    -   added arguments 'maxcor' and 'maxvif' to pass to collinear::collinear()
    -   added argument 'classes' to pass to maxnet::maxnet.formula()
    -   added argument 'regmult' to pass to maxnet::maxnet()
    -   default 'nreps' currently 0
    -   added argument 'test = 0.2' for the test data proportion [STILL PENDING IMPLEMENTATION]
    
    
-   getPredictions()

    -   added arguments 'clamp' and 'type' to pass to maxnet::predict()



# ecotrends 0.4

-   getVariables()

    -   changed url, following TerraClimate Batch Downloads instructions (https://www.climatologylab.org/wget-terraclimate.html)
    -   set vsi=FALSE if not on unix platform, to prevent download fail
    

-   getVariables(), getModels(), getPredictions()

    -   object imported from 'file', if it exists in getwd()



# ecotrends 0.3

-   getTrend()

    -   dealt with NA pixels to avoid numerous Kendall::MannKendall() warnings (thanks to Spacedman at https://gis.stackexchange.com/a/464198)
    -   bonus: increased efficiency, as mannkendall outputs an unlisted vector (still thanks to Spacedman at https://gis.stackexchange.com/a/464198)



# ecotrends 0.2

-   getPredictions()

    -   added argument 'region' (to get predictions only within modelled polygon)


-   getTrend()

    -   added argument 'occs' (to get trend only within presence pixels)
    -   added Mann-Kendall outputs besides tau: p_value, S, S_variance



# ecotrends 0.1

-   Added the following package functions, together with documentation and users guide:

    -   getRegion()
    -   varsAvailable()
    -   getVariables()
    -   pixelArea()
    -   getModels()
    -   getPredictions()
    -   getTrend()



# ecotrends 0.0.0.9000

-   Added a `NEWS.md` file to track changes to the package.
