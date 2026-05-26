%% ========================================================================
%  Rice Typology Refinement and Reclassification Framework
%  ------------------------------------------------------------------------
%
%  Purpose
%  ------------------------------------------------------------------------
%  This script refines and harmonizes a regional rice typology dataset for
%  South Asia using:
%
%      1. Rice mask consistency checks
%      2. Nearest-neighbour gap filling
%      3. Country-specific corrections
%      4. Deepwater rice preservation logic
%      5. Soil and topography-based reclassification
%      6. Irrigated upland/lowland separation
%
%  The workflow is designed for:
%
%      - Climate adaptation studies
%      - Crop systems modelling
%      - Regional rice typology mapping
%      - DSSAT / APSIM / InfoCrop applications
%      - Risk and vulnerability assessments
%
%  ------------------------------------------------------------------------
%  Developed By
%  ------------------------------------------------------------------------
%      Dr. Anasuya Barik
%      Borlaug Institute for South Asia (BISA)
%
%  ------------------------------------------------------------------------
%  Required Inputs
%  ------------------------------------------------------------------------
%      1. Rice typology raster
%      2. Rice mask raster
%      3. Soil classification raster
%      4. Topography classification raster
%      5. South Asia country shapefile
%
%  ------------------------------------------------------------------------
%  Expected Variables
%  ------------------------------------------------------------------------
%      topo   : Topography classification raster
%      soil   : Soil texture classification raster
%
%  ------------------------------------------------------------------------
%  Typology Class Assumptions
%  ------------------------------------------------------------------------
%      Original Typology:
%
%          1 = Irrigated Rice
%          2 = Rainfed Rice
%          3 = Deepwater Rice
%
%      Final Refined Typology:
%
%          1 = Irrigated Upland
%          2 = Irrigated Lowland
%          3 = Rainfed Upland
%          4 = Rainfed Lowland
%          5 = Deepwater Rice
%
%  ------------------------------------------------------------------------
%  Environmental Classification Assumptions
%  ------------------------------------------------------------------------
%
%      Topography Classes:
%          1 = Coastal
%          2 = Plains
%          3 = Low Hills
%          4 = Mid/High Hills
%
%      Soil Classes:
%          1 = Very Light
%          2 = Light
%          3 = Medium
%          4 = Heavy
%
%  ------------------------------------------------------------------------
%  Notes for Reuse
%  ------------------------------------------------------------------------
%
%      - Update all input/output file paths.
%      - Update class definitions if typology differs.
%      - Update country correction logic if required.
%      - Update topo/soil thresholds for other crops.
%
%  ------------------------------------------------------------------------
%  MATLAB Toolboxes Required
%  ------------------------------------------------------------------------
%
%      - Mapping Toolbox
%      - Statistics and Machine Learning Toolbox
%
%  ========================================================================
%  ------------------------------------------------------------------------
%  Source Dataset
%  ------------------------------------------------------------------------
%
%  The original rice typology layer used in this workflow was derived from:
%
%      Gumma, M. K., Nelson, A., Thenkabail, P. S., &
%      Singh, A. N. (2011).
%
%      Mapping rice areas of South Asia using MODIS multitemporal data.
%
%      Journal of Applied Remote Sensing, 5(1), 053547.
%
%      https://doi.org/10.1117/1.3619838
%
%  The original dataset was subsequently refined in this workflow using:
%
%      - Rice mask consistency checks
%      - Spatial nearest-neighbour interpolation
%      - Country-specific corrections
%      - Soil and topography-based reclassification
%      - Irrigated upland/lowland separation logic
%
%  ------------------------------------------------------------------------

%% ========================================================================
%% INITIALIZATION
%% ========================================================================

clear;
clc;
close all;


%% ========================================================================
%% LOAD SOUTH ASIA SHAPEFILE
%% ========================================================================

S = shaperead( ...
    'F:\Data\Shapefiles_SA\SA-CNTRY.shp', ...
    'UseGeoCoords', true);


%% ========================================================================
%% DEFINE SPATIAL GRID
%  ------------------------------------------------------------------------
%  Grid corresponds to 0.05° South Asia domain.
%% ========================================================================

lon = 60.0250:0.05:100.0250;
lat = -0.9750:0.05:39.0250;

[X, Y] = meshgrid(lon, lat);


%% ========================================================================
%% LOAD ORIGINAL RICE TYPOLOGY
%  ------------------------------------------------------------------------
%  Original typology raster:
%
%      1 = Irrigated Rice
%      2 = Rainfed Rice
%      3 = Deepwater Rice
%
%  Non-positive values are treated as missing.
%% ========================================================================

aa = flipud(imread( ...
    'E:\CROPS_HEV_06072024\Adaptation\generic layers\rice_typology_murli.tif'));

rice_typology = nan(801,801);

rice_typology(1:800,1:800) = aa;

rice_typology(rice_typology <= 0) = NaN;


%% ========================================================================
%% LOAD RICE MASK
%  ------------------------------------------------------------------------
%  Rice mask identifies all rice-growing pixels.
%% ========================================================================

[A, R] = readgeoraster( ...
    'F:\SACropMask_latest\AllPix\Mask_Rice801.tif', ...
    "OutputType","double");

rice_mask = nan(801,801);

rice_mask(1:801,1:801) = flipud(A);

rice_mask(rice_mask < 0) = NaN;


%% ========================================================================
%% VISUALIZE ORIGINAL TYPOLOGY
%% ========================================================================

figure

pcolor(lon, lat, rice_typology)

shading flat

colorbar

title('Original Rice Typology')

set(gca,'FontName','Times New Roman','FontSize',14)


%% ========================================================================
%% IDENTIFY TYPOLOGY GAPS INSIDE RICE AREAS
%  ------------------------------------------------------------------------
%  Goal:
%  Fill rice pixels that are present in the rice mask but missing in the
%  typology raster.
%
%  Method:
%  Nearest-neighbour assignment using valid surrounding typology pixels.
%% ========================================================================

mismatch_pixels = isnan(rice_typology) & (rice_mask == 1);

mismatch_matrix = double(mismatch_pixels);

mismatch_matrix(mismatch_matrix == 0) = 0;
mismatch_matrix(mismatch_matrix == 1) = 1;


%% ========================================================================
%% EXTRACT MISSING PIXEL COORDINATES
%% ========================================================================

[row_mismatch, col_mismatch] = find(mismatch_pixels);


%% ========================================================================
%% IDENTIFY VALID TYPOLOGY PIXELS
%% ========================================================================

[valid_rows, valid_cols] = find(~isnan(rice_typology));

valid_points = [valid_rows, valid_cols];

mismatch_points = [row_mismatch, col_mismatch];


%% ========================================================================
%% NEAREST-NEIGHBOUR GAP FILLING
%  ------------------------------------------------------------------------
%  Each missing rice pixel receives the class of the nearest valid
%  typology pixel.
%% ========================================================================

nearest_indices = knnsearch(valid_points, mismatch_points);

for i = 1:length(row_mismatch)

    row = row_mismatch(i);
    col = col_mismatch(i);

    nearest_row = valid_rows(nearest_indices(i));
    nearest_col = valid_cols(nearest_indices(i));

    rice_typology(row, col) = ...
        rice_typology(nearest_row, nearest_col);

end


%% ========================================================================
%% COUNTRY-SPECIFIC CORRECTION
%  ------------------------------------------------------------------------
%  Pakistan and Afghanistan correction:
%
%  Rice-growing pixels inside these countries are assigned to Class 1.
%
%  This correction was introduced to resolve typology inconsistencies in
%  border regions where rice presence existed but classification quality
%  was poor.
%% ========================================================================

for i = 1:length(S)

    if strcmp(S(i).name, 'Pakistan') || ...
       strcmp(S(i).name, 'Afghanistan')

        Lat = S(i).Lat';
        Lon = S(i).Lon;

        [xPixel, yPixel] = meshgrid(lon, lat);

        inPolygon = inpolygon(xPixel, yPixel, Lon, Lat);

        rice_pixels = rice_mask == 1;

        rice_typology(inPolygon & rice_pixels) = 1;

    end
end


%% ========================================================================
%% VISUALIZE TYPOLOGY AFTER COUNTRY CORRECTION
%% ========================================================================

figure

pcolor(lon, lat, rice_typology)

shading interp

colorbar

title('Rice Typology after Country Correction')

set(gca,'FontName','Times New Roman','FontSize',14)


%% ========================================================================
%% PRESERVE DEEPWATER RICE CLASS
%  ------------------------------------------------------------------------
%  Goal:
%  Prevent artificial expansion of Deepwater Rice during interpolation.
%
%  Logic:
%      - Compare original and updated typology maps.
%      - Identify newly created Class 3 pixels.
%      - Reassign them using nearest non-Class-3 neighbour.
%% ========================================================================

rice_typology_new = rice_typology;


%% Reload original typology

aa = flipud(imread( ...
    'E:\CROPS_HEV_06072024\Adaptation\generic layers\rice_typology_murli.tif'));

rice_typology_old = nan(801,801);

rice_typology_old(1:800,1:800) = aa;

rice_typology_old(rice_typology_old <= 0) = NaN;


%% Identify artificial Class 3 expansion

class3_new = (rice_typology_new == 3);

class3_old = (rice_typology_old == 3);

class3_to_reclassify = class3_new & ~class3_old;


%% Coordinates requiring reassignment

[row_reclass, col_reclass] = find(class3_to_reclassify);


%% Identify valid non-Class-3 pixels

[valid_rows, valid_cols] = find(rice_typology_new ~= 3);

valid_points = [valid_rows, valid_cols];

reclass_points = [row_reclass, col_reclass];


%% Nearest-neighbour reassignment

nearest_indices = knnsearch(valid_points, reclass_points);

for i = 1:length(row_reclass)

    row = row_reclass(i);
    col = col_reclass(i);

    nearest_row = valid_rows(nearest_indices(i));
    nearest_col = valid_cols(nearest_indices(i));

    rice_typology_new(row, col) = ...
        rice_typology_new(nearest_row, nearest_col);

end


%% ========================================================================
%% SOIL AND TOPOGRAPHY-BASED RECLASSIFICATION
%  ------------------------------------------------------------------------
%  Rainfed Rice (Class 2) is separated into:
%
%      2 = Rainfed Upland
%      3 = Rainfed Lowland
%
%  Environmental Rules:
%
%      Upland:
%          topo = 3 or 4
%          soil = 1 or 2
%
%      Lowland:
%          topo = 1 or 2
%          soil = 3 or 4
%
%  Upland receives priority when both conditions overlap.
%% ========================================================================

updated_rice_typology = rice_typology_new;


%% Preserve irrigated rice

updated_rice_typology(rice_typology_new == 1) = 1;


%% Preserve deepwater rice

updated_rice_typology(rice_typology_new == 3) = 4;


%% Identify rainfed rice

isClass2 = rice_typology == 2;


%% Define lowland conditions

isLowlandByTopography = (topo == 1 | topo == 2);

isLowlandBySoil = (soil == 3 | soil == 4);

isLowland = ...
    isLowlandByTopography | ...
    isLowlandBySoil;


%% Define upland conditions

isUplandByTopography = (topo == 3 | topo == 4);

isUplandBySoil = (soil == 1 | soil == 2);

isUpland = ...
    isUplandByTopography | ...
    isUplandBySoil;


%% Apply upland priority classification

updated_rice_typology(isClass2 & isUpland) = 2;

updated_rice_typology( ...
    isClass2 & ~isUpland & isLowland) = 3;


%% ========================================================================
%% VISUALIZE UPDATED TYPOLOGY
%% ========================================================================

figure

pcolor(lon, lat, updated_rice_typology)

shading interp

colorbar

title('Rainfed Rice Reclassification')

set(gca,'FontName','Times New Roman','FontSize',14)


%% ========================================================================
%% EXPORT INTERMEDIATE TYPOLOGY
%% ========================================================================

R = georasterref( ...
    'RasterSize', size(updated_rice_typology), ...
    'LatitudeLimits', [-0.9750 39.0250], ...
    'LongitudeLimits', [60.0250 100.0250]);

geotiffwrite( ...
    'E:\CROPS_HEV_06072024\Adaptation\generic layers\rice_typology_new_soil_topo_logic_lowland_priority.tif', ...
    updated_rice_typology, ...
    R);


%% ========================================================================
%% SPLIT IRRIGATED RICE INTO UPLAND AND LOWLAND
%  ------------------------------------------------------------------------
%  Final irrigated rice split:
%
%      1 = Irrigated Upland
%      2 = Irrigated Lowland
%
%  Existing rainfed and deepwater classes are shifted upward:
%
%      Old 2 -> 3
%      Old 3 -> 4
%      Old 4 -> 5
%
%  This section uses:
%
%      - Upland priority
%      - Soil + topography conditions
%% ========================================================================

updated_rice_typology = flipud(imread( ...
    'E:\CROPS_HEV_06072024\Adaptation\Rice_typology_291024.tif'));


%% Reassign class numbering

updated_rice_typology(updated_rice_typology == 4) = 5;

updated_rice_typology(updated_rice_typology == 3) = 4;

updated_rice_typology(updated_rice_typology == 2) = 3;


%% Define upland and lowland conditions

upland_condition = ...
    (topo == 3 | topo == 4) | ...
    (soil == 1 | soil == 2);

lowland_condition = ...
    (topo == 1 | topo == 2) | ...
    (soil == 3 | soil == 4);


%% Identify irrigated pixels

class1_mask = (updated_rice_typology == 1);


%% Upland priority split

upland_mask = ...
    class1_mask & upland_condition;

lowland_mask = ...
    class1_mask & ...
    lowland_condition & ...
    ~upland_condition;


%% Apply final irrigated split

updated_rice_typology(upland_mask) = 1;

updated_rice_typology(lowland_mask) = 2;


%% ========================================================================
%% VISUALIZE FINAL TYPOLOGY
%% ========================================================================

figure

pcolor(lon, lat, updated_rice_typology)

shading flat

colorbar

title('Final Rice Typology')

set(gca,'FontName','Times New Roman','FontSize',14)


%% ========================================================================
%% EXPORT FINAL TYPOLOGY
%% ========================================================================

R = georasterref( ...
    'RasterSize', size(updated_rice_typology), ...
    'LatitudeLimits', [-0.9750 39.0250], ...
    'LongitudeLimits', [60.0250 100.0250]);

geotiffwrite( ...
    'E:\CROPS_HEV_06072024\Adaptation\generic layers\rice_typology_Irri_RF_UL_LL.tif', ...
    updated_rice_typology, ...
    R);


%% ========================================================================
%% END OF SCRIPT
%% ========================================================================