## Code 1: Crop Management Data Aggregation Framework (0.05° → 0.5°)
### Convert_005_05_management_areaWeighted_upload.m

 Purpose: This script aggregates high-resolution crop management datasets (0.05 degree spatial resolution) to 0.5 degree grids using:
 
 1. Area-weighted mean aggregation for
    1. Irrigation fraction
    2. Planting dates
    3. Fertilizer application rates
2. Sum aggregation for - Crop harvested area

## Code 2: Rice typology
### Rice_typology_upload.m

This code refines and harmonizes a regional rice typology dataset for South Asia by combining an existing MODIS-based rice classification with rice masks, soil information, and topographic data. The workflow first identifies missing rice typology pixels within rice-growing areas and fills them using nearest-neighbour interpolation. It then applies country-specific corrections for Pakistan and Afghanistan and preserves deepwater rice systems during reclassification. Finally, the script separates rice systems into irrigated upland, irrigated lowland, rainfed upland, rainfed lowland, and deepwater categories using rule-based soil and terrain criteria. The resulting georeferenced outputs are designed for climate impact studies, crop modelling, adaptation assessments, and regional agricultural analysis.

## Code 3: Nitrogen downscaling
### NDownscaleV3.m

This MATLAB code downscales district-level seasonal nitrogen consumption data to grid-level crop-specific nitrogen application rates. District-level seasonal nitrogen consumption was first proportioned according to cropped area to derive crop-wise district nitrogen consumption. Subsequently, nitrogen was spatially allocated to grids using crop masks, crop nitrogen requirements, GPP, soil nitrogen supply, and district-specific upper/lower application limits.
