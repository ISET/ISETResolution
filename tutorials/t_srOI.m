%% Generate ideal optical images but with smaller FOV

%%
ieInit;

%% load the optical image
% path: /scratch/ZhengLyu/super_resolution_pbrt_scenes/optical_image/colorful.mat
inFile = fullfile('/scratch', 'ZhengLyu', 'super_resolution_pbrt_scenes',...
                                        'optical_image', 'colorful.mat');
                                    
load(inFile);
%% Adjust the illuminant
scene = sceneAdjustLuminance(scene, 'mean', 100);

%%
% sceneWindow(scene);
FOV = sceneGet(scene, 'fov');

%% Define the upscale factor
upscaleFactor = 3;
%% Create the ideal optical image
oi = oiCreate;
% Parts that can be skipped with diffraction limited method:
%   1) off axis method
%   2) OTF (PSF) calculation
%   3) diffuser method
optics = oiGet(oi, 'optics');
optics = opticsSet(optics, 'model', 'skip');
oiIdeal = oiSet(oi, 'optics', optics);
% hres = oiGet(oi, 'hres');
oiIdeal = oiCompute(oiIdeal, scene);
oi = oiCompute(oi, scene);
% oiWindow(oiIdeal);
%% Create the sensor part
sensor = sensorCreate;
sensor = sensorSetSizeToFOV(sensor, FOV);
sensor = sensorCompute(sensor, oiIdeal);
% sensorWindow(sensor);

%% ip
ip = ipCreate;
ip = ipCompute(ip, sensor);
ipWindow(ip);

%% Compare the ideal and non ideal optical image
% Here we use the ideal sensor
wave = oiGet(oi, 'wave');
xyzValue = ieReadSpectra('XYZQuanta.mat', wave);
xyzfilter = xyzValue / max(max(max(xyzValue)));

sensorNF = sensorSet(sensor, 'noise flag', -1);
xyzImgNFOI = sensorComputeFullArray(sensorNF, oi, xyzfilter);
xyzImgNFIOI = sensorComputeFullArray(sensorNF, oiIdeal, xyzfilter);

%%
srgbImgOI = xyz2srgb(xyzImgNFOI);
srgbImgIOI = xyz2srgb(xyzImgNFIOI);

vcNewGraphWin; 
subplot(1, 2, 1); imshow(srgbImgOI);
subplot(1, 2, 2); imshow(srgbImgIOI);

%%
rect = [9, 111, 20, 20];
OICrop = imcrop(srgbImgOI, rect);
IOICrop = imcrop(srgbImgIOI, rect);

vcNewGraphWin; 
subplot(1, 2, 1); imshow(OICrop);
subplot(1, 2, 2); imshow(IOICrop);
