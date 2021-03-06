classdef rendererGUI < guiTools.uipanel
  % Image Property GUI 
  %
  % GUI interface for crlImage.gui.griddedImage.sliceRenderer objects
  %
  
  properties (Dependent = true)
    name
    isVisible    
  end
  
  properties (Access=protected)
    nameUI
    textUI
    visUI
    cmapUI 
    propUI
  end
  
  events
    nameUpdated
    visUpdated
    editDispProp
    editCMap
  end
  
  methods
    
    function obj = rendererGUI(varargin)
      
      p = crlImage.gui.griddedImage.rendererGUI.parseInputs(varargin{:});
      
      %% Main UI Panel
      obj = obj@guiTools.uipanel(...
        'Units','pixels',...
        'Position',[10 10 500 50]);        
      
      obj.nameUI = uicontrol('Style','edit',...
        'Parent',obj.panel,...
        'String',p.Results.name,...
        'Units','normalized',...
        'Position',[0.02 0.5 0.3 0.48],...
        'Callback',@(h,evt) notify(obj,'nameUpdated',SpecialEventDataClass(obj.nameUI.String)));
      obj.textUI   = uicontrol('Style','text',...
        'Parent',obj.panel,...
        'String', 'Visible:',...
        'Units','normalized',...
        'Position',[0.02 0.02 0.25 0.45]);
      obj.visUI = uicontrol('Style','checkbox',...
        'Parent',obj.panel,...
        'Units','normalized',...
        'Value',1,...
        'Position',[0.28 0.02 0.05 0.45],...
        'Callback',@(h,evt) notify(obj,'visUpdated'));    
      obj.cmapUI = uicontrol('Style','pushbutton',...
        'Parent',obj.panel,...
        'Units','normalized',...
        'String','Edit Colormap',...
        'Position',[0.66 0.02 0.32 0.98],...
        'Callback',@(h,evt) notify(obj,'editCMap'));   
      obj.propUI = uicontrol('Style','pushbutton',...
        'Parent',obj.panel,...
        'Units','normalized',...
        'String','Edit Display Options',...
        'Position',[0.33 0.02 0.32 0.98],...
        'Callback',@(h,evt) notify(obj,'editDispProp'));      
      
      setUnmatched(obj,p.Unmatched);
    end
       
    function out = get.isVisible(obj)
      out = obj.visUI.Value;
    end
  end
    
  methods (Access=protected,Static=true)
    function p = parseInputs(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      addParamValue(p,'name','VOLUME');                
      parse(p,varargin{:});
    end
  end
  
end