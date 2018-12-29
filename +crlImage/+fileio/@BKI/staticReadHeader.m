function header = staticReadHeader(fname,fpath)
% Static header reading function for BKI files
%
% header = staticReadHeader(fname,fpath)
%

mf = 'l';
if ~exist('fpath','var'), fpath = './'; end

% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(fpath);

if isempty(dir(fname))
  error('File not found');
end

% Open file and set cleanup 
fid = fopen(fname,'rb');
assert(fid>0, ['Failed to open ' fname ' for reading']);
cleaner = onCleanup(@() fclose(fid));

nbytes = getfield(dir(fname),'bytes');

header.index   = read_triple(fid,'int32');
header.size    = read_triple(fid,'uint32');
header.origin  = read_triple(fid,'float32');
header.spacing = read_triple(fid,'float32');

  function r=read_triple(fid,dtype)
    skip=0;
    r(1)=fread(fid,1,dtype,skip,mf);
    r(2)=fread(fid,1,dtype,skip,mf);
    r(3)=fread(fid,1,dtype,skip,mf);
  end

end