classdef sliceViewer < guiTools.uipanel
  % GUI for viewing slices of 3D gridded volumes
  %
  % obj = sliceViewer(volumes,varargin)
  %
  % Inputs
  % ------
  %  volumes : Objects to render slices from.
  %             Two things are required of these objects:
  %             1) r = volumes(i).sliceRenderer must exist for each element
  %             2) The returned r must have a method to render the
  %             individual slice using the syntax
  %             r.renderSlice(axes,'axis',showAxis,'slice',showSlice)
  %
  %
  %%%%%%%%% IGNORE WHATS BELOW
  % GUI for vol3DSliced and volStack3DSliced Object
  %
  % classdef sliceViewer < uitools.baseobj
  %
  % Opens a two-tab UIPanel for the display of a vol3DSliced object
  %
  % Tab 1 Includes Slice Selection and Visualization
  % Tab 2 Shows all layers of the image, with buttons to open GUIs for
  %         display option and colormap control.
  %
    
  properties (Dependent)
    ax
    renderers
    axis
    slice
    zoom
  end
  
  properties (Hidden = true)    
    sliceControl
  end
  
  properties (Access=protected)
    ax_
    renderers_
    zoom_
    listeners_
    tabCont_
    tabs_
    imgControls
    addRemove
  end
  
  methods
    
    function obj = sliceViewer(varargin)
            
      %% Input Parsing
      p = inputParser;
      p.KeepUnmatched = true;
      p.addOptional('volumes',[]);
      p.addParameter('Parent',[]);
      p.parse(varargin{:});
      
      parent = p.Results.Parent;
      if isempty(parent), parent = figure; end
      
      volumes = p.Results.volumes;
      
      %% Initialize Main Panel
      obj = obj@guiTools.uipanel('Parent',parent,p.Unmatched);
      obj.ResizeFcn = @(h,evt) obj.resizeInternals;
      
      %% Set Two tabs_
      obj.tabCont_ = uitabgroup('Parent',obj.panel);
      obj.tabs_(1) = uitab(obj.tabCont_,'Title','Image');
      obj.tabs_(2) = uitab(obj.tabCont_,'Title','Layers');
            
      %% Set up Plot Axis
      obj.ax = axes('Parent',obj.tabs_(1),...
        'Units', 'normalized',...
        'Position', [0.02 0.11 0.96 0.87]);
      
      %% Set up Slice Control
      obj.sliceControl = guiTools.widget.selectXYZSlice(...
        volumes(1).dimSize,...
        'Parent',obj.tabs_(1),...
        'Units','normalized',...
        'Position',[0.02 0 0.98 0.1]);
      
      % Initialize Renderers
      if ~isempty(p.Results.volumes)
        obj.renderers = p.Results.volumes.sliceRenderer;
      end

      % Default Color Layering
      if numel(obj.renderers)>1
        for i = 1:(numel(obj.renderers)-1)
         obj.renderers(i).cmap.transparentZero;
        end
        obj.renderers(end).cmap.type = 'gray';
      end
              
      % Add Listeners
      obj.listenTo{1} = addlistener(obj.sliceControl,'updatedOut',...
                            @(h,evt) obj.renderSlice); 
      obj.initializeControlTab;
      obj.renderSlice;
     
    end
   
    function set.ax(obj,val)
      obj.ax_ = val;
    end
    function out = get.ax(obj)
      out = obj.ax_;
    end
    
    function set.renderers(obj,val)
      if ~isequal(obj.renderers_,val)
        % If updating renderers, update all listeners.
        obj.renderers_ = val;
        for i = 1:numel(obj.renderers_)
          % First listener slot is reserved for the slice control
          if numel(obj.listenTo)>=(i+1)
            % Delete existing listener, if present
            delete(obj.listenTo{i+1});
          end
          % Add new listener
          obj.listenTo{i+1} = ...
            addlistener(obj.renderers(i),'updatedOut',...
            @(h,evt) obj.renderSlice);          
        end
        obj.renderSlice;
      end
    end
    function out = get.renderers(obj)
      out = obj.renderers_;
    end
    
    function set.axis(obj,val)
      obj.sliceControl.selectedAxis = val;
    end
    function out = get.axis(obj)
      out = obj.sliceControl.selectedAxis;
    end
    
    function set.slice(obj,val)
      obj.sliceControl.selectedSlice = val;
    end
    function out = get.slice(obj)
      out = obj.sliceControl.selectedSlice;
    end
      
    function set.zoom(obj,val)
      obj.zoom_ = val;
    end
    
    function val = get.zoom(obj)
      val = obj.zoom_;
    end
      
    
    function initializeControlTab(obj)
      % Should configure the control tab of the viewer.
      
      if ~isempty(obj.imgControls)
          delete(obj.imgControls)
      end
      
      obj.imgControls = crlImage.gui.griddedImage.rendererGUI.empty;
      
      for i = 1:numel(obj.renderers)
          obj.imgControls(i) = obj.renderers(i).propertyGUI(...
                                   'Parent',obj.tabs_(2),...
                                   'Units','normalized',...
                                   'Position',[0.02 0.98-i*0.11 0.98 0.1]);
      end
      
%       if ~isempty(obj.imgControls)
%         delete(obj.imgControls)
%       end;
%       obj.imgControls = uitools.util.imgDispProp.empty;
%       
%       if isa(obj.volume,'vol3DSliced')
%         prop = obj.volume;
%       else
%         prop = obj.volume.volumes;
%       end;
%       
%       for i = 1:numel(prop)
%         obj.imgControls(i) = uitools.util.imgDispProp(...
%           'Parent',obj.tabs_(2),...
%           'Units','normalized',...
%           'Origin',[0.02 0.98-(i*0.11)],...
%           'Size',[0.98 0.1],...
%           'Name',prop(i).name);
%         obj.listenTo{end+1} = addlistener(obj.imgControls(i),'editCMap',...
%           @(h,evt) obj.editColorMap(i));
%         obj.listenTo{end+1} = addlistener(obj.imgControls(i),'editDispProp',...
%           @(h,evt) obj.editDispProp(i));
%         %       obj.listenTo{end+1} = addlistener(obj.imgControls(i),'visUpdated',...
%         %         @(h,evt) obj.setVisible(i));
%         %       obj.listenTo{end+1} = addlistener(obj.imgControls(i),'typeUpdated',...
%         %         @(h,evt) obj.setDisplayType(i));
%       end;
%       
%       obj.addRemove(1) = uicontrol('Style','pushbutton',...
%         'Parent',obj.tabs_(2),...
%         'Units','normalized',...
%         'Position',[0.02 0.02 0.47 0.05],...
%         'String','Add Layer');
%       
%       obj.addRemove(2) = uicontrol('Style','pushbutton',...
%         'Parent',obj.tabs_(2),...
%         'Units','normalized',...
%         'Position',[0.51 0.02 0.47 0.05],...
%         'String','Remove Layer');
      end
  end
  
  methods (Access=protected)
    
    function resizeInternals(obj)
    end
        
    function updateImgAspect(obj)
      if ~isempty(obj.renderers)
        switch obj.axis
          case 1, daspect(obj.ax,1./obj.renderers(1).aspect([2 3 1]));
          case 2, daspect(obj.ax,1./obj.renderers(1).aspect([1 3 2]));
          case 3, daspect(obj.ax,1./obj.renderers(1).aspect([1 2 3]));
        end
      end
    end
    
    function renderSlice(obj)  
      % Render all slices in the current viewer
      %
      
      axes(obj.ax); 
         
      % Delete existing images afterwards to prevent strobing
      toDelete = allchild(obj.ax);
            
      % Renderers internally iterate
      %
      % This does, however, assume uniform typing for the renderers. While
      % this is currently the case (all of type
      % crlImage.gui.griddedImage.sliceRenderer), it might be better to
      % change this in the future.
      %
      obj.renderers.renderSlice(obj.ax,false,'axis',obj.axis,'slice',obj.slice);
      
%       for i = numel(obj.renderers):-1:1
%         % Render in reverse order
%         obj.renderers(i).renderSlice(obj.ax,false,...
%                                 'axis',obj.axis,'slice',obj.slice);
%       end
      axis off tight;
      delete(toDelete);
      obj.updateImgAspect;     
      drawnow;
    end

    function setVisible(obj,i)
      if isa(obj.volume,'vol3DSliced')
        obj.volume.displayOn = obj.imgControls(i).isVisible;
      else
        obj.volume.volumes(i).displayOn = ...
          obj.imgControls(i).isVisible;
      end
    end
    
  end
  
  
end
