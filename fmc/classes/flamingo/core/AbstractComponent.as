﻿import flamingo.core.ParentChildComponentAdapter;
import flamingo.core.VisibleAdapter;
import flamingo.core.InitAdapter;

/*-----------------------------------------------------------------------------
* This file is part of Flamingo MapComponents.
* Author: Michiel J. van Heek.
* IDgis bv
 -----------------------------------------------------------------------------*/

class flamingo.core.AbstractComponent extends MovieClip {
    
    private var componentID:String = "AbstractComponent 1.0";
    
    // The component's 19 base properties.
    var name:String = null;
    var width:String = null;
    var height:String = null;
    var left:String = null;
    var right:String = null;
    var top:String = null;
    var bottom:String = null;
    var xcenter:String = null;
    var ycenter:String = null;
    var listento:Array = null;
    var visible:Boolean = true;
    var maxwidth:Number = null;
    var minwidth:Number = null;
    var maxheight:Number = null;
    var minheight:Number = null;
    var guides:Object = null; // Associative array.
    var styles:Object = null; // Associative array.
    var cursors:Object = null; // Associative array.
    var strings:Object = null; // Associative array.
    
    var __width:Number = null;
    var __height:Number = null;
    
    // Some properties used for components to wait for each other at init time.
    private var initAdapters:Array = null;
    private var inited:Boolean = false;
    
    // Some adapters for containers and their content to adapt to each other's state.
    private var parentChildComponentAdapter:ParentChildComponentAdapter = null;
    private var visibleAdapter:VisibleAdapter = null;
    
    /** @component AbstractComponent
    * Abstract superclass for all components.
    * @file AbstractComponent.as (sourcefile)
    * @file InitAdapter.as (sourcefile)
    * @file ParentChildComponentAdapter.as (sourcefile)
    * @file VisibleAdapter.as (sourcefile)
    */
    function AbstractComponent() {
        if (_parent._parent == null) {
            var textField:TextField = createTextField("mTextField", 0, 0, 0, 550, 400);
            textField.html = true;
            textField.htmlText = "<P ALIGN='CENTER'><FONT FACE='Helvetica, Arial' SIZE='12' COLOR='#000000' LETTERSPACING='0' KERNING='0'><B>AbstractComponent</B> - www.flamingo-mc.org</FONT></P>";
            
            return;
        }
        
        _global.flamingo.correctTarget(_parent, this);
    }
    
    function onLoad():Void {
        if (_parent._parent == null) {
            return;
        }
        setBaseConfig();
        setCustomConfig();
        wait();
    }
    
    /**
    * Sets the component's base configuration, which comprises of the 19 base properties.
    */
    function setBaseConfig():Void {
   
        // Retrieves the default configuration for the component, in order to set the base properties.
        var defaultConfig:XMLNode = _global.flamingo.getDefaultXML(this);
        _global.flamingo.parseXML(this, defaultConfig);
        
        // Retrieves the application configurations for the component, in order to set the base properties.
        var appConfigs:Array = _global.flamingo.getXMLs(this);
        for (var i = 0; i < appConfigs.length; i++) {
            _global.flamingo.parseXML(this, XMLNode(appConfigs[i]));
        }
        
        if (listento == null) {
            listento = new Array();
        }
    }
	
	function setAttribute(name:String, value:String):Void {
	}
	
    
    /**
    * Waits for the "listento" components to init before going to the afterLoad() method.
    */
    function wait():Void {
        initAdapters = new Array();
        if (listento != null) {
        		addInitAdapters(listento);
				}
        if (initAdapters.length == 0) {
            afterLoad();
        }
    }
    
    /**
    * 
    */
    private function addInitAdapters(ids2WaitFor:Array):Void {
        var component:Object = null;
        var initAdapter:InitAdapter = null;
        for (var i:String in ids2WaitFor) {
            component = _global.flamingo.getComponent(ids2WaitFor[i]);
            if ((component == null) || ((component instanceof AbstractComponent) && (!component.isInited()))) {
                initAdapter = new InitAdapter(this);
                initAdapters.push(initAdapter);
                //_global.flamingo.tracer(this + " wait for " + ids2WaitFor[i] + " i = " + i);
                _global.flamingo.addListener(initAdapter, ids2WaitFor[i], this);
            }
        }    
    }
    
    /**
    * Removes a listener to a "listento" component after that "listento" component has raised an init event.
    * @attr initAdapter:InitAdapter Listener to be removed.
    */
    function removeInitAdapter(initAdapter:InitAdapter):Void {
        for (var i:String in initAdapters) {
            if (initAdapters[i] == initAdapter) {
                initAdapters.splice(int(Number(i)), 1);
				
                _global.flamingo.removeListener(initAdapter, listento[i], this);
                
                if (initAdapters.length == 0) {
                    afterLoad();
                }
                return;
            }
        }
    }
    
    /**
    * Finishes the init state of the component, calling the component's init() method.
    * This will raise the onInit event.
    */
    function afterLoad():Void {
        //addComposites after dependencies are loaded
        addComposites();

        // Removes the configurations for the component from the Flamingo framework.
        _global.flamingo.deleteXML(this);
        
        setVisible(visible);
        var bounds:Object = _global.flamingo.getPosition(this);
        setBounds(bounds.x, bounds.y, bounds.width, bounds.height);
        
        parentChildComponentAdapter = new ParentChildComponentAdapter(this);
        _global.flamingo.addListener(parentChildComponentAdapter, _global.flamingo.getParent(this), this);
        
        // If the component's immediate parent is a window, the component will become invisible when the window is closed. If this behavior is not desired, configure an extra container between the window and its content. That way the window will not be the component's immediate parent anymore.
        if (_parent._parent._parent._name == "mWindow") {
            visibleAdapter = new VisibleAdapter(this);
            _global.flamingo.addListener(visibleAdapter, _parent._parent._parent._parent, this);
        }
        
        init();
        inited = true;
        _global.flamingo.raiseEvent(this, "onInit", this);
        
        layout();
    }
    
    /**
    * Sets the component's custom configuration, which comprises of the properties not in the "base" set.
    */
    function setCustomConfig():Void {
        // Retrieves the default configuration for the component, in order to set the custom properties.
        var defaultConfig:XMLNode = _global.flamingo.getDefaultXML(this);
        setCustomProperties(defaultConfig);
        
        // Retrieves the application configurations for the component, in order to set the custom properties.
        var appConfigs:Array = _global.flamingo.getXMLs(this);
        for (var i = 0; i < appConfigs.length; i++) {
            setCustomProperties(XMLNode(appConfigs[i]));
        }
    }
    
    /**
    * Sets the component's custom properties. Properties can be attributes and composites.
    * @attr config:XMLNode Configuration in the form of an xml.
    */
    function setCustomProperties(config:XMLNode):Void {
        // Parses the xml attributes to object attributes.
        for (var attributeName:String in config.attributes) {
            var value:String = config.attributes[attributeName];
            setAttribute(attributeName, value);
        }
        
    }

    private function addComposites():Void {
        var appConfigs:Array = _global.flamingo.getXMLs(this);
        for (var i = 0; i < appConfigs.length; i++) {
            var config:XMLNode = XMLNode(appConfigs[i]);
		        // Parses the xml child nodes to object composites.
		        for (var i:Number = 0; i < config.childNodes.length; i++) {
		            var xmlNode:XMLNode = config.childNodes[i];
		            var nodeName:String = xmlNode.nodeName;
		            if (nodeName.indexOf(":") > -1) {
		                nodeName = nodeName.substr(nodeName.indexOf(":") + 1);
		            }
		            addComposite(nodeName, xmlNode);
		        }
        }
    }    

    
    function addComposite(name:String, config:XMLNode):Void { }
    
    /**
    * Shows or hides the component.
    * In case that the component is a direct child of a Window component, shows or hides the Windows component likewise.
    * This will raise the onSetVisible event.
    * @param visible:Boolean True or false.
    */
    function setVisible(visible:Boolean):Void {
        if (this.visible != visible) {
            this.visible = visible;
            _visible = visible;
            
            _global.flamingo.raiseEvent(this, "onSetVisible", this, visible);
            
            // If the component's immediate parent is a window, the window will get the same visibility as given to the component. This is to make a window close on setting its content invisible. If this behavior is not desired, configure an extra container between the window and its content. That way the window will not be the component's immediate parent anymore.
            if (_parent._parent._parent._name == "mWindow") {
                _parent._parent._parent._parent.setVisible(visible);
            }
        }
    }
    
    /**
    * Sets the position and the size of the component.
    * This will raise the onResize event.
    * @param x:Number The x position.
    * @param y:Number The y position.
    * @param width:Number The width.
    * @param height:Number The height.
    */
    function setBounds(x:Number, y:Number, width:Number, height:Number):Void {
        _x = x;
        _y = y;
        __width = width;
        __height = height;
        
        if (inited) {
            layout();
        }
        
        _global.flamingo.raiseEvent(this, "onResize", this);
    }
    
    function init():Void { }
    
    /**
    * Returns true if the component has finished the init phase. In other words: the component's init() method has run and the onInit event been fired.
    */
    function isInited():Boolean {
        return inited;
    }
    
    function layout():Void { }
    
    function go():Void { }
    
    function getComponentName():String {
        return componentID.split(" ")[0];
    }
    
    function getParent(componentName:String) {
        if (componentName == null) {
            return _global.flamingo.getParent(this);
        } else {
            var parent:MovieClip = _global.flamingo.getParent(this);
            if (parent == null) {
                return null;
            }
            while (!(parent == _root)) {
                if (parent.getComponentName() == componentName) {
                    return parent;
                }
                parent = _global.flamingo.getParent(parent);
            }
        }
        return null;
    }
    
    /**
    * Displays the values of the component's 19 base properties plus the bounds properties.
    * This can be useful for debugging.
    */
    function traceProperties():Void {
        _global.flamingo.tracer(this);
        
        _global.flamingo.tracer("NAME " + name);
        _global.flamingo.tracer("WIDTH " + width);
        _global.flamingo.tracer("HEIGHT " + height);
        _global.flamingo.tracer("LEFT " + left);
        _global.flamingo.tracer("RIGHT " + right);
        _global.flamingo.tracer("TOP " + top);
        _global.flamingo.tracer("BOTTOM " + bottom);
        _global.flamingo.tracer("XCENTER " + xcenter);
        _global.flamingo.tracer("YCENTER " + ycenter);
        _global.flamingo.tracer("LISTENTO " + listento.toString());
        _global.flamingo.tracer("VISIBLE " + visible);
        _global.flamingo.tracer("MAXWIDTH " + maxwidth);
        _global.flamingo.tracer("MINWIDTH " + minwidth);
        _global.flamingo.tracer("MAXHEIGHT " + maxheight);
        _global.flamingo.tracer("MINHEIGHT " + minheight);
        
        for (var i:String in guides) {
            _global.flamingo.tracer("GUIDE " + guides[i]);
        }
        for (var i:String in styles) {
            _global.flamingo.tracer("STYLE " + styles[i]);
        }
        for (var i:String in cursors) {
            _global.flamingo.tracer("CURSOR " + cursors[i]);
        }
        for (var i:String in strings) {
            for (var j:String in strings[i]) {
                _global.flamingo.tracer("STRING " + i + " " + j + " " + strings[i][j]);
            }
        }
        
        _global.flamingo.tracer("__X " + _x);
        _global.flamingo.tracer("__Y " + _y);
        _global.flamingo.tracer("__WIDTH " + __width);
        _global.flamingo.tracer("__HEIGHT " + __height);
    }
    
}