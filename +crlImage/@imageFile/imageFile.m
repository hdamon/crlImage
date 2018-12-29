classdef (Abstract) imageFile < crlBase.baseFileObj & crlImage.griddedImage
% File Class for image files
%
% Combines crlBase.baseFileObj and crlImage.griddedImage
%

  properties
    header % Stores raw header information from the image file.
  end
      
  properties (Hidden=true)
    hasData = false;
  end
  
  methods
    
    function obj = imageFile(varargin)
   % Test Functions
      fnameFcn = @(x) isempty(x)||isa(x,'crlImage.imageFile')||...
        (ischar(x) && ~ismember(lower(x),{'readonly'}));
      fpathFcn = @(x) isempty(x) || ...
        (ischar(x) && ~ismember(lower(x),{'readonly'}));
      
      % Input Parser Object
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('fname',[],fnameFcn);
      p.addOptional('fpath',[],fpathFcn);
      p.parse(varargin{:});
                         
      %% Call Parent Constructor
      obj = obj@crlBase.baseFileObj(p.Results.fname,p.Results.fpath,...
        p.Unmatched);
      obj = obj@crlImage.griddedImage;      
      if obj.existsOnDisk
        obj.read;
      end         
    end

    %% Read and Write Methods Mandated by crlBase.baseFileObj
    function read(obj)
      obj.readHeader;
    end
    
    function write(obj)
      if ~obj.readOnly
        obj.writeHeader;
        obj.writeData;
      else
        warning([obj.fname ' is flagged as read only']);
      end
    end
    
  end
  
  methods (Access=protected)
    
    function val = getArray(obj)
      % Method called by labelledArray whenever obj.array is requested
      %

      if isempty(obj.array_) 
        % If the array hasn't been set, read it from disk.      
        crlBase.disp(['Reading Data for ' obj.fname ]);
        obj.readData;
      end
      val = getArray@crlImage.griddedImage(obj);
    end
        
  end
   
  %% Abstract Methods
  methods (Abstract)   
    %readHeader(obj);
    readData(obj); 
    %writeHeader(obj);
    %writeData(obj);
  end  
  
  methods (Abstract,Static=true)
    header = staticReadHeader(fname,fpath);
    data = staticReadData(fname,fpath,header);
  end
       
end
