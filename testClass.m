classdef testClass < crlImage.griddedImage
  
  properties
    imageObj
  end
  
  methods
    
    function obj = testClass(a)
      obj.imageObj = a;
    end
    
  end
  
  methods (Access=protected)
    
    function setArray(obj,val)
      if ~isempty(obj.imageObj)
      obj.imageObj.array = val;
      end;
    end
    
    function val = getArray(obj)
      if ~isempty(obj.imageObj)
      val = obj.imageObj.array;
      else
        val = [];
      end;
    end
    
    function setDimensions(obj,val)
      if ~isempty(obj.imageObj)
      obj.imageObj.dimensions = val;
      end;
    end
    
    function val = getDimensions(obj)
      if ~isempty(obj.imageObj)
      val = obj.imageObj.dimensions;
      else
        val = [];
      end;
    end
    
  end
  
end
