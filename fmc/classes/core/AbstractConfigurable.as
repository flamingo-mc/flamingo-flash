/**
 * ...
 * @author Roy Braam
 */

import core.AbstractPositionable;
import tools.Logger;
class core.AbstractConfigurable extends AbstractPositionable{
	
	public function AbstractConfigurable(id:String, container:MovieClip) {
		super(id, container);				
	}
	
	public function init():Void {
		/*//set visible false while configuring
		this._visible = false;
		//set defaults defaults
		var xmlNode:XMLNode = this.stringToXMLNode(defaultXML);
		this.setConfig(xmlNode);
		delete xmlNode;
		//get the custom xml's
		var xmls:Array = flamingo.getXMLs(this);
		for (var i = 0; i < xmls.length; i++) {			
			this.setConfig(stringToXMLNode(xmls[i]));
		}
		delete xmls;
		//remove xml from repository
		flamingo.deleteXML(this);
		this._visible = visible;*/
	}
	
	public function setConfig(xml:XMLNode) {
		//parse the default attributes.
		flamingo.parseXML(this, xml);
		//set the custom attributes
		for (var attributeName:String in xml.attributes) {
            var value:String = xml.attributes[attributeName];
            setAttribute(attributeName, value);
        }	
		//set the custom composites
		addComposites(xml);
	}
	
	function setAttribute(name:String, value:String):Void {
		Logger.console("!!!!!AbstractConfigurable.setAttribute(name:String, value:String) must be implemented in subclass");
	}	
	
	function addComposites(config:XMLNode) {
		for (var j:Number = 0; j < config.childNodes.length; j++) {
			var xmlNode:XMLNode = config.childNodes[j];
			var nodeName:String = xmlNode.nodeName;
			if (nodeName.indexOf(":") > -1) {
				nodeName = nodeName.substr(nodeName.indexOf(":") + 1);
			}
			addComposite(nodeName, xmlNode);
		}
	}
	
	function addComposite(name:String, config:XMLNode):Void { 
		Logger.console("!!!!!AbstractConfigurable.addComposite(name:String, config:XMLNode) must be implemented in subclass");
	}
	
	
	/***********************************************
	 * Helper functions
	 */
	/**
	 * From string to xmlnode
	 * @param	xmlString
	 */
	public function stringToXMLNode(xmlString:String) {
		var xml:XML = new XML(String(xmlString));
		return xml.firstChild;
	}
}