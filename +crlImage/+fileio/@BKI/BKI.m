classdef BKI < crlImage.imageFile
  % crlImage class for BKI files
  %
  % 
  
  properties (Constant, Hidden = true)
    validExts = {'.bki'};
  end
  
  methods
    
    function obj = BKI(varargin)
      obj = obj@crlImage.imageFile(varargin{:});
    end
    
%     function write(obj)
%       % Mandated by crlBase.baseFileObj
%     end
%     
%     function read(obj)
%       % Mandated by crlBase.baseFileObj
%       obj.readHeader;
%     end
    
    function readHeader(obj)
      obj.header = crlImage.fileio.BKI.staticReadHeader(obj.fname,obj.fpath);
      
      % Are these all guaranteed to exist for BKI files?
      obj.dimensions = arrayDim('dimSize',obj.sizes);
      obj.origin     = obj.header.origin;
      obj.directions = diag(obj.header.spacing);
      
      % What does the header.index field represent?
    end
    
    function readData(obj)
      % Mandated by crlImage.imageFile
      obj.data = obj.staticReadData(obj.fname,obj.fpath,obj.header);
    end
    
  end
  
  methods (Static=true)
    % Methods in individual m-files
    header = staticReadHeader(fname,fpath);
    data   = staticReadData(fname,fpath,header);
  end
  
end
  
  