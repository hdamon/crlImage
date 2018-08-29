classdef sliceRenderer < handle
  % Object class for rendering a 2D slice from a griddedImage object
  %
  % obj = sliceRenderer(imageIn,varargin)
  %
  % Inputs
  % ------
  %   imageIn : Array of crlImage.griddedImage objects to render
  %
  % Param-Value Inputs
  % ------------------
  %   cmap : Define the colormaps to be used
  %
  % Outputs
  % -------
  %   obj : Array of sliceRenderer objects, with one renderer for each 
  %           object in the imageIn array.
  %
  %
  
  
  properties (Dependent = true)
    axis
    slice
    aspect
    cmap
  end
    
  properties (Access = protected)
    axis_
    slice_
    cmap_
    originalImage_
    sliceImage_
    listeners_
    gui_
  end
  
  events
    updatedOut
  end
  
  methods
    
    function obj = sliceRenderer(imageIn,varargin)
      
      if nargin > 0
        
        if isa(imageIn,'crlImage.griddedImage.sliceRenderer')
          % Return the input object
          obj = imageIn;
          return;
        end;
        
        % Check Input Type
        assert(isa(imageIn,'crlImage.griddedImage'),...
              'This renderer is for crlImage.griddedImage objects');
          
        p = inputParser;
        p.addParameter('cmap',[],@(x) isa(x,'guiTools.widget.alphacolor'));
        p.parse(varargin{:});
     
        assert(isempty(p.Results.cmap)||(numel(p.Results.cmap)==numel(imageIn)),...
                  'Incorrect number of colormaps provided');
                               
        %
        if numel(imageIn)>1
          for i = 1:numel(imageIn)
            if isempty(p.Results.cmap)
              obj(i) = crlImage.gui.griddedImage.sliceRenderer(imageIn(i));
            else
              obj(i) = crlImage.gui.griddedImage.sliceRenderer(imageIn(i),...
                'cmap',p.Results.cmap(i));
            end
          end;
          return;
        end
            
        if isempty(p.Results.cmap)
          cmap = guiTools.widget.alphacolor('range',imageIn.arrayRange);
        else
          cmap = p.Results.cmap;
        end;
        
        
        obj.originalImage_ = imageIn;
        obj.axis = 1;
        obj.slice = ceil(imageIn.dimSize(1)/2);
        obj.cmap = cmap;
        
        obj.listeners_{1} = addlistener(obj.cmap,'updatedOut',...
                                      @(h,evt) notify(obj,'updatedOut'));
        obj.listeners_{2} = addlistener(obj.originalImage_,'updatedOut',...
                                      @(h,evt) obj.updatedInput);
      end;
    end
  
    function out = get.aspect(obj)
      out = obj.originalImage_.aspect;
    end;
    
    function updatedInput(obj)
      % Callback when the input image is updated.
      %
      % Update the slice image, then notify any listeners.
      obj.updateSlice;
      notify(obj,'updatedOut');
    end;
    
    function out = get.cmap(obj)
      out = obj.cmap_;
    end;
    
    function set.cmap(obj,val)
      obj.cmap_ = val;
    end;
    
    function set.axis(obj,val)
      
      assert((numel(val)==1)||(numel(val)==numel(obj)),...
               'Invalid number of axis definitions');
             
      if numel(val)==1
        val = repmat(val,1,numel(obj));
      end;
      
      %% Multiple Objects
      if numel(obj)>1
        for i = 1:numel(obj)
          obj(i).axis = val(i);
        end
        return;
      end
      
      %% Single Object Below This Line
      if ~isempty(obj.originalImage_)
        nDims = numel(obj.originalImage_.dimensions);
        assert(~isempty(val)&&ismember(val,[1:nDims]),...
              'Selected axis out of range');
      end;
      if ~isequal(obj.axis_,val)
       obj.axis_  = val;
       obj.slice_ = ceil(obj.originalImage_.dimSize(obj.axis_)/2);
       obj.updateSlice;
      end
    end;
    
    function out = get.axis(obj)
      out = obj.axis_;
    end;
    
    function set.slice(obj,val)
      assert((numel(val)==1)||(numel(val)==numel(obj)),...
               'Invalid number of axis definitions');
             
      if numel(val)==1
        val = repmat(val,1,numel(obj));
      end;
      
      %% Multiple Objects
      if numel(obj)>1
        for i = 1:numel(obj)
          obj(i).slice = val(i);
        end
        return;
      end      
      
      if ~isempty(obj.originalImage_)
        sMax = obj.originalImage_.dimSize(obj.axis);
        assert((val>0)&&(val<=sMax),...
                  'Selected slice out of range');
      end;
      if ~isequal(obj.slice_,val)
        obj.slice_ = val;
        obj.updateSlice;
      end;            
    end;
    
    function out = get.slice(obj)
      out = obj.slice_;
    end;
    
    function updateSlice(obj)
      
      % Update All Slices In A Stack
      %  This should probably never actually get called?
      if numel(obj)>1
        for i = 1:numel(obj)
          obj(i).updateSlice;
        end
        return;
      end;
      
      % Get a slice from the volume and store it internally
      idx = repmat({':'},1,numel(obj.originalImage_.dimensions));
      idx{obj.axis} = obj.slice;

      s.type = '()';
      s.subs = idx;      
      obj.sliceImage_ = subsref(obj.originalImage_,s);           
    end      
    
    function renderSlice(obj,varargin)
      p = inputParser;
      p.addOptional('ax',[],@(x) isa(x,'matlab.graphics.axis.Axes'));
      p.addOptional('clearfirst',false,@(x) islogical(x));
      p.addParameter('axis',obj.axis,@(x) isnumeric(x)&&isscalar(x));
      p.addParameter('slice',obj.slice,@(x) isnumeric(x)&&isscalar(x));
      p.parse(varargin{:});
      
      % Shouldn't incurr computation costs if it's not changed
      obj.axis = p.Results.axis;
      obj.slice = p.Results.slice;
      
      ax = p.Results.ax;
      if isempty(ax); figure; ax = gca; end;      
    
      axes(ax);
      if p.Results.clearfirst, cla; end;
      hold on;
      img = squeeze(obj.sliceImage_.data);
      img = crlImage.gui.orientMRSlice(img,obj.axis,obj.originalImage_.orientation);
      [rgb, alpha] = obj.cmap.img2rgb(img);
      tmp = get(ax,'ButtonDownFcn');
      image(rgb,'AlphaData',alpha,'ButtonDownFcn',tmp);
      set(ax,'ButtonDownFcn',tmp);
      hold off;            
    end
      
    function propertyGUI(obj)
    end
    
  end
  
end