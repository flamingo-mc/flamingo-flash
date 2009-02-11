﻿// This file is part of Flamingo MapComponents.
// Author: Michiel J. van Heek.



/** @component EditBar
* A container that holds the commit button. 
* Flamingo has two buttons used for editing: the remove feature button, which removes the active feature from the feature model, 
* and the commit button, which commits the changes made within the feature model to the server. Please refer to the GIS component.
* @file flamingo/tpc/classes/flamingo/gui/EditBar.as  (sourcefile)
* @file flamingo/tpc/EditBar.fla (sourcefile)
* @file flamingo/tpc/EditBar.swf (compiled component, needed for publication on internet)
* @file flamingo/tpc/CommitButton.fla (sourcefile)
* @file flamingo/tpc/CommitButton.swf (compiled component, needed for publication on internet)
*/

/** @tag <tpc:EditBar>
* This tag defines an edit bar instance. The edit bar must be registered as a listener to an edit map. 
* Actually, the edit bar listens to the feature model of the edit map.
* @class flamingo.gui.EditBar extends AbstractContainer implements ActionEventListener 
* @hierarchy childnode of Flamingo or a container component.
* @example
	<Flamingo>
		<tpc:EditBar id="editBar" left="523" top="4" listento="editMap" backgroundalpha="0" borderalpha="0">
			...
		</tpc:EditBar>
	</Flamingo>	
*/

import flamingo.gui.*;

import flamingo.event.ActionEvent;
import flamingo.event.ActionEventListener;
import flamingo.gismodel.GIS;

class flamingo.gui.EditBar extends AbstractContainer implements ActionEventListener {
    
    private var gis:GIS = null;
    
    function init():Void {
		
        gis = _global.flamingo.getComponent(listento[0]).getGIS();
        
        var ids:Array = getComponents();
        for (var i:String in ids) {
            _global.flamingo.getComponent(ids[i]).setActionEventListener(this);
        }
    }
    
    function onActionEvent(actionEvent:ActionEvent):Void {
        var sourceClassName:String = actionEvent.getSourceClassName();
        var actionType:Number = actionEvent.getActionType();
        if (sourceClassName + "_" + actionType == "Button_" + ActionEvent.CLICK) {
            gis.commit();
        } else if (sourceClassName + "_" + actionType == "Confirmation_" + ActionEvent.CLICK) {
            var feature:flamingo.gismodel.Feature = gis.getActiveFeature();
            if (feature != null) {
                feature.getLayer().removeFeature(feature, true);
            }
        }
    }
    
}
