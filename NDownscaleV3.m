clc; 
clear all
%MainData=readtable('C:\Aniket\BISA research\ACASA\Fertilizer data\Downscaling\V3\DownscaleINPUT1.xlsx','Sheet','Sheet1');
%save('C:\Aniket\BISA research\ACASA\Fertilizer data\Downscaling\V3\DownscaleINPUT1.mat','MainData')
load('C:\Aniket\BISA research\ACASA\Fertilizer data\Downscaling\V3\DownscaleINPUT1.mat'); %this file gives the main table named MainData
limits=readtable('C:\Aniket\BISA research\ACASA\Fertilizer data\Downscaling\V3\LIMITS.xlsx','Sheet','Sheet1');
UNQdist=unique(MainData.CN_DT_Code);
cropDETAILS = readtable('C:\Aniket\BISA research\ACASA\Fertilizer data\Downscaling\V2\cropdetails_MATLAB.csv');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CropMask=table2array(MainData(:,8:21));
DistNcons=table2array(MainData(:,36:49));
CropCoeff=table2array(cropDETAILS(:,2:15));
%%% Calculate Nitrogen supply by soil based on SOC, BD and crop duration
SOC = (0.181*MainData.SOC_5_15cm + 0.272*MainData.SOC_15_30cm + 0.545*MainData.SOC_30_60cm)/2; %updated SOC most probably in % (5-15, 15-30, 30-60). See source https://zenodo.org/records/2525553 by 2 was divided to convert to percentage
BD = (0.037*MainData.BD0_5+0.22*MainData.BD30_60+0.74*MainData.BD100_200)/100; %check units
SOILNSUPPLY = SOC.*1000.*60.*0.000085.*BD.*0.6.*CropCoeff(3,:)./10; %relation of SOC, BD and crop duration
%%% Additional Nitrogen requirement of crop based on GPP, Harvest index,Nitrogen
%%% fixation
KGPPyield=zeros(1,1); 
RGPPyield=zeros(1,1);
KCropNreq=zeros(1,1);
RCropNreq=zeros(1,1);
KAddNreq=zeros(1,1);
RAddNreq=zeros(1,1);
KTOTNreq=zeros(1,1);
RTOTNreq=zeros(1,1);

%Kharif
for ik=7:14 %crops %Barley-1	Cpea-2	Mustard-3	Rrice-4	Sghum-5	Wheat-6	Cotton-7	Gnut-8	Krice-9	Maize-10	Pmillet-11	Ppea-12	SBean-13 SCane-14
KGPPyield(1:size(DistNcons,1),ik-6)=MainData.AVG_KhGGP*CropCoeff(2,ik); %K_GPP x Harvest Index = GPP yield. Average GPP using 2015,2016 and 2017 data
KCropNreq(1:size(DistNcons,1),ik-6)=KGPPyield(:,ik-6)*CropCoeff(4,ik); %Crop Nitrogen requirement = GPP yield x Nitrogen feed (constant) of crop
KAddNreq(1:size(DistNcons,1),ik-6)= max(0,KCropNreq(:,ik-6)-SOILNSUPPLY(:,ik)-CropCoeff(5,ik)); %Additional nitrogen supply = Crop Nitrogen requirement - soil N supply - Nitrogen fixation of crop. If the value is <0, then take 0   
KTOTNreq(1:size(DistNcons,1),ik-6)= KAddNreq(:,ik-6).*CropMask(:,ik)/CropCoeff(2,ik); %total Nitrogen requirement for the pixel (kg) = Additional Nitrogen supply x Crop mask area  / Nitrogen use efficiency
end
%Rabi
for ir=1:6 %crops %Barley-1	Cpea-2	Mustard-3	Rrice-4	Sghum-5	Wheat-6	Cotton-7	Gnut-8	Krice-9	Maize-10	Pmillet-11	Ppea-12	SBean-13 SCane-14
RGPPyield(1:size(CropMask,1),ir)=MainData.AVG_RbGGP*CropCoeff(2,ir); %R_GPP x Harvest Index = GPP yield Average GPP using 2015,2016 and 2017 data
RCropNreq(1:size(CropMask,1),ir)=RGPPyield(:,ir)*CropCoeff(4,ir+7);
RAddNreq(1:size(CropMask,1),ir)= max(0,RCropNreq(:,ir)-SOILNSUPPLY(:,ir)-CropCoeff(5,ir)); %Additional nitrogen supply = Crop Nitrogen requirement - soil N supply - Nitrogen fixation of crop.If the value is <0, then take 0     
RTOTNreq(1:size(CropMask,1),ir)= RAddNreq(:,ir).*CropMask(:,ir)/CropCoeff(2,ir); %total Nitrogen requirement for the pixel(kg) = Additional Nitrogen supply x Crop mask area  / Nitrogen use efficiency  
end

%%%Proportioning nitrogen requirement with district consumption
propNkg=zeros(1,1);
CMareaTOT=zeros(1,1);
DIST_Nconsum=zeros(1,1);
DIST_Nreq=zeros(1,1);
STOREpropNkgha=zeros(1,1);

m=1;
for i=1:length(UNQdist)
propNkgha=zeros(1,1);    
%filtering district specific data
selDIST = strcmp(MainData.CN_DT_Code, UNQdist{i,1});
rowIndicesDIST = find(selDIST);
dataDIST = MainData(rowIndicesDIST,:); %select only the ith district data
dataKTOTNreqDIST=KTOTNreq(rowIndicesDIST,:);   
dataRTOTNreqDIST=RTOTNreq(rowIndicesDIST,:);
dataCropMaskDIST=CropMask(rowIndicesDIST,:);
dataDistNcons=DistNcons(rowIndicesDIST,:);

limitidx1=strcmp(limits.CNDT, UNQdist{i,1});
limitIndxDIST=find(limitidx1);
limitDIST=limits(limitIndxDIST,:);
datalimitDIST=table2array(limitDIST(:,2:29));

    %Kharif
    for ik=7:14
      CMareaTOT(1,ik)=sum(dataCropMaskDIST(:,ik)); %total area in a district based on crop mask
      DIST_Nconsum(1,ik)=CMareaTOT(1,ik)*dataDistNcons(1,ik); %total Nitrogen consumption based district Kg/ha x total crop mask area
      DIST_Nreq(1,ik)=sum(dataKTOTNreqDIST(:,ik-6));
      for jk=1:size(dataDistNcons,1)
          propNkg(jk,ik)=dataKTOTNreqDIST(jk,ik-6)*DIST_Nconsum(1,ik)/DIST_Nreq(1,ik); %proportional nitrogen alloted to pixel based on district nitrogen consumption and district nitrogen requirement 
          if dataCropMaskDIST(jk,ik)==0 %condition to check if there is crop area in the pixel
          propNkgha(jk,ik)=0;
          else
          propNkgha(jk,ik)=min(max(propNkg(jk,ik)/dataCropMaskDIST(jk,ik),datalimitDIST(1,ik)),datalimitDIST(1,ik+14)); %nitrogen consumption converted to kg/ha with upper and limit applied based on plot level data    
          end     
      end
    end
    
    %Rabi
    for ir=1:6
      CMareaTOT(1,ir)=sum(dataCropMaskDIST(:,ir)); %total area in a district based on crop mask
      DIST_Nconsum(1,ir)=CMareaTOT(1,ir)*dataDistNcons(1,ir);%total Nitrogen consumption based district Kg/ha x total crop mask area
      DIST_Nreq(1,ir)=sum(dataRTOTNreqDIST(:,ir));
      for jk=1:size(dataDistNcons,1)
          propNkg(jk,ir)=dataRTOTNreqDIST(jk,ir)*DIST_Nconsum(1,ir)/DIST_Nreq(1,ir); %proportional nitrogen alloted to
          if dataCropMaskDIST(jk,ir)==0 %condition to check if there is crop area in the pixel
          propNkgha(jk,ir)=0;
          else
          propNkgha(jk,ir)=min(max(propNkg(jk,ir)/dataCropMaskDIST(jk,ir),datalimitDIST(1,ir)),datalimitDIST(1,ir+14)); %nitrogen consumption converted to kg/ha with upper and limit applied based on plot level data
          end     
      end
    end
    
STOREpropNkgha(m:m+size(dataDistNcons,1)-1,1:size(propNkgha,2))=propNkgha(1:size(dataDistNcons,1),1:size(propNkgha,2));
STOREID(m:m+size(dataDistNcons,1)-1,1:7)=table(dataDIST.ACODE, dataDIST.CN_DT_Code, dataDIST.S_NAME, dataDIST.D_NAME, dataDIST.Country, dataDIST.LAT, dataDIST.LONG);
m=m+size(dataDistNcons,1);    
end
STOREpropNkgha(isnan(STOREpropNkgha)) = 0;

columnHeaders = {'ACODE',	'CN_DT_Code',	'S_NAME',	'D_NAME',	'Country',	'latitude',	'longitude',	'Barley_kgha',	'Cpea_kgha',	'Mustard_kgha',	'Rrice_kgha',	'Sorghum_kgha',	'Wheat_kgha',	'Cotton_kgha',	'Gnut_kgha',	'Krice_kgha',	'Maize_kgha',	'Pmillet_kgha',	'Ppea_kgha',	'Sbean_kgha',	'Scane_kgha'};

propTable = array2table(STOREpropNkgha, 'VariableNames', columnHeaders(8:end));
outputTable = [STOREID, propTable];
outputTable.Properties.VariableNames = columnHeaders;

writetable(outputTable, 'C:\Aniket\BISA research\ACASA\Fertilizer data\Downscaling\V3\outputTableV3.xlsx');