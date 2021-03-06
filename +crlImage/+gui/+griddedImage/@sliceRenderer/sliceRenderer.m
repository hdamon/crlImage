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
  % Properties
  % ----------
  %           axis : Currently selected axis
  %          slice : Currently selected slice
  %         aspect : Aspect ratio of image
  %           cmap : Image colormap
  %   enableRender : Flag to turn rendering on/off
  %  originalImage : 3D Volume (griddedImage object) that the slice is
  %                    selected from.
  %
  %
  
  properties (Dependent = true)
    axis
    slice
    aspect
    cmap
    enableRender
    originalImage
  end
  
  properties (Access = protected)
    axis_
    slice_
    cmap_
    enableRender_ = 1; % Enabled by default.
    originalImage_
    sliceImage_
    listeners_
    gui_
  end
  
  events
    updatedOut
  end
  
  methods
    
    function obj = sliceRenderer(varargin)
      
      if nargin > 0
        if isa(varargin{1},'crlImage.griddedImage.sliceRenderer')
          % Return the input object
          obj = varargin{1};
          return;
        end
      end
      
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('imageIn',[],@(x) isa(x,'crlImage.griddedImage'));
      p.addParameter('cmap',[],@(x) isa(x,'guiTools.widget.alphacolor'));
      p.parse(varargin{:});
      
      imageIn = p.Results.imageIn;
      cmap = p.Results.cmap;
     
      %% Recurse for Multiple Input Images
      if numel(imageIn)>1
        assert(isempty(cmap)||ismember(numel(cmap),[1 numel(imageIn)]),...
          'Incorrect number of colormaps');
        obj(numel(imageIn)) = crlImage.gui.griddedImage.sliceRenderer;
        for i = 1:numel(imageIn)
          obj(i) = crlImage.gui.griddedImage.sliceRenderer(imageIn(i),p.Unmatched);
        end
        return;
      end
      
      %% Instantiate Renderer for a Single Object
      if isempty(cmap)
        cmap = guiTools.widget.alphacolor;
      end
      
      obj.cmap = cmap;
      obj.originalImage = imageIn;
      obj.listeners_ = {};
    end
    
    %% Get/Set obj.originalImage
    function out = get.originalImage(obj)
      out = obj.originalImage_;
    end
    
    function set.originalImage(obj,val)
      % Set originalImage_ and update the appropriate listener
      if ~isequal(obj.originalImage_,val)
        obj.originalImage_ = val;
        if numel(obj.listeners_)>=2
          delete(obj.listeners{2});
        end
        obj.listeners_{2} = addlistener(obj.originalImage_,'updatedOut',...
          @(h,evt) obj.updatedInput);
        obj.axis = 1;
        obj.slice = ceil(obj.originalImage_.dimSize(1)/2);
        if ~isempty(obj.cmap)&&isequal(obj.cmap.range,[0 1])
          obj.cmap.range = val.arrayRange;
        end
      end
    end
    
    %% Set/Get enableRender
    %%%%%%%%%%%%%%%%%%%%%%%
    function out = get.enableRender(obj)
        out = obj.enableRender_;
    end
    
    function set.enableRender(obj,val)
        if ~isequal(obj.enableRender_,val)
        obj.enableRender_ = val;
        notify(obj,'updatedOut');
        end
    end
    
    
    %% Get aspect
    %%%%%%%%%%%%%
    function out = get.aspect(obj)
      out = obj.originalImage_.aspect;
    end
       
    %% Set/Get obj.cmap
    %%%%%%%%%%%%%%%
    function out = get.cmap(obj)
      out = obj.cmap_;
    end
    
    function set.cmap(obj,val)
      if ~isequal(obj.cmap_,val)
        obj.cmap_ = val;
        if numel(obj.listeners_)>=1
          delete(obj.listeners{1});
        end
        if isequal(val.range,[0 1])&&~isempty(obj.originalImage)
          obj.cmap_.range = obj.originalImage.arrayRange;
        end
        obj.listeners_{1} = addlistener(obj.cmap_,'updatedOut',...
          @(h,evt) notify(obj,'updatedOut'));
      end
    end
    
    %% Set/Get obj.axis
    %%%%%%%%%%%%%%%%%%%
    function set.axis(obj,val)
      
      assert((numel(val)==1)||(numel(val)==numel(obj)),...
        'Invalid number of axis definitions');
      
      if numel(val)==1
        val = repmat(val,1,numel(obj));
      end
      
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
      end
      if ~isequal(obj.axis_,val)
        obj.axis_  = val;
        obj.slice_ = ceil(obj.originalImage_.dimSize(obj.axis_)/2);
        obj.updateSlice;
      end
    end
    
    function out = get.axis(obj)
      out = obj.axis_;
    end
    
    %% Set/Get obj.slice
    %%%%%%%%%%%%%%%%%%%%
    function set.slice(obj,val)
      assert((numel(val)==1)||(numel(val)==numel(obj)),...
        'Invalid number of axis definitions');
      
      if numel(val)==1
        val = repmat(val,1,numel(obj));
      end
      
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
      end
      if ~isequal(obj.slice_,val)
        obj.slice_ = val;
        obj.updateSlice;
      end
    end
    
    function out = get.slice(obj)
      out = obj.slice_;
    end
    
    
    function updatedInput(obj)
      % Callback when the input image is updated.
      %
      % Update the slice image, then notify any listeners.
      obj.updateSlice;
      notify(obj,'updatedOut');
    end
    
    function updateSlice(obj) 
      % Update All Slices In A Stack
      
      
      %  This loop should probably never actually get called?
      if numel(obj)>1
        for i = 1:numel(obj)
          obj(i).updateSlice;
        end
        return;
      end
      
      % Get a slice from the volume and store it internally
      idx = repmat({':'},1,numel(obj.originalImage_.dimensions));
      idx{obj.axis} = obj.slice;
      
      s.type = '()';
      s.subs = idx;
      obj.sliceImage_ = squeeze(subsref(obj.originalImage_.data,s));
    end
    
    function renderSlice(obj,varargin)
      % Render the selected slice to a specified axes
      
      % Multi-Render
      if numel(obj)>1
          % Always render in reverse order (First slice on top)
          for i = numel(obj):-1:1
              obj(i).renderSlice(varargin{:});
          end
          return
      end
      
      if ~obj.enableRender
          % Only render if turned on
          return;
      end
      
      % Input Parsing
      p = inputParser;
      p.addOptional('ax',[],@(x) isa(x,'matlab.graphics.axis.Axes'));
      p.addOptional('clearfirst',false,@(x) islogical(x));
      p.addParameter('axis',obj.axis,@(x) isnumeric(x)&&isscalar(x));
      p.addParameter('slice',obj.slice,@(x) isnumeric(x)&&isscalar(x));
      p.parse(varargin{:});
      
      % Shouldn't incurr computation costs if it's not changed
      obj.axis  = p.Results.axis;
      obj.slice = p.Results.slice;
      
      ax = p.Results.ax;
      if isempty(ax); figure; ax = gca; end
      
      axes(ax);
      if p.Results.clearfirst, cla; end
      hold on;
      img = obj.sliceImage_; %squeeze(obj.sliceImage_.data);
      img = crlImage.gui.orientMRSlice(img,obj.axis,obj.originalImage_.orientation);
      [rgb, alpha] = obj.cmap.img2rgb(img);
      tmp = get(ax,'ButtonDownFcn');
      image(rgb,'AlphaData',alpha,'ButtonDownFcn',tmp);
      set(ax,'ButtonDownFcn',tmp);
      hold off;
    end
    
    function varargout = propertyGUI(obj,varargin)
        % Create or raise a uipanel to edit renderer options
        %
        
        if ishghandle(obj.gui_)
            guiTools.util.parentfigure.raise(obj.gui_);
        else
          obj.gui_ = crlImage.gui.griddedImage.rendererGUI(varargin{:});
          
          obj.listeners_{end+1} = addlistener(obj.gui_,'editCMap',@(h,evt) obj.cmap_.edit);
          obj.listeners_{end+1} = addlistener(obj.gui_,'editDispProp',@(h,evt) disp('NOT YET IMPLEMENTED'));
          obj.listeners_{end+1} = addlistener(obj.gui_,'visUpdated',@(h,evt) obj.updateVisible(h,evt));
        end
        
        if nargout>0
            varargout{1} = obj.gui_;
        end
        
    end
    
    
    function updateVisible(obj,h,evt)
        obj.enableRender = h.isVisible;
    end
  end
  
end