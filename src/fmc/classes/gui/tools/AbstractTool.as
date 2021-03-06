/*-----------------------------------------------------------------------------
Copyright (C) 2006  Menko Kroeske

This file is part of Flamingo MapComponents.

Flamingo MapComponents is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
-----------------------------------------------------------------------------*/
/**
 * Abstract tool. Implement this when you want to create a tool implementation
 * @author Roy Braam
 */
import core.AbstractPositionable;
import gui.tools.ToolGroup;
import tools.Logger;
import gui.button.AbstractButton;

class gui.tools.AbstractTool extends AbstractButton
{
	private var _holder:MovieClip;
	private var _toolGroup:ToolGroup;
	
	//Is the tool active (used at the moment)
	private var _active:Boolean;
	
	//the map listener. If this tool is active this object will listen to the actions done by the user.
	private var _lMap:Object;
	
	//scroll properties:
	private var _zoomscroll:Boolean;
	
	/**
	 * Constructor for AbstractTool.
	 * @param	id the id of the button
	 * @param	toolGroup the toolgroup where this tool is in.
	 * @param	container the movieclip that holds this button 
	 * @see 	gui.button.AbstractButton
	 */
	public function AbstractTool(id, toolGroup:ToolGroup, container:MovieClip) {			
		super(id, container);
		this.toolGroup = toolGroup;
		this.parent = toolGroup;
		//init vars
		this.lMap = new Object();		
		this.active = false;
		this.zoomscroll = true;
		
		var thisObj:AbstractTool = this;
		//add mousewheel event to tool:
		this.lMap.onMouseWheel = function(map:MovieClip, delta:Number, xmouse:Number, ymouse:Number, coord:Object) {
			thisObj.onMouseWheel(map, delta, xmouse, ymouse, coord);
			
		};
			
	}	
	/**
	 * onMouseWheel
	 * @param	map
	 * @param	delta
	 * @param	xmouse
	 * @param	ymouse
	 * @param	coord
	 */
	public function onMouseWheel(map:MovieClip, delta:Number, xmouse:Number, ymouse:Number, coord:Object) {
		var thisObj:AbstractTool = this;
		if (thisObj.zoomscroll) {
			if (!thisObj._parent.updating) {
				thisObj._parent.cancelAll();
				var zoom;
				if (delta<=0) {
					zoom = 80;
				} else {
					zoom = 120;
				}
				var w = map.getWidth();
				var h = map.getHeight();
				var c = map.getCenter();
				var cx = (w/2)-((w/2)/(zoom/100));
				var cy = (h/2)-((h/2)/(zoom/100));
				var px = (coord.x-c.x)/(w/2);
				var py = (coord.y-c.y)/(h/2);
				coord.x = c.x+(px*cx);
				coord.y = c.y+(py*cy);
				map.moveToPercentage(zoom, coord, 500, 0);
				thisObj._parent.updateOther(map, 500);
			}
		}
	}
	
	/***********************************************************
	 * Special getters / setters.... TODO: Still needed or implement in the other setters and getters?
	 */
	/**
	 * Returns the real parent
	 * @return the real parent In this case its always the borderNavigation
	 */
	public function getParent():Object {
		return this.toolGroup;
	}	 
	 
	/**
	 * Get the listento. Default its the listento of the toolgroup
	 */
	public function get listento():Array 
	{
		if (this.toolGroup != null) {
			return this.toolGroup.listento;
		}else {
			return this._listento;
		}
	}
	/**
	 * Set the listento.
	 */
	public function set listento(listenTo:Array):Void {
		_listento = listenTo;
	}
	/**
	 * Enable/disable (grayout) the tool
	 * @param	b true(enable) or false(disable
	 */
	public function setEnabled(b:Boolean):Void{
		if (!b && this._active) {			
			this.setActive(false);
			this.toolGroup.setCursor(undefined);	
		}
		super.setEnabled(b);
	}
	/**
	 * Active/deactivate the tool
	 * @param	active true (Active) or false(deactivate)
	 */ 
	public function setActive(active:Boolean):Void {
		//turn off
		if (this.active && !active) {
			flamingo.removeListener(this.lMap, this.listento, this.listento);		
			if (toolGroup!=null)
				this.toolGroup.setCursor(undefined);
			this.mcDown._visible = false;
			this.mcOver._visible = false;
			this.mcUp._visible = true;
			flamingo.raiseEvent(this, "onDeactivate", this);
			//TODO: Set correct cursor this.setCursor(mc.cursors[cursorid]);
		}//turn on
		else if (!this.active && active) {
			flamingo.addListener(this.lMap, this.listento, this.listento);
			if (toolGroup != null)
				this.toolGroup.setCursor(this.cursors[this.cursorId]);
			this.mcUp._visible = false;
			this.mcOver._visible = false;
			this.mcDown._visible = true;
			flamingo.raiseEvent(this, "onActivate", this);
			//TODO: Set correct cursor this.setCursor(mc.cursors[cursorid]);
			//see toolgroup initTool
		}
		this._active = active;		
	}
	/**
	 * Returns true if this button is clickable
	 */
	public function isClickable():Boolean {
		return super.isClickable() && !this.active;
	}
	/***** Tool defaults, do nothing ******/
	function startIdentifying() {}
	function stopIdentifying() {}
	function startUpdating() {}
	function stopUpdating() {}
	
	/**
	 * Handles the press of the button.
	 */
	public function onRelease() { 
		this.toolGroup.setTool(this.id);
	}
	/*********************** Getters and Setters ***********************/
	/**
	 * getter  active
	 */
	public function get active():Boolean {
		return this._active;
	}
	/**
	 * setter  active
	 */
	public function set active(value:Boolean) {
		this._active = value;
	}
	
	/**
	 * getter  toolGroup
	 */
	public function get toolGroup():ToolGroup {
		return _toolGroup;
	}
	
	/**
	 * setter  toolGroup
	 */
	public function set toolGroup(value:ToolGroup):Void {
		_toolGroup = value;
	}
	
	/**
	 * getter  enabled
	 */
	public function get enabled():Boolean {
		return _enabled;
	}
	
	/**
	 * setter  enabled
	 */
	public function set enabled(value:Boolean) {
		this._enabled = value;
	}
	
	/**
	 * getter  lMap
	 */
	public function get lMap():Object {
		return _lMap;
	}
	
	/**
	 * setter  lMap
	 */
	public function set lMap(value:Object):Void {
		_lMap = value;
	}
	
	/**
	 * getter  zoomscroll
	 */
	public function get zoomscroll():Boolean {
		return _zoomscroll;
	}
	
	/**
	 * setter  zoomscroll
	 */
	public function set zoomscroll(value:Boolean):Void {
		_zoomscroll = value;
	}
	
}