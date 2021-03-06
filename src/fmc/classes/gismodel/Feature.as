﻿/*-----------------------------------------------------------------------------
* This file is part of Flamingo MapComponents.
* Author: Michiel J. van Heek.
* IDgis bv
* Changes by author: Maurits Kelder, B3partners bv
 -----------------------------------------------------------------------------*/
import gismodel.*;

import event.*;
import coremodel.service.*;
import coremodel.service.wfs.*;
import geometrymodel.Geometry;
import geometrymodel.GeometryTools;

import geometrymodel.Envelope;
import tools.Logger;
/**
 * gismodel.Feature
 */
class gismodel.Feature {
    
    private var layer:Layer = null;
    private var serviceFeature:ServiceFeature = null;
    private var id:String = null;
    private var geometry:Geometry = null;
    private var values:Array = null;
    
    private var stateEventDispatcher:StateEventDispatcher = null;
    /**
     * constructor
     * @param	layer
     * @param	serviceFeature
     * @param	id
     * @param	geometry
     * @param	values
     * @param	ownerName
     */
    function Feature(layer:Layer, serviceFeature:ServiceFeature, id:String, geometry:Geometry, values:Array, ownerName:String) {
        if (layer == null) {
            _global.flamingo.tracer("Exception in gismodel.Feature.<<init>>(" + id + ")\nNo layer given.");
            return;
        }
        if (id == null) {
            _global.flamingo.tracer("Exception in gismodel.Feature.<<init>>()\nNo id given.");
            return;
        }
        if (geometry == null) {
            _global.flamingo.tracer("Exception in gismodel.Feature.<<init>>(" + id + ")\nNo geometry given.");
            return;
        }
        var geometryTypes:Array = layer.getGeometryTypes();
        if (geometryTypes.length > 0) {
            var clazz:Function = null;
            var match:Boolean = false;
            for (var i:String in geometryTypes) {
                clazz = GeometryTools.getGeometryClass(geometryTypes[i]);
                if (geometry instanceof clazz) {
                    match = true;
                    break;
                }
            }
            if (!match) {
                _global.flamingo.tracer("Exception in gismodel.Feature.<<init>>(" + id + ")\nType of the given geometry does not match any of the geometry types of the layer.");
                return;
            }
        }
        var properties:Array = layer.getProperties();
        if ((values != null) && (values.length != properties.length)) {
            _global.flamingo.tracer("Exception in gismodel.Feature.<<init>>(" + id + ", " + values.toString() + ")\nNumber of given values does not match the number of properties of the layer.");
            return;
        }
        if (values == null) {	
            values = new Array();
            var defaultValue:String = null;
            for (var i:Number = 0; i < properties.length; i++) {
                defaultValue = Property(properties[i]).getDefaultValue();
				if (serviceFeature != null) {
                	serviceFeature.setValue(properties[i].getName(), defaultValue);
            	}
                values.push(defaultValue); // Default value may be null.
            }
            var ownerPropertyName:String = layer.getOwnerPropertyName();
            if ((ownerPropertyName != null) && (ownerName != null)) {
                values[layer.getPropertyIndex(ownerPropertyName)] = ownerName;
            }
        }
        
        var whereClauses:Array = layer.getWhereClauses();
        var whereClause:WhereClause = null;
        var propertyIndex:Number = -1;
        var value:String = null;
        for (var i:String in whereClauses) {
            whereClause = WhereClause(whereClauses[i]);
            propertyIndex = layer.getPropertyIndex(whereClause.getPropertyName());
            if (propertyIndex > -1) {
                value = whereClause.getValue();
                if (values[propertyIndex] == null) {
                    values[propertyIndex] = value;
                } else if (values[propertyIndex] != value) {
                    _global.flamingo.tracer("Exception in gismodel.Feature.<<init>>(" + id + ", " + values.toString() + ")");
                    return;
                }
            }
        }
        
        this.layer = layer;
        this.serviceFeature = serviceFeature;
        this.id = id;
        this.geometry = geometry;
        this.values = values;
        stateEventDispatcher = new StateEventDispatcher();
    }
    /**
     * getLayer
     * @return
     */
    function getLayer():Layer {
        return layer;
    }
    /**
     * getServiceFeature
     * @return
     */
    function getServiceFeature():ServiceFeature {
        return serviceFeature;
    }
    /**
     * getID
     * @return
     */
    function getID():String {
        return id;
    }
    /**
     * getGeometry
     * @return
     */
    function getGeometry():Geometry {
        return geometry;
    }
    /**
     * getEnvelope
     * @return
     */
    function getEnvelope():Envelope {
    	return geometry.getEnvelope();
    }	
    /**
     * setValues
     * @param	values
     */
    function setValues(values:Array):Void {
        var properties:Array = layer.getProperties();
        if ((values == null) || (values.length != properties.length)) {
            _global.flamingo.tracer("Exception in gismodel.Feature.setValues(" + values.toString() + ")");
            return;
        }
        
        var property:Property = null;
        var value:Object = null;
        for (var i:Number = 0; i < properties.length; i++) {
            property = Property(properties[i]);
            value = values[i];
            if (property.isImmutable()) {
                continue;
            }
            
            this.values[i] = value;
            
            if (serviceFeature != null) {
            	//_global.flamingo.tracer("Feature setValues naar serviceFeature setValue for:" + property.getName() + " value = " + value);
                serviceFeature.setValue(property.getName(), value);
            }
        }
        if (serviceFeature != null) {
            layer.addOperation(new Update(serviceFeature));
        }
        stateEventDispatcher.dispatchEvent(new StateEvent(this, "Feature", StateEvent.CHANGE, "values", layer.getGIS()));
    }
    /**
     * setValue
     * @param	name
     * @param	value
     */
    function setValue(name:String, value:String):Void {
        var propertyIndex:Number = layer.getPropertyIndex(name);
        if (propertyIndex == -1) {
            _global.flamingo.tracer("Exception in gismodel.Feature.setValue(" + name + ")\nGiven property does not exist.");
            return;
        }
        if (layer.getProperty(name).isImmutable()) {
            _global.flamingo.tracer("Exception in gismodel.Feature.setValue(" + name + ")\nGiven property is immutable.");
            return;
        }
        
        if (values[propertyIndex] != value) {
            values[propertyIndex] = value;
            
            if (serviceFeature != null) {
                serviceFeature.setValue(name, value);
                layer.addOperation(new Update(serviceFeature));
            }
            stateEventDispatcher.dispatchEvent(new StateEvent(this, "Feature", StateEvent.CHANGE, "values", layer.getGIS()));
        }
    }
    /**
     * getValues
     * @return
     */
    function getValues():Array {
        return values.concat();
    }
    /**
     * getValue
     * @param	propertyName
     * @return
     */
    function getValue(propertyName:String):String {
        var propertyIndex:Number = layer.getPropertyIndex(propertyName);
        if (propertyIndex == -1) {
            // _global.flamingo.tracer("Exception in gismodel.Feature.getValue(" + propertyName + ")");
            return null;
        }
        
        return values[propertyIndex];
    }
	/**
	 * getValueWithPropType
	 * @param	propType
	 * @return
	 */
    function getValueWithPropType(propType:String):String {
        var propertyIndex:Number = layer.getPropertyWithTypeIndex(propType);
        if (propertyIndex == -1) {
            // _global.flamingo.tracer("Exception in gismodel.Feature.getValueWithPropType(" + propertyName + ")");
            return null;
        }
        
        return values[propertyIndex];
    }
	/**
	 * getLabelText
	 * @return
	 */
    function getLabelText():String {
        var labelPropertyName:String = layer.getLabelPropertyName();
        if (labelPropertyName == null) {
            return null;
        }
        
        return getValue(labelPropertyName);
    }
    /**
     * addEventListener
     * @param	stateEventListener
     * @param	sourceClassName
     * @param	actionType
     * @param	propertyName
     */
    function addEventListener(stateEventListener:StateEventListener, sourceClassName:String, actionType:Number, propertyName:String):Void {
        if (sourceClassName + "_" + actionType + "_" + propertyName != "Feature_" + StateEvent.CHANGE + "_values") {
            _global.flamingo.tracer("Exception in gismodel.Feature.addEventListener(" + sourceClassName + ", " + propertyName + ")");
            return;
        }
        stateEventDispatcher.addEventListener(stateEventListener, sourceClassName, actionType, propertyName);
    }
    /**
     * removeEventListener
     * @param	stateEventListener
     * @param	sourceClassName
     * @param	actionType
     * @param	propertyName
     */
    function removeEventListener(stateEventListener:StateEventListener, sourceClassName:String, actionType:Number, propertyName:String):Void {
        if (sourceClassName + "_" + actionType + "_" + propertyName != "Feature_" + StateEvent.CHANGE + "_values") {
            _global.flamingo.tracer("Exception in gismodel.Feature.removeEventListener(" + sourceClassName + ", " + propertyName + ")");
            return;
        }
        stateEventDispatcher.removeEventListener(stateEventListener, sourceClassName, actionType, propertyName);
    }
	/**
	 * 
	 * @param	includePrefix
	 * @return the feature as object
	 * 	object["id"]= the id
	 * 	object["wktgeom"]= the geometry in wkt text
	 * 	object["fmc_layername"]= the layername from which the feature is given
	 * 	object["<propertyname without prefix and ':'>"]= the property value
	 */
    function toObject(includePrefix: Boolean):Object{
    	var returnValue:Object = new Object();
    		returnValue["id"]=getID();
    	if (getGeometry()!=null){    	
			returnValue["wktgeom"]=(getGeometry().toWKT());	
    	}
		if (layer!=null){
			returnValue["fmc_layername"]=layer.getName();
		}
    	var properties:Array = layer.getProperties();
    	for (var i:Number = 0; i < properties.length; i++) {
    		var property:Property = Property(properties[i]);
    		//var propertyIndex:Number = layer.getPropertyIndex(property.getName());
			var nameWithoutPrefix:String=property.getName();
			if (nameWithoutPrefix.indexOf(":")>=0 && !includePrefix){
				nameWithoutPrefix=nameWithoutPrefix.substr(nameWithoutPrefix.indexOf(":")+1);
			}
    		returnValue[nameWithoutPrefix]=getValue(property.getName());		
    	}
    	return returnValue;
    }
	
    /**
     * toString
     * @return
     */
    function toString():String {
        return "Feature(" + id + ")";
    }
    
}
