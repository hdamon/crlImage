function data = staticReadData(fname,fpath,header)
% Static method for reading NRRD data
%
%
%


%% Input Parsing
if ~exist('fpath','var')
  fpath = './';
end

% Read header if one isn't provided
if ~exist('header','var')||isempty(header)
  if isstruct(fpath)
    header = fpath;
    fpath = './';
  else  
    header = crlImage.fileio.NRRD.staticReadHeader(fname,fpath);
  end
end

%% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(fpath);

%% Open the appropriate file, and make sure it's closed when done.
if isfield(header,'data_fname')&&~isempty(header.data_fname)
  crlBase.disp(['Reading data from separate file: ' header.data_fname]);
  fid = fopen(header.data_fname,'rb');
  assert(fid>0,['Failed to open NRRD data file ' header.data_fname]);
else
  fid = fopen(fname,'rb');
  assert(fid>0,['Failed to open NRRD file ' fname]);
  % Move past the header by looking for the blank line
  while (true)
    line = fgetl(fid);
    if (isempty(line)||feof(fid))
      break;
    end
  end
end
closeFile = onCleanup(@() fclose(fid));

assert(~isempty(header.encoding) && ...
       ~isempty(header.dimension) && ...
       ~isempty(header.sizes) && ...
       ~isequal(header.encoding,'???') && ...
       ~isequal(header.dimension,'???') && ...
       ~isequal(header.sizes,'???'), ...
       'Required header fields are missing');
if (isequal(header.endian,'???')), header.endian = 'little'; end     
     
assert(numel(header.sizes)==header.dimension,...
        'Sizes field does not match dimension field');
 
assert(isfield(header,'type'),'Data type undefined in header');     
typecast = crlImage.fileio.NRRD.getMatlabType(header.type);

switch lower(header.encoding)
 case {'raw'}
  data = fread(fid, inf, typecast);
  
 case {'gzip', 'gz'}
  tmpBase = tempname();
  tmpFile = [tmpBase '.gz'];
  fidTmp = fopen(tmpFile, 'wb');
  assert(fidTmp > 3, 'Could not open temporary file for GZIP decompression')
  
  tmp = fread(fid, inf, 'uint8=>uint8');
  fwrite(fidTmp, tmp, 'uint8');
  fclose(fidTmp);
        
  gunzip(tmpFile)
  system(['rm ' tmpFile]);
  
  fidTmp = fopen(tmpBase, 'r');
  
  %meta.encoding = 'raw';
  %data = readData(fidTmp, meta, type);
  
  data = fread(fidTmp,inf,typecast);    
  fclose(fidTmp);
  system(['rm ' tmpBase]);
  
 case {'txt', 'text', 'ascii'}
  data = fscanf(fid, '%f');
  data = cast(data, type);
  
 otherwise
  assert(false, 'Unsupported encoding')
end

data = adjustEndian(data,header.endian);

assert(numel(data)==prod(header.sizes),...
  'Data size does not match header.sizes');

data = reshape(data,header.sizes);

end


function data = adjustEndian(data, endian)
[~,~,endian] = computer();
needToSwap = (isequal(endian, 'B') && isequal(lower(endian), 'little')) || ...
             (isequal(endian, 'L') && isequal(lower(endian), 'big'));
         
if (needToSwap)
    data = swapbytes(data);
end
end
