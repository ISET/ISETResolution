% Compare two ways to generate low resolution image

%%
ieInit;

%% load the optical image
% path: /scratch/ZhengLyu/super_resolution_pbrt_scenes/optical_image/colorful.mat
inFile = fullfile('/scratch', 'ZhengLyu', 'super_resolution_pbrt_scenes',...
                                        'optical_image', 'colorful.mat');
                                    
load(inFile); % 
%%
sceneWindow(scene);

%% Define the upscale factor
upscaleFactor = 3;
%% Create oi
oi = oiCreate;
oi = oiSet(oi, 'fov', sceneGet(scene, 'fov'));
oi = oiSet(oi, 'fnumber', 0.1);
% oi = oiSet(oi, 'focal length', 1.2);
oi = oiCompute(oi, scene);
% oiWindow(oi)
%%

sensorlr = sensorCreate;
sensorlr = sensorSet(sensorlr, 'pixel size', 2.9*sensorGet(sensorlr, 'pixel size'));
sensorlr = sensorSetSizeToFOV(sensorlr, oiGet(oi, 'fov'));

sensorhr = sensorSet(sensorlr, 'pixel size',...
                sensorGet(sensorlr, 'pixel size')/upscaleFactor);
sensorhr = sensorSet(sensorhr, 'size',...
                        sensorGet(sensorlr, 'size')*upscaleFactor); 
                    
sensorlr = sensorCompute(sensorlr, oi);
sensorhr = sensorCompute(sensorhr, oi);

%%
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
subplot(1, 2, 1); imshow(srgbImglr); subplot(1, 2, 2); imshow(srgbImghr); 

%% see a crop of the low resolution image and high resolution image
rectlr = [32, 62, 10, 10];
lrCrop = imcrop(srgbImglr, rectlr); 

recthr =[(rectlr(1)-1)*upscaleFactor+1, (rectlr(2)-1)*upscaleFactor+1,...
                        (rectlr(3)+1)*upscaleFactor-1, (rectlr(4)+1)*upscaleFactor-1];
hrCrop = imcrop(srgbImghr, recthr); 

% See the crop
vcNewGraphWin; 
subplot(1, 2, 1); imagesc(lrCrop);axis square; subplot(1, 2, 2); imagesc(hrCrop); axis square

% Check one channel of the crop
vcNewGraphWin; 
subplot(1, 2, 1); imagesc(lrCrop(:,:,1));axis square; subplot(1, 2, 2); imagesc(hrCrop(:,:,1)); axis square

%% Now use a kernel to test if the downsampled image is the same one with the real low resolution image
kernel = ones(3, 3, 3)/9;

rIdx = 1:upscaleFactor:size(srgbImghr,1);
cIdx = 1:upscaleFactor:size(srgbImghr,2);
lrConv = zeros(size(srgbImglr));
for rr = 1:length(rIdx)
    for cc = 1:length(cIdx)
        rSE = [rIdx(rr), rIdx(rr)+size(kernel,1)-1];
        cSE = [cIdx(cc), cIdx(cc)+size(kernel,2)-1];
        lrConv(rr, cc, :) = sum(sum(srgbImghr(rSE(1):rSE(2), cSE(1):cSE(2),:) .* kernel, 1),2);
    end
end

%%
vcNewGraphWin;
subplot(1, 3, 1); imshow(srgbImglr(:,:,1) - lrConv(:,:,1)); colorbar; caxis([-1e-2 0.2e-1]);colormap('gray');
subplot(1, 3, 2); imshow(srgbImglr(:,:,2) - lrConv(:,:,2)); colorbar; caxis([-1e-2 0.2e-1]); colormap('gray');
subplot(1, 3, 3); imshow(srgbImglr(:,:,3) - lrConv(:,:,3)); colorbar; caxis([-1e-2 0.2e-1]);colormap('gray');

%% Check the depth map
depthMap = sceneGet(scene, 'depth map');
vcNewGraphWin; imagesc(depthMap); colormap(gray); colorbar;