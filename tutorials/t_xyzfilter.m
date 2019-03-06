% Description:
%
% A short script as a reminder of how to correctly use the xyzfilter.
% Previously we have the issue after applying the xyz filter with the
% sensorComputeFullArray function. When we get the sensor data with this
% function and use xyz2srgb function to turn the data into srgb space, the
% color does not match what it should be as observed in scene and optical
% image. 
% The reason for this issue is due to the unfixed exposure time setting
% before using the sensorComputeFullArray function. This will cost the
% sensorCompute function to calculate the exposuretime for each channel,
% leading to a change for these channels. This will result in wrong 
% (relative) X, Y and Z channels, causing the color mismatch issue.
%
% Update: just found another issue is the noise. By setting the noise flag
% to be "-1", meaning eliminate all noise will give a better match srgb
% image.
%
% Zheng Lyu, Brian Wandell, 2019

%% Initialization
ieInit;

%% Create a scene
% We use the uniform white scene to make sure finally we are able to get
% the white image, might be blurred due to the optical image though.
scene = sceneCreate('uniform d65');
% sceneWindow(scene);
%% Create optical image
oi = oiCreate;
oi = oiCompute(oi, scene);
oi = oiSet(oi, 'fov', 12);
% oiWindow(oi);
%% Create a sensor and set the size according to the field of view
sensor = sensorCreate;
sensor = sensorSetSizeToFOV(sensor, oiGet(oi, 'fov'));

%% Now apply xyz filter on the sensor
wave = oiGet(oi, 'wave');
xyzQuanta = ieReadSpectra('xyzQuanta.mat', wave);
xyzQuantaFilter = xyzQuanta / max(max(max(xyzQuanta)));
% ieNewGraphWin; plot(wave, xyzQuantaFilter);

% These are the KEY STEPS to make sure exposure time is the same for three
% channels, and set the sensor to be noise free.
sensorXYZ = sensorSet(sensor, 'exp time', 1);
sensorXYZ = sensorSet(sensorXYZ, 'noise flag', -1);
%% Use the sensorComputeFullArray to calculate the xyz image, and convert
%  it into the srgb space
xyzFilterImage = sensorComputeFullArray(sensorXYZ, oi, xyzQuantaFilter);

xyz2srgbFilterImage = xyz2srgb(xyzFilterImage);
%% Get the xyz value from oi and compare them:
oiXYZ = oiGet(oi, 'xyz');
oiSRGB = xyz2srgb(oiXYZ);

%% Plot and compare
ieNewGraphWin; imshow(xyz2srgbFilterImage); title('Compute from full array');
ieNewGraphWin; imshow(oiSRGB); title('oi srgb image');