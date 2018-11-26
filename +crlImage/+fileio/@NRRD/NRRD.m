classdef NRRD < crlImage.imageFile & dynamicprops
   
  properties (Constant, Hidden=true)
    validExts = {'.nrrd', '.nhdr'};
  end
  
  methods
    
    function obj = NRRD(varargin)
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
    
  end
  
  
end