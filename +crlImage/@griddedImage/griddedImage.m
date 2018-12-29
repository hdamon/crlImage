classdef griddedImage < labelledArray
  % Base class for N-D Raster Images
  %
  %  obj = crlImage.griddedImage(image,varargin)
  %
  % Inputs
  % ------
  %   image : N-D numeric array
  %
  % Param-Value Inputs
  % ------------------
  %
  %
  %
 
  properties (Dependent=true)    
    sizes
    dimType
    origin
    directions  
    orientation
    aspect
    data       % Public access to .array
    GUI        % Currently unused
    spaceGrid  
  end
  
  properties (Access=protected)
    dimType_   % What type of dimension is it?
    spaceDims_ %
    spaceGrid_    
    renderer_
    GUI_       % Currently unused
  end
  
  methods
    
    function obj = griddedImage(image,varargin)
          
      if ~exist('image','var'), image = []; end
     
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('spaceDims',':');
      p.parse(varargin{:});
                  
      obj = obj@labelledArray(image,p.Unmatched);      
    
      obj.spaceDims_ = p.Results.spaceDims;
      obj.spaceGrid_ = spatialGrid(obj.dimensions(p.Results.spaceDims));   
    end
    
    function p = view(obj,varargin)
      if ~isempty(obj(1).array)
        p = crlImage.gui.sliceViewer(obj,varargin{:});
      end
    end
    
    obj = testThis(obj);
    
    %% spaceGrid is redirected to the protected property
    function g = get.spaceGrid(obj)
      g = obj.spaceGrid_;
    end
    
    function set.spaceGrid(obj,val)
      obj.spaceGrid_ = val;
    end
    
    %%
    function out = get.orientation(obj)
      out = obj.spaceGrid_.orientation;
    end
    
    function set.orientation(obj,val)
      obj.spaceGrid_.orientation = val;
    end
    
    function out = get.origin(obj)
      out = obj.spaceGrid_.origin;
    end
    
    function set.origin(obj,val)
      obj.spaceGrid_.origin = val;
    end
    
    function out = get.directions(obj)
      out = obj.spaceGrid_.directions;
    end
    
    function set.directions(obj,val)
      obj.spaceGrid_.directions = val;
    end
    
    function out = get.aspect(obj)
      out = obj.spaceGrid_.aspect;
    end
    
    function set.aspect(obj,val)
      obj.spaceGrid_.aspect = val;
    end
    
    function t = get.dimType(obj)
      t = obj.dimType_;
    end
    
    function set.dimType(obj,val)
      obj.dimType_ = val;
    end
    
    function d = get.data(obj)
      d = obj.array;
    end
    
    function set.data(obj,val)
      obj.array = val;
    end
    
    function s = get.sizes(obj)
      s = obj.dimSize;
    end
    
    function set.sizes(obj,val)
      obj.dimSize = val;
    end
    
    function rendererOut = sliceRenderer(obj)
      % Return the appropriate slice renderer
      %
      % Not REALLY sure if we want to actually store this, or let multiple
      % renderers be instantiated that are all tied to the same image.
      
      rendererOut = crlImage.gui.griddedImage.sliceRenderer(obj);      
    end
      
  end
  
  methods (Access=protected)
    
    function [out,varargout] = subcopy(obj,varargin)     
      out = subcopy@labelledArray(obj,varargin{:}); 
      out.spaceGrid = out.spaceGrid.copy;
      out.spaceGrid.dimensions = out.dimensions;      
    end
    
    %% Set/Get For Array
    %%%%%%%%%%%%%%%%%%%%
    function setArray(obj,val)
      setArray@labelledArray(obj,val);      
      obj.checkGridConsistency;
    end
    
    function val = getArray(obj)
      val = getArray@labelledArray(obj);
    end
    
    %% Set/Get For Dimensions
    %%%%%%%%%%%%%%%%%%%%%%%%%
    function setDimensions(obj,val)
      setDimensions@labelledArray(obj,val);
      obj.checkGridConsistency;
    end %% END setDimensions(obj,val)
    
    function val = getDimensions(obj)
      val = getDimensions@labelledArray(obj);
    end
    
    function checkGridConsistency(obj)
      % Check that obj is a valid griddedImage object
      %
      % checkGridConsistency(obj)
      %
      
      if isempty(obj.dimensions)
        return;
      end
      
      if isempty(obj.spaceGrid)
        obj.spaceGrid = spatialGrid(obj.dimensions(obj.spaceDims_));
        return;
      end
      
      if numel(obj.spaceGrid.dimensions)==numel(obj.dimensions)
        % Same dimensionality can keep the origin and directions
        obj.spaceGrid.dimensions = obj.dimensions;
      else
        % Changing dimensionality resets the spaceGrid
        obj.spaceGrid = spatialGrid(obj.dimensions(obj.spaceDims_));
      end        
    end
    
  end
  
end

 