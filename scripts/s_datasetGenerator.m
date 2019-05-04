%%

%%
ieInit;

%% 
upscaleFactor = 4;

%% Create xyz filter
l3dSR = l3DataSuperResolution();
xyzCF = l3dSR.get('ideal cmf'); xyzCF = xyzCF./ max(max(max(xyzCF)));
%% Create a camera
camera = l3dSR.camera;

sensorLR = cameraGet(camera,'sensor');

fillFactor = 1;
sensorLR = pixelCenterFillPD(sensorLR,fillFactor);

sensorLR = sensorSet(sensorLR, 'filterspectra', xyzCF);

% Set the high resolution sensor
sensorHR = sensorSet(sensorLR, 'noise flag', -1);

% Adjust the pixel size, but keep the same fill factor
sensorHR = sensorSet(sensorHR, 'pixel size same fill factor',...
    sensorGet(sensorLR, 'pixel size')/upscaleFactor); % Change the pixel size
sensorHR = sensorSet(sensorHR, 'expTime',1);
cameraLR = cameraSet(camera, 'sensor', sensorLR);
cameraHR = cameraSet(camera, 'sensor', sensorHR);
%% Set the img path and save path
imgPath = fullfile('/scratch', 'zhenglyu', 'unlabeled2017');
savePath = fullfile('/scratch', 'zhenglyu', 'sensor_data_set');

imgFormat = strcat('*.', 'jpg');
filesToLoad = dir(fullfile(imgPath, imgFormat));

targetFormat = strcat('*.mat');

for ii = 1:5000
    disp(['loading scene ', num2str(ii)]);
    % Read image file name
    imgName = filesToLoad(ii).name;
    
    % Transfer image to scene
    wList = [400:10:700];
    fullImgName = fullfile(imgPath, imgName);
    scene = sceneFromFile(fullImgName, 'rgb', 110, 'LCD-Apple', wList);
    scene = sceneSet(scene, 'fov', 5);
    illmnt = ieReadSpectra('D65', wList);
    scene = sceneAdjustIlluminant(scene, illmnt);
    oi = oiCreate; oi = oiCompute(scene, oi);
    hFov = sceneGet(scene, 'fov horizontal');
    vFov = sceneGet(scene, 'vfov');
    sensorLR = sensorSetSizeToFOV(sensorLR, [hFov, vFov]);
    sensorLR = sensorCompute(sensorLR, oi);
    lrData = sensorGet(sensorLR, 'volts');
    % ieNewGraphWin; imshow(lrData);

    sensorHR = sensorSet(sensorHR, 'size', sensorGet(sensorLR, 'size') * upscaleFactor);

    hrData = sensorComputeFullArray(sensorHR, oi, xyzCF);
    % ieNewGraphWin; imshow(hrData);
    saveName = strcat('img_data_', int2str(ii), '.mat');
    save(fullfile(savePath, saveName), 'lrData', 'hrData','-v7.3');
end

%%
disp('Done.')


