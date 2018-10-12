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
% Part of the crlImage Project
% 2009-2018
%

  p = inputParser;
  p.KeepUnmatched = true;
  p.addOptional('fname',[],@(x) isempty(x)||ischar(x));
  p.addOptional('fpath',[],@(x) isempty(x)||ischar(x));        
  p.addParamValue('readOnly',false,@(x) islogical(x));
  p.parse(varargin{:});

[fName,fPath] = ...
  crlImage.fileio.checkFileNameAndPath(p.Results.fname,p.Results.fpath);

[~,~,EXT] = fileparts(fName);

switch lower(EXT)
  case {'.nrrd','.nhdr'}
    fileOut = crlImage.fileio.newNRRD(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);
  case '.nii'
    fileOut = crlImage.fileio.NIFTI(fName,fPath,...
                                'readonly',p.Results.readOnly,p.Unmatched);  
  otherwise
    error('Unknown file extension');
end;  


end
