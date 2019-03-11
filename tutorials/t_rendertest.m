%%
%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file

% The teapot is our test file
% /scratch/zhenglyu/pbrt-v3-scene-ZL/
inFile = fullfile('/scratch', 'zhenglyu', 'pbrt-v3-scene-ZL',...
                                        'landscape', 'view-0.pbrt');
recipe = piRead(inFile);

% The output will be written here
sceneName = 'landscape';
%/scratch/zhenglyu/renderedScene/
outFile = fullfile('/scratch','zhenglyu','renderedScene', ...
                    sceneName,'landscape_v3.pbrt');
recipe.set('outputFile',outFile);
%% Set up the render quality

% There are many different parameters that can be set.
recipe.set('film resolution',[8192 4608]);
recipe.set('pixel samples', 1024);
% recipe.set('max depth',20); % Number of bounces

%% Render
piWrite(recipe);

%%  This is a pinhole case.  So we are rendering a scene.

[scene, result] = piRender(recipe);
%%
ieAddObject(scene); sceneWindow;
scene = sceneSet(scene,'gamma',1);

% Notice that we also computed the depth map
scenePlot(scene,'depth map');
%%
outScene = fullfile('/scratch','zhenglyu','renderedScene', ...
                    sceneName,'landscape_v3_v1.m');
save(outScene, 'scene');
%% END
