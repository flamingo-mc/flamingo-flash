﻿/*-----------------------------------------------------------------------------
* This file is part of Flamingo MapComponents.
* Author: Michiel J. van Heek.
* IDgis bv
 -----------------------------------------------------------------------------*/
/** @component GIS 
* A component without a graphical user interface, that serves as a model for the editing components, such as the edit map and the edit legend. 
* The feature model keeps the layer and feature data for all editing components that listen to this model.
* A feature model is organized hierarchically. It consists of zero of more layers, which in turn consist of zero of more features per layer. 
* Every level in the hierarchy broadcasts its own events. 
* For example: the feature model about adding and removing of layers, a layer about changing its visibility, and a feature about a change in its property values.
* @file flamingo/fmc/classes/flamingo/gismodel/GIS.as  (sourcefile)
* @file flamingo/fmc/GIS.fla (sourcefile)
* @file flamingo/fmc/GIS.swf (compiled component, needed for publication on internet)
* @file flamingo/fmc/classes/flamingo/gismodel/Layer.as 
* @file flamingo/fmc/classes/flamingo/gismodel/Property.as 
* @file flamingo/fmc/classes/flamingo/gismodel/Feature.as
* @file flamingo/fmc/classes/flamingo/gismodel/Style.as
* @file flamingo/fmc/classes/flamingo/gismodel/CreateGeometry.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/GeometryTools.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/Geometry.as (hierachical classes for the geometry model -> used for digitizing polygons, boxes and circles)
* @file flamingo/fmc/classes/flamingo/geometrymodel/GeometryFactory.as 
* @file flamingo/fmc/classes/flamingo/geometrymodel/GeometryParser.as 
* @file flamingo/fmc/classes/flamingo/geometrymodel/LinearRing.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/LineSegment.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/LineString.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/LineStringFactory.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/Point.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/PointFactory.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/Polygon.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/PolygonFactory.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/Envelope.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/Circle.as
* @file flamingo/fmc/classes/flamingo/geometrymodel/CircleFactory.as
*/

/** @tag <fmc:GIS>  
* This tag defines a feature model instance. A feature model can be registered as a listener of an authentication component. 
* If one or more layers within the feature model are protected with authorization, 
* the feature model must listen to the authentication component, which tells the feature model the roles of the current user.
* @class gismodel.GIS extends AbstractComponent
* @hierarchy childnode of Flamingo or a container component. 
* @example
	<Flamingo>
		<fmc:GIS  id="gis" authentication="authentication" listento="authentication" updatemaps="map,printMap0">
		...
		</fmc:GIS>
	</Flamingo>	
* @attr authentication Reference to the authentication component. This value must be equal to the “listento”.
* @attr updateMaps Comma seperate list of maps that should be updated after a commit to the server. Set this attribute when
* the Layers in your map(s) (LayerOGWMS, LayerArcIMS) are based on the same data as the (WFS)Layers in the GIS (EditMap)    
*/

/** @tag <fmc:Layer>
* This tag defines a layer instance.
* @class gismodel.Layer extends AbstractComposite
* @hierarchy childnode of GIS.
* @example
	<fmc:GIS  id="gis" authentication="authentication" listento="authentication" >
		<fmc:Layer title="Redlining" visible="true" labelpropertyname="app:label" roles="XDF56YZ">
		...
		</fmc:Layer>
		<fmc:Layer title="Luchthavens" visible="true" wfsurl="wfs::http://localhost:8080/flamingo-edit-server/services" 
			featuretypename="app:Airport" geometrytypes="Point" labelpropertyname="app:numFlights" roles="XDF56YT">
		...
		</fmc:Layer>
	</fmc:GIS>
* @attr title Name by which the layer is presented to the user, for example in the edit legend.
* @attr visible	(true, false, defaultvalue = false) Whether or not the layer's features be visible in the edit map.
* @attr wfsurl	URL to the server that serves the layer's features. Standard url format is used, with the exception that it is preceded by “wfs::”. 
* Currently, only the OGC web feature service protocol is supported.
* @attr featuretypename	Name of the feature type that defines the layer's features on the server.
* @attr geometrytypes(“Point”, “LineString”, “Polygon”, “Circle”, or a combination of these, comma-separated, no default value) 
* Geometry types that the user be able to draw when a new feature is created. 
* Every possible geometry type will appear as a create button in the edit legend.
* NB the geometrytype Circle not supported when editing WFS Layers, is only applicable for red-lining 
* @attr labelpropertyname Name of the property which value be shown on a label in the edit map, near the feature's geometry.
* @attr roles Names of the roles that are authorized to access the layer and its features. 
* If the current user has none of these roles, the layer will not be loaded in the feature model, 
* which means that it will not be visible in the map legend and the layer's features will not be visible in the edit map. 
* If no roles at all are configured for the layer, the layer is considered unprotected by authorization and will be loaded in the feature model regardless of the user's roles.
*/

/** @tag <fmc:Property>
* This tag defines a layer's feature property instance.
* @class gismodel.Property extends AbstractComposite
* @hierarchy childnode of Layer.
* @example
	<fmc:Layer name="redlining" title="Redlining" visible="true" labelpropertyname="app:label" roles="XDF56YZ">
	 	<fmc:Property name="app:label" title="Label" type="MultiLine"/>
		...
	</fmc:Layer>
	<fmc:Layer title="Luchthavens" visible="true" wfsurl="wfs::http://localhost:8080/flamingo-edit-server/services" 
		featuretypename="app:Airport" geometrytypes="Point" labelpropertyname="app:numFlights" roles="XDF56YT">
            <fmc:Property name="app:numFlights" title="Aantal vluchten" type="DropDown:50,100,120,250,450,900,2000"/>
            <fmc:Property name="app:name" title="Naam" type="SingleLine" defaultvalue="YAYA"/>
            <fmc:Property name="app:description" title="Omschrijving" type="MultiLine" immutable="true"/>
* @attr name (no default value) Name of the property, this should correspond with the feature type property name on the server (incl. namespace).			
* @attr title (default value: “”) Name by which the property is presented to the user, for example on a label in the edit properties component.
* @attr type (“SingleLine”, “MultiLine”, “DropDown”, default value = “SingleLine”) Presentation type of the property. 
* This type defines how the property will appear in the edit properties component. As a single line or multi line text input, 
* or a drop down list with fixed values.
* @attr defaultvalue Value that the property gets when a new feature is created.
* @attr immutable (true, false, default value: false) Whether or not the property value can be changed.
*/

/** @tag <fmc:Style>
* This tag defines a layer's feature style instance. All the layer's features will use this style to present themselves in the edit map.
* @class gismodel.Style extends AbstractComposite
* @hierarchy childnode of Layer.
* @example
	<fmc:Layer name="redlining" title="Redlining" visible="true" labelpropertyname="app:label" roles="XDF56YZ">
	 	...
		<fmc:Style fillcolor="0xFFCC00" fillopacity="30" strokecolor="0xFFCC00" strokeopacity="100"/>
	</fmc:Layer>
* @attr fillcolor (0x000000 – 0xFFFFFF, no default value) Fill color. Not applicable to point or line string geometries.
* @attr fillopacity	(0 – 100, no default value) Fill opacity. A value of 0 means completely transparent. Not applicable to point or line string geometries. If a feature's geometry is not completely transparent, a click on its fill will make the feature the active feature. If the geometry is completely transparent the user's mouse will click right through it.
* @attr strokecolor	(0x000000 – 0xFFFFFF, no default value) Stroke color.
* @attr strokeopacity (0 – 100, no default value) Stroke opacity. A value of 0 means completely transparent.
*/


import gismodel.*;

import event.*;
import geometrymodel.Envelope;
import core.AbstractComponent;

class gismodel.GIS extends AbstractComponent {
    
    private var authentication:MovieClip = null;
    private var layers:Array = null;
    private var updateMaps:Array = null;
    private var activeFeature:Feature = null;
    private var createGeometry:CreateGeometry = null;
    private var serversBusy:Number = 0;
    
    private var stateEventDispatcher:StateEventDispatcher = null;
    
	
	function onLoad(){
		layers = new Array();
		super.onLoad();
		
	}
	
	function init():Void{
		stateEventDispatcher = new StateEventDispatcher();
		
        
    }
    
    function setAttribute(name:String, value:String):Void {
		if (name == "updatemaps") {
			updateMaps = value.split(",");
        }
		if (name == "authentication") {
			authentication = _global.flamingo.getComponent(value);
        }
        super.setAttribute(name, value);
    }
    
    function addComposite(name:String, xmlNode:XMLNode):Void {
        if (name == "Layer") {
			var layer:Layer = new Layer(this,xmlNode);
            addLayer(layer);
        }
    }
    
    
    function addLayer(layer:Layer):Void {
        if (layer == null) {
            _global.flamingo.tracer("Exception in gismodel.GIS.addLayer()\nNo layer given.");
            return;
        }
        if (getLayer(layer.getName()) != null) {
            _global.flamingo.tracer("Exception in gismodel.GIS.addLayer(" + layer.getName() + ")\nGiven layer already exists.");
            return;
        }
        var roles:Array = layer.getRoles();
        var authorized:Boolean = false;
        //_global.flamingo.tracer("GIS addLayer roles = " + roles + " authentication = " + authentication);
        if (roles.length == 0) {
            authorized = true;
        }
        for (var i:String in roles) {
            if ((authentication != null) && (authentication.hasRole(roles[i]))) {
                authorized = true;
            }
        }
        //_global.flamingo.tracer("GIS addLayer authorized = " + authorized);
        if (!authorized) {
            return;
        }
        layers.push(layer);
        stateEventDispatcher.dispatchEvent(new AddRemoveEvent(this, "GIS", "layers", new Array(layer), null, this));
    }
    
    function getLayers():Array {
        return layers.concat();
    }
    
    function getLayer(name:String):Layer {
        var layer:Layer = null;
        for (var i:String in layers) {
            layer = Layer(layers[i]);
            if (layer.getName() == name) {
                return layer;
            }
        }
        return null;
    }
    
    function getLayerPosition(layer:Layer):Number {
        for (var i:Number = 0; i < layers.length; i++) {
            if (layers[i] == layer) {
                return i;
            }
        }
        return -1;
    }

    function getEnvelope():Envelope {
    	var layer:Layer = layers[0];
    	 var minx:Number = layer.getEnvelope().getMinX();  
    	 var maxx:Number = layer.getEnvelope().getMaxX();
    	 var miny:Number = layer.getEnvelope().getMinY(); 
    	 var maxy:Number = layer.getEnvelope().getMaxY();
    	  
    	 for (var i:Number = 1; i < layers.length; i++) {
    	 	layer = layers[i];
    	 	if (layer.getEnvelope().getMinX() < minx) {
    	 		minx = layer.getEnvelope().getMinX();
    	 	}
    	 	if (layer.getEnvelope().getMaxX() > maxx) {
    	 		maxx = layer.getEnvelope().getMaxX();
    	 	}
    	 	if (layer.getEnvelope().getMinY() < miny) {
    	 		miny = layer.getEnvelope().getMinY();
    	 	}
    	 	if (layer.getEnvelope().getMaxY() > maxy) {
    	 		maxy = layer.getEnvelope().getMaxY();
    	 	}
    	 }	   	 
    	 return new Envelope(minx,miny,maxx,maxy);
    }
    
    function setActiveFeature(activeFeature:Feature):Void {
        if (this.activeFeature == activeFeature) {
            return;
        }
        
        var previousActiveFeature:Feature = this.activeFeature;
        this.activeFeature = activeFeature;
        
        stateEventDispatcher.dispatchEvent(new ChangeEvent(this, "GIS", "activeFeature", previousActiveFeature, this));
    }
    
    function getActiveFeature():Feature {
        return activeFeature;
    }
    
    function setCreateGeometry(createGeometry:CreateGeometry):Void {
        this.createGeometry = createGeometry;
            
        stateEventDispatcher.dispatchEvent(new StateEvent(this, "GIS", StateEvent.CHANGE, "createGeometry", this));
    }
    
    function getCreateGeometry():CreateGeometry {
        return createGeometry;
    }
    
    
    function commit():Void {
        for (var i:String in layers) {
            if (Layer(layers[i]).isTransactionProblematic4Server()) {
                _global.flamingo.tracer("Exception in gismodel.GIS.commit()\nAt least one of the layers, \"" + Layer(layers[i]).getName() +  "\", has problems to send its transaction to the server. Sending transactions is cancelled for all layers.");
                return;
            }
        }
        
        serversBusy += layers.length;
        for (var i:String in layers) {
            Layer(layers[i]).commit();
        }
    }
    
    function onServerReady():Void {
        serversBusy--;
        if ((serversBusy == 0) && (updateMaps!=null)) {
        	for (var i:String in updateMaps) {
        		var map:Object = _global.flamingo.getComponent(updateMaps[i]); 
        		map.update(0, true);
        	}
            
        }
    }
    
    function addEventListener(stateEventListener:StateEventListener, sourceClassName:String, actionType:Number, propertyName:String):Void {
        if (
                (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.CHANGE + "_extent")
             && (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.ADD_REMOVE + "_layers")
             && (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.CHANGE + "_activeFeature")
             && (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.CHANGE + "_createGeometry")
           ) {
            _global.flamingo.tracer("Exception in gismodel.GIS.addEventListener(" + sourceClassName + ", " + propertyName + ")");
            return;
        }
        stateEventDispatcher.addEventListener(stateEventListener, sourceClassName, actionType, propertyName);
    }
    
    function removeEventListener(stateEventListener:StateEventListener, sourceClassName:String, actionType:Number, propertyName:String):Void {
        if (
                (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.CHANGE + "_extent")
             && (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.ADD_REMOVE + "_layers")
             && (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.CHANGE + "_activeFeature")
             && (sourceClassName + "_" + actionType + "_" + propertyName != "GIS_" + StateEvent.CHANGE + "_createGeometry")
           ) {
            _global.flamingo.tracer("Exception in gismodel.GIS.removeEventListener(" + sourceClassName + ", " + propertyName + ")");
            return;
        }
        stateEventDispatcher.removeEventListener(stateEventListener, sourceClassName, actionType, propertyName);
    }
    
    function toString():String {
        return "GIS()";
    }
    
}