classdef (Abstract) imageFile < crlBase.baseFileObj %& crlImage.griddedImage
% File Class for image files
%
% Basically just a crlBase.baseFileObj object with the addition of
% header and data properties.
%
%
  properties
    header
    data
  end
  
  properties (Hidden=true)
    hasData = false;
  end
  
  methods
    
    function obj = imageFile(varargin)
   % Test Functions
      fnameFcn = @(x) isempty(x)||isa(x,'crlImage.fileio.newNRRD')||...
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
      if obj.existsOnDisk
        obj.read;
      end;
      %obj = obj@crlImage.griddedImage;      
      
    end

    function out = get.data(obj)
      if ~obj.hasData
        try
          crlBase.disp(['Reading Data for ' obj.fname ]);
          obj.readData;
          obj.hasData = true;
        catch
          disp(['Error reading data for ' obj.fname]);
          keyboard;
          obj.data = [];
        end;
      end
      out = obj.data;
    end
    
    function set.data(obj,val)
      % function set.data(obj,val)
      %
      % Overloaded set function for crlEEG.fileio.NRRDData.data.  This does a bunch
      % of data checking to make sure that the NRRD isn't getting too
      % screwed up.
      %
      % Allows:
      %  1) Clearing of data, ie: obj.data = [];
      %  2) Setting of data to the default value. ie: obj.data = '???';
      %  3) Setting of data, as long as the size of the new value matches
      %        obj.sizes.
      %
      dataSize = size(val);
      if all(dataSize==0)
        crlBase.disp('Clearing data field');
        obj.data = '???';
        obj.hasData = false;
      elseif strcmpi(val,'???');
        crlBase.disp('Setting default data field');
        obj.data = val;
        obj.hasData = false;
      elseif (numel(dataSize)==numel(obj.header.sizes))&&all(dataSize==obj.header.sizes)
        obj.data = val;
        obj.hasData = true;
      else
        error('Attempting to change the size of the NRRD data');
      end;
      obj.imgRanges = [];
    end    
    
  end
   
  methods (Abstract)
  end  
  
       
end
