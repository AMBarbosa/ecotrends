# ecotrends 0.4  [ PENDING! ]

-   getModels()

    -   add argument 'seed = 1' for the background sample
    -   add argument 'reps = 10' with samples for train and test
    -   report model evaluation (AUC, maxTSS) across the test data samples
    -   add arguments with parameters for maxnet::maxnet()
    -   add arguments with parameters for collinear::collinear()


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
