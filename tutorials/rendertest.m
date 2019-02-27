%%
%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file

% The teapot is our test file
% /scratch/zhenglyu/pbrt-v3-scenes/landscape
inFile = fullfile('/scratch', 'zhenglyu', 'pbrt-v3-scenes',...
                                        'landscape', 'view-0.pbrt');
recipe = piRead(inFile);

% The output will be written here
sceneName = 'landscape';
%/scratch/zhenglyu/renderedScene/
outFile = fullfile('/scratch','zhenglu','renderedScene', ...
                    sceneName,'landscapeTest.pbrt');
recipe.set('outputFile',outFile);
%% Set up the render quality

% There are many different parameters that can be set.
recipe.set('film resolution',[600 600]);
recipe.set('pixel samples',64);
recipe.set('max depth',1); % Number of bounces

%% Render
piWrite(recipe);

%%  This is a pinhole case.  So we are rendering a scene.

[scene, result] = piRender(recipe);

ieAddObject(scene); sceneWindow;
scene = sceneSet(scene,'gamma',0.5);

% Notice that we also computed the depth map
scenePlot(scene,'depth map');
%%
outScene = fullfile('/scratch','zhenglu','renderedScene', ...
                    sceneName,'landscapeTest.m');
save(outScene, scene);
%% END
