﻿/*-----------------------------------------------------------------------------
* This file is part of Flamingo MapComponents.
* Author: Michiel J. van Heek.
* IDgis bv
 -----------------------------------------------------------------------------*/
import event.*;

import flash.external.ExternalInterface;

import core.AbstractComponent;
import tools.Logger;
/**
 * event.StateEventDispatcher
 */
class event.StateEventDispatcher {
    
    private var eventListeners:Object = null; // Associative array;
    /**
     * constructor
     */
    function StateEventDispatcher() {
        eventListeners = new Object();
    }
    /**
     * addEventListener
     * @param	stateEventListener
     * @param	sourceClassName
     * @param	actionType
     * @param	propertyName
     */
    function addEventListener(stateEventListener:StateEventListener, sourceClassName:String, actionType:Number, propertyName:String):Void {
        var key:String = sourceClassName.toUpperCase() + "_" + actionType + "_" + propertyName.toUpperCase();
        
        if (eventListeners[key] == null) {
            eventListeners[key] = new Array();
        } else {
            for (var i:String in eventListeners[key]) {
                if (eventListeners[key][i] == stateEventListener) {
                    trace("EXCEPTION in event.StateEventDispatcher.addEventListener(" + sourceClassName + ", " + propertyName + ")");
                    return;
                }
            }
        }
        
        eventListeners[key].push(stateEventListener);
    }
    /**
     * removeEventListener
     * @param	stateEventListener
     * @param	sourceClassName
     * @param	actionType
     * @param	propertyName
     */
    function removeEventListener(stateEventListener:StateEventListener, sourceClassName:String, actionType:Number, propertyName:String):Void {
        var key:String = sourceClassName.toUpperCase() + "_" + actionType + "_" + propertyName.toUpperCase();
        
        if (eventListeners[key] == null) {
            trace("EXCEPTION in event.StateEventDispatcher.removeEventListener(" + sourceClassName + ", " + propertyName + ")");
            return;
        }
        
        for (var i:String in eventListeners[key]) {
            if (eventListeners[key][i] == stateEventListener) {
                delete eventListeners[key][i];
                return;
            }
        }
        
        trace("EXCEPTION in event.StateEventDispatcher.removeEventListener(" + sourceClassName + ", " + propertyName + ")");
        return;
    }
    /**
     * dispatchEvent
     * @param	stateEvent
     */
    function dispatchEvent(stateEvent:StateEvent):Void {
        var sourceClassName:String = stateEvent.getSourceClassName();
        var actionType:Number = stateEvent.getActionType();
        var propertyName:String = stateEvent.getPropertyName();
        var key:String = sourceClassName.toUpperCase() + "_" + actionType + "_" + propertyName.toUpperCase();
        if (eventListeners[key] == null) {
            return;
        }
        var comp:AbstractComponent = stateEvent.getEventComp();
        _global.flamingo.raiseEvent(comp,"onStateEvent", stateEvent.toString()); 
        for (var i:Number = 0; i < eventListeners[key].length; i++) { // Dispatches the event in the same order as which the listeners were added.
            StateEventListener(eventListeners[key][i]).onStateEvent(stateEvent);
        }
     }
    
}
