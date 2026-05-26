%% ========================================================================
%  Crop Management Data Aggregation Framework (0.05° → 0.5°)
%  ------------------------------------------------------------------------
%  Purpose:
%  This script aggregates high-resolution crop management datasets
%  (0.05 degree spatial resolution) to 0.5 degree grids using:
%
%     1. Area-weighted mean aggregation for
%        - Irrigation fraction
%        - Planting dates
%        - Fertilizer application rates
%
%     2. Sum aggregation for
%        - Crop harvested area
%
%  The framework is designed for preparing crop management inputs for:
%        - DSSAT, Infocrop, APSIM and other models
%        - ISIMIP-input crop simulations
%        - Regional and global agricultural assessments
%
%  Developed by: Anasuya Barik
%  Affiliation: Borlaug Institute for South Asia (BISA)
%
%  Notes:
%  ------------------------------------------------------------------------
%  1. Crop-specific files can be changed wherever marked as:
%           >>> CHANGE FOR NEW CROP <<<
%
%  2. The current configuration uses:
%           MUST = Mustard
%
%  3. Spatial aggregation factor:
%           10 × 10 pixels
%           (0.05° → 0.5°)
%
%  4. All outputs are GeoTIFF files preserving geographic coordinates.
%
%  5. Ensure Mapping Toolbox is installed for:
%           - readgeoraster
%           - geotiffwrite
%           - shaperead
%           - geoshow
%
%  ------------------------------------------------------------------------
%  Author Contact:
%        Dr Anasuya Barik
%        Borlaug Institute for South Asia (BISA)
%  ========================================================================

%% IRRIGATION AGGREGATION
%  Area-weighted aggregation of irrigation fraction
%  ------------------------------------------------------------------------
%  Logic:
%  Irrigation values are aggregated using crop area as weights so that
%  regions with larger crop area contribute more to the final 0.5° value.
%  ========================================================================

clear; clc;

% -------------------------------------------------------------------------
% Load irrigation raster
% >>> CHANGE FOR NEW CROP <<<
% Replace MUST_IR_V3.tif with crop-specific irrigation raster
% -------------------------------------------------------------------------
[ir, R] = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\CropIRV3\CropIRV3\MUST_IR_V3.tif');

% -------------------------------------------------------------------------
% Load crop area raster
% >>> CHANGE FOR NEW CROP <<<
% Replace MUST_AR_V3.tif with crop-specific harvested area raster
% -------------------------------------------------------------------------
[ar, ~] = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\CropAreaV3\CropAreaV3\MUST_AR_V3.tif');

ir = double(ir);
ar = double(ar);

% Aggregation factor
factor = 10;

% Original raster dimensions
[nr, nc] = size(ir);

% New raster dimensions after aggregation
nr2 = floor(nr / factor);
nc2 = floor(nc / factor);

% Initialize aggregated raster
ir_05 = nan(nr2, nc2);

% Area-weighted aggregation loop
for i = 1:nr2

    for j = 1:nc2

        % Extract 10 × 10 block indices
        r = (i-1)*factor + (1:factor);
        c = (j-1)*factor + (1:factor);

        % Subset irrigation and crop area blocks
        ir_block = ir(r,c);
        ar_block = ar(r,c);

        % Valid crop pixels only
        valid = ar_block > 0 & ...
                ~isnan(ar_block) & ...
                ~isnan(ir_block);

        % Compute weighted mean
        if any(valid(:))

            w = ar_block(valid);   % weights = crop area
            v = ir_block(valid);   % irrigation values

            ir_05(i,j) = sum(v .* w) / sum(w);

        end
    end
end

% Visualize aggregated irrigation
figure
imagesc(ir_05)
colorbar
title('Aggregated Irrigation Fraction')

% Flip raster if required for orientation correction
ir_05_1 = flipud(ir_05);

% Create 0.5° raster reference
R05 = georasterref( ...
    'RasterSize', size(ir_05), ...
    'LatitudeLimits', R.LatitudeLimits, ...
    'LongitudeLimits', R.LongitudeLimits);

% Export GeoTIFF
% >>> CHANGE OUTPUT NAME FOR NEW CROP <<<
geotiffwrite( ...
    'MUST_IR_V3_05deg_weighted.tif', ...
    flipud(ir_05), ...
    R05);


%% PLANTING DATE AGGREGATION
%  Area-weighted aggregation of planting dates
%  ------------------------------------------------------------------------
%  Logic:
%  Planting dates are aggregated using harvested area as weights.
%
%  NOTE:
%  Circular mean is NOT required because planting dates do not cross
%  year boundaries in this dataset.
%  ========================================================================

clear

% -------------------------------------------------------------------------
% Load planting date raster
% >>> CHANGE FOR NEW CROP <<<
% -------------------------------------------------------------------------
[ir, R] = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\PDATE_V3\MUST.tif');

% -------------------------------------------------------------------------
% Load crop area raster
% >>> CHANGE FOR NEW CROP <<<
% -------------------------------------------------------------------------
[ar, ~] = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\CropAreaV3\CropAreaV3\MUST_AR_V3.tif');

ir = double(ir);
ar = double(ar);

factor = 10;

[nr, nc] = size(ir);

nr2 = floor(nr / factor);
nc2 = floor(nc / factor);

ir_05 = nan(nr2, nc2);

% Area-weighted aggregation
for i = 1:nr2

    for j = 1:nc2

        r = (i-1)*factor + (1:factor);
        c = (j-1)*factor + (1:factor);

        ir_block = ir(r,c);
        ar_block = ar(r,c);

        valid = ar_block > 0 & ...
                ~isnan(ar_block) & ...
                ~isnan(ir_block);

        if any(valid(:))

            w = ar_block(valid);
            v = ir_block(valid);

            ir_05(i,j) = sum(v .* w) / sum(w);

        end
    end
end

% Plot
figure
imagesc(ir_05)
colorbar
title('Aggregated Planting Dates')

% Create raster reference
R05 = georasterref( ...
    'RasterSize', size(ir_05), ...
    'LatitudeLimits', R.LatitudeLimits, ...
    'LongitudeLimits', R.LongitudeLimits, ...
    'ColumnsStartFrom','north');

% Export GeoTIFF
% >>> CHANGE OUTPUT NAME FOR NEW CROP <<<
geotiffwrite( ...
    'F:\Climakid\Management_05degree\MUST_PLanting_V3_05deg_weighted.tif', ...
    ir_05, ...
    R05);

%% CROP AREA AGGREGATION
%  Aggregation using SUM
%  ------------------------------------------------------------------------
%  Logic:
%  Crop harvested area should be summed rather than averaged.
%  ========================================================================

clear

% -------------------------------------------------------------------------
% Load crop area raster
% >>> CHANGE FOR NEW CROP <<<
% -------------------------------------------------------------------------
[ar, R] = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\CropAreaV3\CropAreaV3\MUST_AR_V3.tif');

ar = double(ar);

factor = 10;

[nr, nc] = size(ar);

nr2 = floor(nr / factor);
nc2 = floor(nc / factor);

ir_05 = nan(nr2, nc2);

% Area sum aggregation
for i = 1:nr2

    for j = 1:nc2

        r = (i-1)*factor + (1:factor);
        c = (j-1)*factor + (1:factor);

        ar_block = ar(r,c);

        valid = ar_block > 0 & ~isnan(ar_block);

        v = ar_block(valid);

        ir_05(i,j) = sum(v);

    end
end

% Plot
figure
imagesc(ir_05)
colorbar
title('Aggregated Crop Area')

% Create raster reference
R05 = georasterref( ...
    'RasterSize', size(ir_05), ...
    'LatitudeLimits', R.LatitudeLimits, ...
    'LongitudeLimits', R.LongitudeLimits, ...
    'ColumnsStartFrom','north');

% Export GeoTIFF
% >>> CHANGE OUTPUT NAME FOR NEW CROP <<<
geotiffwrite( ...
    'F:\Climakid\Management_05degree\MUST_Area_V3_05deg.tif', ...
    ir_05, ...
    R05);

% Create crop mask
mask = nan(nr2, nc2);

% Assign mask value where crop exists
mask(ir_05 > 0) = 1;

% Plot mask
figure
imagesc(mask)
colorbar
title('Crop Presence Mask')

% Export mask
% >>> CHANGE OUTPUT NAME FOR NEW CROP <<<
geotiffwrite( ...
    'F:\Climakid\Management_05degree\MUST_Mask_V3_05deg.tif', ...
    mask, ...
    R05);


%% FERTILIZER AGGREGATION
%  Wheat and Rice Example
%  ------------------------------------------------------------------------
%  Logic:
%  - India-specific fertilizer dataset is used within India
%  - Global fertilizer dataset is used outside India
%  - Final raster is aggregated using area-weighted averaging
%  ========================================================================

clear

% Load South Asia shapefile
S = shaperead( ...
    'F:\Data\Shapefiles_SA\SA-CNTRY.shp', ...
    'UseGeoCoords', true);

% Create 0.05° grid
lon = 60.0250:0.05:100.0250;
lat = -0.9750:0.05:39.0250;

[X,Y] = meshgrid(lon,lat);

% India mask only
% NOTE:
% Country index may differ for another shapefile
india = inpolygon(X,Y,S(5).Lon,S(5).Lat);

india = flipud(india);

% Load India fertilizer raster
% >>> CHANGE FOR NEW CROP <<<
fert = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\Krice_kgha.tif');

% Example for wheat:
% fert = readgeoraster('Whea_kgha.tif');

fert = double(fert);

% Remove invalid values
fert(fert < 0) = NaN;

% Load global fertilizer dataset
% >>> CHANGE VARIABLE NAMES FOR NEW CROP <<<
aa = ncread( ...
    'C:\Users\ABARIK\Downloads\fertilizer_application_2015soc_ric_1850-2015.nc', ...
    'fertrate');

lat_fert = ncread( ...
    'C:\Users\ABARIK\Downloads\fertilizer_application_histsoc_whe_1850-2015.nc', ...
    'latitude');

lon_fert = ncread( ...
    'C:\Users\ABARIK\Downloads\fertilizer_application_histsoc_whe_1850-2015.nc', ...
    'longitude');

% Select year 2015
aa1 = aa(:,:,166);

% Interpolate global fertilizer to South Asia grid
AA = interp2( ...
    lon_fert, ...
    lat_fert, ...
    aa1', ...
    X, Y, ...
    'linear', NaN);

% Merge India and global datasets
final_fert = flipud(AA);

% India pixels replaced with India-specific fertilizer
final_fert(india) = fert(india);

% Load crop area raster
% >>> CHANGE FOR NEW CROP <<<
[ar, R] = readgeoraster( ...
    'C:\Users\ABARIK\Downloads\CropAreaV3\CropAreaV3\MUST_AR_V3.tif');

ir = double(final_fert);
ar = double(ar);

factor = 10;

[nr, nc] = size(ir);

nr2 = floor(nr / factor);
nc2 = floor(nc / factor);

ir_05 = nan(nr2, nc2);

% Area-weighted aggregation
for i = 1:nr2

    for j = 1:nc2

        r = (i-1)*factor + (1:factor);
        c = (j-1)*factor + (1:factor);

        ir_block = ir(r,c);
        ar_block = ar(r,c);

        valid = ar_block > 0 & ...
                ~isnan(ar_block) & ...
                ~isnan(ir_block);

        if any(valid(:))

            w = ar_block(valid);
            v = ir_block(valid);

            ir_05(i,j) = sum(v .* w) / sum(w);

        end
    end
end

% Plot fertilizer
figure
imagesc(ir_05)
colorbar
title('Aggregated Fertilizer Application')

% Create raster reference
R05 = georasterref( ...
    'RasterSize', size(ir_05), ...
    'LatitudeLimits', R.LatitudeLimits, ...
    'LongitudeLimits', R.LongitudeLimits, ...
    'ColumnsStartFrom','north');

% Export GeoTIFF
% >>> CHANGE OUTPUT NAME FOR NEW CROP <<<
geotiffwrite( ...
    'C:\Users\ABARIK\Downloads\CropIRV3\MUST_FERT_V3_05deg_weighted.tif', ...
    ir_05, ...
    R05);

%% FERTILIZER AGGREGATION FOR CROPS WITHOUT GLOBAL DATA
 % Example: Pigeon Pea (PPea), Chickpea (CPea), Millets 
 % ------------------------------------------------------------------------
 % Logic:
 % 
 % For some crops, reliable global fertilizer application datasets are
 % unavailable outside India.
 % 
 % In such cases:
 % 
 %    1. India-specific fertilizer values are retained.
 %    2. Mean fertilizer application across valid Indian crop pixels is
 %       computed.
 %    3. This mean value is assigned to all pixels outside India.
 % 
 % This prevents unrealistic zero fertilizer values outside India while
 % maintaining reasonable regional estimates.
 % 
 % NOTE:
 % This approach should only be used for crops lacking suitable global
 % fertilizer datasets.
 % ========================================================================

clear
% Load shapefile
S = shaperead('F:\Data\Shapefiles_SA\SA-CNTRY.shp','UseGeoCoords',true);
lon = 60.0250:0.05:100.0250;
lat = -0.9750:0.05:39.0250;
[X,Y] = meshgrid(lon,lat);

% India mask only (k = 5)
india = inpolygon(X,Y,S(5).Lon,S(5).Lat);
india=flipud(india);

% Load India fertilizer raster
fert = readgeoraster('C:\Users\ABARIK\Downloads\PMillet_kgha.tif');
fert = double(fert); fert(fert<0)=NaN;

% Take 2015
aa=fert; aa(aa==0)=NaN;
aa1 = nanmean(aa(:));

% --- Combine ---
% India → India data
% Others → global data
final_fert(1:801, 1:801) = aa1;
for i=1:801
    for j=1:801
        if fert(i,j)>0
            final_fert(i,j)=fert(i,j);
        end
    end
end

[ar, R] = readgeoraster('C:\Users\ABARIK\Downloads\CropAreaV3\CropAreaV3\MUST_AR_V3.tif');

ir = double(final_fert);
ar = double(ar);

factor = 10;            
[nr, nc] = size(ir);
nr2 = floor(nr / factor);
nc2 = floor(nc / factor);

ir_05 = nan(nr2, nc2);

% Area-weighted aggregation
for i = 1:nr2
    for j = 1:nc2

        r = (i-1)*factor + (1:factor);
        c = (j-1)*factor + (1:factor);

        ir_block = ir(r,c);
        ar_block = ar(r,c);

        % Valid wheat pixels
        valid = ar_block > 0 & ~isnan(ar_block) & ~isnan(ir_block);

        if any(valid(:))
            w = ar_block(valid);
            v = ir_block(valid);

            ir_05(i,j) = sum(v .* w) / sum(w);
        end
    end
end

imagesc(ir_05)
% Create new raster reference (0.5 degree)
R05 = georasterref('RasterSize', size(ir_05),'LatitudeLimits', R.LatitudeLimits,'LongitudeLimits', R.LongitudeLimits,'ColumnsStartFrom','north');
geotiffwrite('F:\Climakid\Management_05degree\MUST_FERT_V3_05deg_weighted.tif', ir_05, R05);

%% plots
[aa, R] = readgeoraster("MUST_IR_V3_05deg_weighted.tif");
aa = flipud(double(aa));
[nrows, ncols] = size(aa);
lon = linspace( ...
    R.LongitudeLimits(1) + R.CellExtentInLongitude/2, ...
    R.LongitudeLimits(2) - R.CellExtentInLongitude/2, ...
    ncols);

lat = linspace( ...
    R.LatitudeLimits(2) - R.CellExtentInLatitude/2, ...
    R.LatitudeLimits(1) + R.CellExtentInLatitude/2, ...
    nrows);
figure
imagesc(lon, lat, aa)
set(gca,'YDir','normal')
colorbar
S = shaperead('F:\Data\Shapefiles_SA\SA-CNTRY.shp','UseGeoCoords',true);
hold on
geoshow(S, 'FaceAlpha', 0, 'LineWidth', 1);
axis off
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
title('Rice –Irrigation', 'FontName', 'Times New Roman', 'FontSize', 14)

%% FINAL PLOT VISUALIZATION
%  Example visualization for aggregated irrigation dataset
%  ========================================================================

clear

% Load aggregated raster
[aa, R] = readgeoraster("MUST_IR_V3_05deg_weighted.tif");

aa = flipud(double(aa));

% Create coordinate vectors
[nrows, ncols] = size(aa);

lon = linspace( ...
    R.LongitudeLimits(1) + R.CellExtentInLongitude/2, ...
    R.LongitudeLimits(2) - R.CellExtentInLongitude/2, ...
    ncols);

lat = linspace( ...
    R.LatitudeLimits(2) - R.CellExtentInLatitude/2, ...
    R.LatitudeLimits(1) + R.CellExtentInLatitude/2, ...
    nrows);

% Plot raster
figure
imagesc(lon, lat, aa)
set(gca,'YDir','normal')
colorbar
% Overlay South Asia boundaries
S = shaperead( ...
    'F:\Data\Shapefiles_SA\SA-CNTRY.shp', ...
    'UseGeoCoords', true);
hold on
geoshow(S, ...
    'FaceAlpha', 0, ...
    'LineWidth', 1);

% Figure formatting
axis off

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', 14)

title('Mustard – Irrigation', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 14)


%% END OF SCRIPT
