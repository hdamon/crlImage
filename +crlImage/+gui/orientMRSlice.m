function sliceImg = orientMRSlice(sliceImg,axis,orientation)
% Orient an image sliceImg from a NRRD
%
% sliceImg = orientMRSlice(sliceImg,axis,orientation)
%
% Inputs
% ------
%   sliceImg : 2D Array: Image to be oriented
%   axis : Which axis it's from
%   orientation: Orientation of the overall image
%
% Currently only left-posterior-superior images are supported
%

if ~exist(orientation,'var'), orientation = 'left-posterior-superior'; end;

switch lower(orientation)
  case 'left-posterior-superior'
    sliceImg = permute(sliceImg,[2 1]);
    
    if ismember(axis,[3]);
      if isempty(which('flip'))
        % Backwards compatibility
        sliceImg = flipdim(sliceImg,1);
      else
        sliceImg = flip(sliceImg,1);
      end
    end
  otherwise
    error('Unknown image orientation');
end