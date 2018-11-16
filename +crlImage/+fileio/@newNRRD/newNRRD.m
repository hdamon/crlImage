classdef newNRRD < crlImage.imageFile
   
  properties (Constant, Hidden=true)
    validExts = {'.nrrd', '.nhdr'};
  end;
  
  methods
    
    function obj = newNRRD(varargin)
      % Constructor for crlEEG.fileio.NRRD objects.
      %
      % function obj = crlEEG.fileio.NRRD(fname,fpath)
      %            
      obj = obj@crlImage.imageFile(varargin{:});     
    end
    
    function write(obj)
    end
    
    function read(obj)      
      obj.readHeader;      
    end
    
    [matlabtype] = getMatlabType(nrrdObj);
    
  end
  
  methods (Access=protected)
    
    function writeHeader(fileIn,varargin)
    end
     
    function writeData(fileIn,varargin)
    end
%     
%     function val = getArray(obj)
%       if isempty(obj.array_) %obj.hasData
%         try
%           crlBase.disp(['Reading Data for ' obj.fname ]);
%           obj.readData;
%           %obj.hasData = true;
%         catch
%           disp(['Error reading data for ' obj.fname]);
%           e = lasterror
%           keyboard;
%           obj.data = [];
%         end;
%       end
%       val = getArray@crlImage.imageFile(obj);      
%     end
    
  end
  
  
end