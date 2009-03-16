﻿/*-----------------------------------------------------------------------------
* This file is part of Flamingo MapComponents.
* Author: Michiel J. van Heek.
* IDgis bv
 -----------------------------------------------------------------------------*/
import flamingo.geometrymodel.*;

interface flamingo.event.GeometryListener {

	public function onChangeGeometry(geometry:Geometry):Void;
    	
	public function onAddChild(geometry:Geometry,child:Geometry) : Void;

}