classdef griddedImage < labelledArray
  % Combines a labelledArray with a spatialGrid
  %
  % 
  properties (Dependent=true)    
    sizes
    dimType
    origin
    directions  
    orientation
    aspect
    data    
    GUI
    spaceGrid
  end
  
  properties (Access=protected)
    dimType_
    spaceGrid_    
    renderer_
    GUI_    
  end
  
  methods
    
    function obj = griddedImage(image,varargin)
      
      if ~exist('image','var'), image = []; end;
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('spaceDims',':');
      p.parse(varargin{:});
                  
      obj = obj@labelledArray(image,p.Unmatched);      
             
      obj.spaceGrid_ = spatialGrid(obj.dimensions(p.Results.spaceDims));
    end
    
    obj = testThis(obj);
    
    function out = get.orientation(obj)
      out = obj.spaceGrid_.orientation;
    end;
    
    function out = get.origin(obj)
      out = obj.spaceGrid_.origin;
    end
    
    function out = get.directions(obj)
      out = obj.spaceGrid_.directions;
    end;
    
    function t = get.dimType(obj)
      t = obj.dimType_;
    end;
    
    function set.dimType(obj,val)
      obj.dimType_ = val;
    end;
    
    function g = get.spaceGrid(obj)
      g = obj.spaceGrid_;
    end;
    
    function set.spaceGrid(obj,val)
      obj.spaceGrid_ = val;
    end;
    
    function d = get.data(obj)
      d = obj.array;
    end;
    
    function set.data(obj,val)
      obj.array = val;
    end;
    
    function s = get.sizes(obj)
      s = obj.dimSize;
    end;
    
    function set.sizes(obj,val)
      obj.dimSize = val;
    end
    
    function aspect = get.aspect(obj)
      aspect = sqrt(sum(obj.directions.^2,1));
    end
    
    function rendererOut = sliceRenderer(obj)
      % Return the appropriate slice renderer
      %
      % Not REALLY sure if we want to actually store this, or let multiple
      % renderers be instantiated that are all tied to the same image.
      if isempty(obj.renderer_)
       obj.renderer_ = crlImage.gui.griddedImage.sliceRenderer(obj);
      end
      rendererOut = obj.renderer_;            
    end
    
    function sliceOut = getSlice(obj,axis,slice)
      % Get a slice from the volume
      assert(~isempty(axis)&&ismember(axis,[1:numel(obj.dimensions)]),...
                  'Invalid axis identifier');
            
      sMax = obj.dimSize(axis);
      assert((slice>0)&&(slice<=sMax),...
        'Selected slice out of range');
      
      idx = repmat({':'},1,numel(obj.dimensions));
      idx{axis} = slice;

      s.type = '()';
      s.subs = idx;      
      sliceOut = subsref(obj,s);           
    end
    
    function i = renderSlice(obj,axes,axis,slice)
      
    end
    
  end
  
end

 