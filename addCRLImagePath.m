function addCRLImagePath()

[currDir,~,~] = fileparts(mfilename('fullpath'));

addpath(currDir);
addpath(fullfile(currDir,'/external/niftiTools'));
