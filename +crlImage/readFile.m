function fileOut = readFile(varargin)
% Generalized file reader for crlImage
%
% function fileOut = readFile(varargin)
%
% Usage
% -----
%    f = crlImage.readFile(fname)
%    f = crlImage.readFile(fname,fpath)
%
% Optional Param-Value Inputs
% ---------------------------
%   'readOnly' : If set true, file will be flagged as read only.
%                   DEFAULT: False
%
% Additional unmatched fields in varargin will be passed to the file object
% constructor. Note that when doing this, it is best to include both fname
% and fpath data, to prevent misparsing the additional input data.
%
% Currently Supported File Formats:
% ---------------------------------
%    NRRD : Using crlImage.fileio.NRRD
%   NIfTI : Using crlImage.fileio.NIFTI
%
% Part of the crlImage Project
% 2009-2018
%

% Input Parsing
p = inputParser;
p.KeepUnmatched = true;
p.addOptional('fname',[],@(x) isempty(x)||ischar(x));
p.addOptional('fpath',[],@(x) isempty(x)||ischar(x));
p.addParameter('readOnly',false,@(x) islogical(x));
p.parse(varargin{:});

[fName,fPath] = ...
  crlImage.fileio.checkFileNameAndPath(p.Results.fname,p.Results.fpath);

% Find filetype and call appropriate class constructor
[~,~,EXT] = fileparts(fName);

switch lower(EXT)
  case {'.nrrd','.nhdr'}
    fileOut = crlImage.fileio.NRRD(fName,fPath,...
      'readonly',p.Results.readOnly,p.Unmatched);
  case '.nii'
    fileOut = crlImage.fileio.NIFTI(fName,fPath,...
      'readonly',p.Results.readOnly,p.Unmatched);
  otherwise
    error('Unknown file extension');
end


end
