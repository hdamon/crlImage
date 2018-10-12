function readHeader(nrrdObj)
% Read and Parse the NRRD Header
% 
% Written By: Damon Hyde
% Modified from mathworks provided code
% Last Edited: Mar 9, 2016
% Part of the cnlEEG Project
%

% Move to the right directory, and make sure we move back when done
tmpDir = pwd;
returnToDir = onCleanup(@() cd(tmpDir));
cd(nrrdObj.fpath);

% Open file and set cleanup 
fid = fopen(nrrdObj.fname,'rb');
assert(fid>0, ['Failed to open ' nrrdObj.fname ' for reading']);
cleaner = onCleanup(@() fclose(fid));

% Make sure it looks like a NRRD
line = fgetl(fid);
assert(numel(line) >= 4, 'Bad file signature');
assert(isequal(line(1:4),'NRRD'), 'File does not appear to be a NRRD');

meta = struct([]);

while (true)  
   line = fgetl(fid);
   
   % Exit if at end of header
   if (isempty(line)), break; end
         
   % Skip comment lines
   if (isequal(line(1),'#')), continue; end;
   
   % Parse line
   parsed = regexp(line, ':=?\s*','split','once');
   assert(numel(parsed)==2, 'Error parsing line');
   
   fieldname = lower(parsed{1});
   value = parsed{2};
   
   % For Debugging
   %disp(['Field: ' fieldname ' Value: ' value]);
   
   parseHeaderField(nrrdObj,fieldname,value);

   % If we're at the end of the file, exit
   if (feof(fid)), break; end;
end

%% Configure object fields appropriately from the header

% if isfield(nrrdObj.header,'sizes')
% nrrdObj.dimensions = arrayDim('dimSize',nrrdObj.header.sizes);
% end;
% if isfield(nrrdObj.header,'spaceorigin')
% nrrdObj.origin = nrrdObj.header.spaceorigin;
% end;
% if isfield(nrrdObj.header,'spacedirections')
% nrrdObj.directions = nrrdObj.header.spacedirections;
% end
% if isfield(nrrdObj.header,'orientation')
% nrrdObj.orientation = nrrdObj.header.space;
% end;
% 
% if isfield(nrrdObj.header,'kinds')
% nrrdObj.dimType = nrrdObj.header.kinds;
% end;
% 
% if ~isfield(nrrdObj.header,'encoding'), nrrdObj.header.encoding = 'gzip'; end;
% if ~isfield(nrrdObj.header,'type'), nrrdObj.header.type = 'float'; end;

end

function parseHeaderField(nrrdObj,fieldname,value)
% Parsing and assignment of NRRD Header Fields from String Values
%
%


switch lower(fieldname)
  case 'content'
    nrrdObj.header.content = removeExcessDelimiters(value,' ');
  case 'type'
    nrrdObj.header.type = removeExcessDelimiters(value,' ');
  case 'endian'
    nrrdObj.header.endian = removeExcessDelimiters(value,' ');
  case 'encoding'
    nrrdObj.header.encoding = removeExcessDelimiters(value,' ');
  case {'datafile', 'data file'}
    nrrdObj.header.data_fname = removeExcessDelimiters(value,' ');
  case 'dimension'
    nrrdObj.header.dimension = sscanf(value,'%i');
  case 'space'
    nrrdObj.header.space = removeExcessDelimiters(value,' ');
  case {'spacedirections', 'space directions'}
    tmpvalue = strrep(value,'none','');
    iSD = extractNumbersWithout(tmpvalue,{'(', ')', ','});
    if (length(iSD)~=9 & length(iSD)~=10)
      fprintf('Warning: %i space directions found.\n', iSD );
    end
    nrrdObj.header.spacedirections = [iSD(1) iSD(4) iSD(7); ...
      iSD(2) iSD(5) iSD(8); ...
      iSD(3) iSD(6) iSD(9)];
  case 'sizes'
    iSizes = sscanf(value,'%i');
    nrrdObj.header.sizes = iSizes';
  case 'thicknesses'
    sThicknesses = extractStringList(value);
    iThicknesses = [];
    lenThicknesses = length(sThicknesses);
    for iI=1:lenThicknesses
      iThicknesses = [iThicknesses, str2num( sThicknesses{iI} ) ];
    end
    nrrdObj.header.thicknesses = iThicknesses;
  case 'kinds'
    nrrdObj.header.kinds = extractStringList(value);
  case 'centerings'
    nrrdObj.header.centerings = extractStringList(value);
  case 'spaceunits'
    nrrdObj.header.spaceunits = extractStringList(value);
  case {'spaceorigin', 'space origin'}
    iSo = extractNumbersWithout(value,{'(',')',','});
    nrrdObj.header.spaceorigin = iSo';
  case 'measurementframe'
    iMF = extractNumbersWithout( value, {'(',')',','} );
    nrrdObj.header.measurementframe = [iMF(1) iMF(4) iMF(7); ...   
                                   iMF(2) iMF(5) iMF(8); ...
                                   iMF(3) iMF(6) iMF(9)];
  case 'modality'
     nrrdObj.header.modality = removeExcessDelimiters( extractKeyValueString( value ), ' ');   
  case 'dwmri_b-value'
    nrrdObj.header.bvalue = str2num( extractKeyValueString(value) );    
  case 'dwmri_gradient_'
    [iGNr, dwiGradient] = extractGradient(value);
    nrrdObj.header.gradients(iGNr+1,:) = dwiGradient;    
  otherwise
    disp(['NRRD Field ' fieldname ' is unsupported by this library, skipping']);
end

end

function sl = removeExcessDelimiters( strList, delim )
% Remove excess characters from a string
% 

if ( isempty( strList ) )
  sl = [];
  return;
end

indxList = [];
len = length( strList );

iStart = 1;
while ( iStart<len & strList(iStart)==delim )
  iStart = iStart+1;
end

iEnd = len;
while ( iEnd>1 & strList(iEnd)==delim )
  iEnd = iEnd-1;
end

iLastWasDelimiter = 0;
for iI=iStart:iEnd  
  if ( strList(iStart)~=delim )
    indxList = [indxList; iI ];
    iLastWasDelimiter = 0;
  else
    if ( ~iLastWasDelimiter )
      indxList = [indxList; iI];
    end
    iLastWasDelimiter = 1;
  end  
end

sl = strList(indxList);
end

function iNrs = extractNumbersWithout( inputString, withoutTokens )
% Remove delimiters and return a string of numbers
%
auxStr = inputString;

for iI=1:length( withoutTokens )  
  auxStr = strrep( auxStr, withoutTokens{iI}, ' ' );  
end

iNrs = sscanf( auxStr, '%f' );
end

function sl = extractStringList( strList )
% Extract a list of strings 
%

strList = removeExcessDelimiters( strList, ' ' );
delimiterIndices = strfind(strList,' ');
numDelimiters = length(delimiterIndices);

if (numDelimiters>=1)
  sl{1} = strList(1:delimiterIndices(1)-1);
else
  sl{1} = strList;
end

for iI=1:numDelimiters-1
  sl{iI+1} = strList(delimiterIndices(iI)+1:delimiterIndices(iI+1)-1);
end

if (numDelimiters>=2)
  sl{numDelimiters+1} = strList(delimiterIndices(end)+1:end);
end

end

function [iGNr, dwiGradient] = extractGradient( st )

% first get the gradient number
iGNr = str2num( st(1:4) );

% find where the assignment is
assgnLoc = strfind( st, ':=' );

if ( isempty(assgnLoc) )
  dwiGradient = [];
  return;
else 
  dwiGradient = sscanf( st(assgnLoc+2:end), '%f' );  
end

end


function kvs = extractKeyValueString( st )

assgnLoc = strfind( st, ':=' );

if ( isempty(assgnLoc) )
  kvs = [];
  return;
else  
  kvs = st(assgnLoc(1)+2:end);  
end

end

