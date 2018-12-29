function data = staticReadData(fname,fpath,header)
% Static data read funciton for BKI files
%
%

mf ='l';
%% Input Parsing
if ~exist('fpath','var'), fpath = './'; end

% Read header if one isn't provided
if ~exist('header','var')||isempty(header)
  if isstruct(fpath)
    header = fpath;
    fpath = './';
  else  
    header = crlImage.fileio.NRRD.staticReadHeader(fname,fpath);
  end
end

% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(fpath);

if isempty(dir(fname))
  error('File not found');
end
nbytes = getfield(dir(fname),'bytes');

% Open file and set cleanup 
fid = fopen(fname,'rb');
assert(fid>0, ['Failed to open ' fname ' for reading']);
cleaner = onCleanup(@() fclose(fid));

%% Data Read
% attempt to find size of data elements
headersize=4*3*4; % 4 triples of 4-byte numbers
fseek(fid,headersize,'bof');
datasize=(nbytes-headersize)/prod(header.size);

numextrabytes=(nbytes-headersize)-round(datasize)*prod(header.size);

switch round(datasize)
  case 1
    skip=0;
    data=fread(fid,prod(header.size),'uint8',skip,mf);
    data=reshape(data,header.size);
  case 2
    % hard coding 2-byte data to be signed short
    skip=0;
    data=fread(fid,prod(header.size),'int16',skip,mf);
    data=reshape(data,header.size);
  case 4
    % hard coding 4-byte data to be float ... it might be int32 !
    skip=0;
    data=fread(fid,prod(header.size),'float',skip,mf);
    data=reshape(data,header.size);
  case 8
    % hard coding 8-byte data to be double ... it might be int64 !
    skip=0;
    data=fread(fid,prod(header.size),'double',skip,mf);
    data=reshape(data,header.size);
  otherwise
    fprintf('Datasize is %f, unsure what to do\n',round(datasize));
    keyboard
end

switch numextrabytes
  case 0 % do nothing
  case 8
    header.NumOfActionsExecuted=fread(fid,1,'uint32',skip,mf);
    header.NumOfActionsUpdated=fread(fid,1,'uint32',skip,mf);
  otherwise
    warning('Unexpected number of extra bytes in bki file');
end

% we should be at end of file. Read one more character to check
fread(fid,1,'char');
if ~feof(fid)
  warning('Expected end of file ... perhaps file was not interpreted correctly?');
end
