% Demo script to illustrate how to do super resolution with:
% 1) ideal optics: meaning the PSF is delta function, there's no blur
%    effect when pass the optical image
% 2) sensor: we use a noise free sensor with xyz filter. When calcualting
%    the sensor signal, we compute the full array xyz filter image. Then we
%    transfer the image in xyz space to sRGB image.

%% init
ieInit;

%% load the optical image
inFile = fullfile('/scratch', 'ZhengLyu', 'super_resolution_pbrt_scenes',...
                                        'optical_image', 'colorful.mat');
                                    
load(inFile);

%% Adjust the illuminant
scene = sceneAdjustLuminance(scene, 'mean', 100);

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
oi = oiSet(oi, 'optics', optics);
% hres = oiGet(oi, 'hres');
oi = oiCompute(oi, scene);
% oiWindow(oi);

%% Create the low and high resolution image
sensorlr = sensorCreate;
sensorlr = sensorSet(sensorlr, 'pixel size', 2.9*sensorGet(sensorlr, 'pixel size'));
sensorlr = sensorSetSizeToFOV(sensorlr, oiGet(oi, 'fov'));

sensorhr = sensorSet(sensorlr, 'pixel size',...
                sensorGet(sensorlr, 'pixel size')/upscaleFactor);
sensorhr = sensorSet(sensorhr, 'size',...
                        sensorGet(sensorlr, 'size')*upscaleFactor); 
                    
sensorlr = sensorCompute(sensorlr, oi);
sensorhr = sensorCompute(sensorhr, oi);

%% Generate the ip module
ip = ipCreate;
iplr = ipCompute(ip, sensorlr);
iphr = ipCompute(ip, sensorhr);
%%
lrImg = ipGet(iplr, 'data srgb');
hrImg = ipGet(iphr, 'data srgb');
%%
vcNewGraphWin; 
subplot(1, 2, 1); imshow(lrImg); subplot(1, 2, 2); imshow(hrImg); 
%% see a crop of the low resolution image and high resolution image
rectlr = [32, 62, 10, 10];
lrCrop = imcrop(lrImg, rectlr); 

recthr =[(rectlr(1)-1)*upscaleFactor+1, (rectlr(2)-1)*upscaleFactor+1,...
                        (rectlr(3)+1)*upscaleFactor-1, (rectlr(4)+1)*upscaleFactor-1];
hrCrop = imcrop(hrImg, recthr); 

vcNewGraphWin; 
subplot(1, 2, 1); imshow(lrCrop); subplot(1, 2, 2); imshow(hrCrop);
%% convert the xyz image into srgb space
wave = oiGet(oi, 'wave');
xyzValue = ieReadSpectra('XYZQuanta.mat', wave);
xyzfilter = xyzValue / max(max(max(xyzValue)));
sensorlr = sensorSet(sensorlr, 'noise flag', -1);
sensorhr = sensorSet(sensorhr, 'noise flag', -1);

xyzImglr = sensorComputeFullArray(sensorlr, oi, xyzfilter);
xyzImghr = sensorComputeFullArray(sensorhr, oi, xyzfilter);
srgbImglr = xyz2srgb(xyzImglr);
srgbImghr = xyz2srgb(xyzImghr);

%%
vcNewGraphWin; 
imshow(srgbImghr); 
%%
lrIdealCrop = imcrop(srgbImglr, rectlr);
hrIdealCrop = imcrop(srgbImghr, recthr);
vcNewGraphWin; 
subplot(1, 4, 1); imshow(lrCrop); 
subplot(1, 4, 2); imshow(hrCrop);
subplot(1, 4, 3); imshow(lrIdealCrop);
subplot(1, 4, 4); imshow(hrIdealCrop);
