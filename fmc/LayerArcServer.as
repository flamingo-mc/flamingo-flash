﻿/*-----------------------------------------------------------------------------
Created by : Abeer.Mahdi@realworld-systems.com
		     Realworld systems 
			 tel: 0345 614406
-----------------------------------------------------------------------------*/
var version:String = "2.0.2";
//---------------------------------
//properties which can be set in ini
var visible:Boolean;
var fullextent:Object;
var server:String;
var servlet:String;
var mapservice:String;
var featurelimit:Number = 1;
var identifydistance:Number = 10;
var maptipdistance:Number = 10;
var legend:Boolean = false;
var legendurl:String;
var minscale:Number;
var maxscale:Number;
var identifyall:Boolean = false;
var maptipall:Boolean = true;
var retryonerror:Number = 0;
var timeout:Number = 10;
var backgroundcolor:Number = 0xFBFBFB;
var transcolor:Number = 0xFBFBFB;
var legendcolor:Number = 0xFFFFFF;
var identifyids:String;
var forceidentifyids:String;
var maptipids:String;
var hidelegendids:String;
var showlegendids:String;
var visibleids:String;
var hiddenids:String;
var outputtype:String = "png24";
var alpha:Number = 100;
//---------------------------------
var layers:Object = new Object();
var updating:Boolean = false;
var nrcache:Number = 0;
var map:MovieClip;
var caches:Object = new Object();
var thisObj:MovieClip = this;
var _identifylayers:Array;
var _maptiplayers:Array;
var identifyextent:Object;
var maptipcoordinate:Object;
var showmaptip:Boolean;
var canmaptip:Boolean = false;
var timeoutid:Number;
var initialized:Boolean = false;
var extent:Object;
var nrlayersqueried:Number;
var layerliststring:String;
//-------------------------------------------
//listenerobject for map
var lMap:Object = new Object();
lMap.onUpdate = function(map:MovieClip):Void  {
	thisObj.update();
};
lMap.onChangeExtent = function(map:MovieClip):Void  {
	thisObj.updateCaches();
};
lMap.onIdentify = function(map:MovieClip, identifyextent:Object):Void  {
	thisObj.identify(identifyextent);
};
lMap.onIdentifyCancel = function(map:MovieClip):Void  {
	thisObj.cancelIdentify();
};
lMap.onMaptip = function(map:MovieClip, x:Number, y:Number, coord:Object):Void  {
	thisObj._startMaptip(coord.x, coord.y);
};
lMap.onMaptipCancel = function(map:MovieClip):Void  {
	thisObj._stopMaptip();
};
flamingo.addListener(lMap, flamingo.getParent(this), this);
//listener for maptip connector
//-----------------------------------------------------------------
init();
//-----------------------------------
/** @tag <fmc:LayerArcServer>  
* This tag defines a ESRI ArcGIS Server layer.
* @hierarchy childnode of <fmc:Map> 
* @attr server  servername of the ArcGIS Server mapservice
* @attr mapservice  mapservicename
* @attr identifyall (defaultvalue = "false") true or false;  true= all layerid's will be identified, false = identify stops after identify success
* @attr visibleids Comma seperated list of layerid's (same as in axl) Id's in this list will be visible.
* @attr hiddenids Comma seperated list of layerid's (same as in axl) Id's in this list will be hidden.
* @attr identifyids Comma seperated list of layerid's (same as in axl) Id's in this list will be identified in the order of the list. Use keyword "#ALL#" to identify all layers.
* @attr maptipids Comma seperated list of layerid's (same as in axl) Id's in this list will be queried during a maptip event. Use keyword "#ALL#" to query all layers.
* @attr dataframe dataframename of the mapservice
*/
/** @tag <layer>  
* This defines a sublayer of an ArcGIS Server mapservice
* @hierarchy childnode of <fmc:LayerArcServer> 
* @attr id  layerid, same as in the axl.
* @attr subfields  Comma seperated list of fields, which will be identified.
* @attr identifydistance  (defaultvalue = "10") Distance in pixels for performing getFeatures request.
* @attr maptipdistance (defaultvalue = "10") Distance in pixels for performing getFeatures request for a maptip. 
* @attr featurelimit  (defaultvalue = "1") Number of features that will return after an identify.
* @attr query  The 'where' clause in the getImage and getFeatures request.
* @attr maptip Configuration string for a maptip. Fieldnames between square brackets will be replaced  with their actual values. For multi-language support use a standard string tag with id='maptip'.
*/
function init():Void {
	if (flamingo == undefined) {
		var t:TextField = this.createTextField("readme", 0, 0, 0, 550, 400);
		t.html = true;
		t.htmlText = "<P ALIGN='CENTER'><FONT FACE='Helvetica, Arial' SIZE='12' COLOR='#000000' LETTERSPACING='0' KERNING='0'><B>LayerArcServer "+this.version+"</B> - www.flamingo-mc.org</FONT></P>";
		return;
	}
	this._visible = false;
	map = flamingo.getParent(this);
	//defaults
	var xml:XML = flamingo.getDefaultXML(this);
	this.setConfig(xml);
	delete xml;
	//custom
	var xmls:Array = flamingo.getXMLs(this);
	for (var i = 0; i<xmls.length; i++) {
		this.setConfig(xmls[i]);
	}
	delete xmls;
	//remove xml from repository
	flamingo.deleteXML(this);
	this._visible = visible;
	flamingo.raiseEvent(this, "onInit", this);
}
/**
* Configurates a component by setting a xml.
* @attr xml:Object Xml or string representation of a xml.
*/
function setConfig(xml:Object) {
	if (xml == undefined) {
		return;
	}
	if (typeof (xml) == "string") {
		xml = new XML(String(xml)).firstChild;
	}
	//load default attributes, strings, styles and cursors                                           
	flamingo.parseXML(this, xml);
	//parse custom attributes
	for (var attr in xml.attributes) {
		var val:String = xml.attributes[attr];
		switch (attr.toLowerCase()) {
		case "legendcolor" :
			if (val.charAt(0) == "#") {
				this.legendcolor = Number("0x"+val.substring(1, val.length));
			} else {
				this.legendcolor = Number(val);
			}
			break;
		case "transcolor" :
			if (val.charAt(0) == "#") {
				this.transcolor = Number("0x"+val.substring(1, val.length));
			} else {
				this.transcolor = Number(val);
			}
			break;
		case "backgroundcolor" :
			if (val.charAt(0) == "#") {
				this.backgroundcolor = Number("0x"+val.substring(1, val.length));
			} else {
				this.backgroundcolor = Number(val);
			}
			break;
		case "alpha" :
			this._alpha = Number(val);
			break;
		case "outputtype" :
			this.outputtype = val;
			break;
		case "timeout" :
			this.timeout = Number(val);
			break;
		case "retryonerror" :
			this.retryonerror = Number(val);
			break;
		case "minscale" :
			this.minscale = Number(val);
			break;
		case "maxscale" :
			this.maxscale = Number(val);
			break;
		case "identifydistance" :
			this.identifydistance = Number(val);
			break;
		case "featurelimit" :
			this.featurelimit = Number(val);
			break;
		case "fullextent" :
			this.fullextent = map.string2Extent(val);
			break;
		case "maptipall" :
			if (val.toLowerCase() == "true") {
				maptipall = true;
			} else {
				maptipall = false;
			}
			break;
		case "identifyall" :
			if (val.toLowerCase() == "true") {
				identifyall = true;
			} else {
				identifyall = false;
			}
			break;
		case "legend" :
			if (val.toLowerCase() == "true") {
				legend = true;
			} else {
				legend = false;
			}
			break;
		case "shadow" :
			dropShadow();
			break;
		case "server" :
			server = val;
			break;
		case "servlet" :
			servlet = val;
			break;
		case "mapservice" :
			mapservice = val;
			break;
		case "showlegendids" :
			setLayerProperty(val, "legend", true);
			this.showlegendids = val;
			break;
		case "hidelegendids" :
			setLayerProperty(val, "legend", false);
			this.hidelegendids = val;
			break;
		case "visibleids" :
			setLayerProperty(val, "visible", true);
			this.visibleids = val;
			break;
		case "hiddenids" :
			setLayerProperty(val, "visible", false);
			this.hiddenids = val;
			break;
		case "identifyids" :
			setLayerProperty(val, "identify", true);
			this.identifyids = val;
			break;
		case "forceidentifyids" :
			setLayerProperty(val, "forceidentify", true);
			this.forceidentifyids = val;
			break;
		case "maptipids" :
			this.canmaptip = true;
			setLayerProperty(val, "maptip", true);
			this.maptipids = val;
			break;
		case "dataframe" :
			dataframe = val;
			break;
		}
	}
	var xlayers:Array = xml.childNodes;
	if (xlayers.length>0) {
		for (var i:Number = xlayers.length-1; i>=0; i--) {
			if (xlayers[i].nodeName.toLowerCase() == "layer") {
				var id;
				for (var attr in xlayers[i].attributes) {
					if (attr.toLowerCase() == "id") {
						id = xlayers[i].attributes[attr];
						break;
					}
				}
				if (id != undefined) {
					if (layers[id] == undefined) {
						layers[id] = new Object();
					}
					if (layers[id].language == undefined) {
						layers[id].language = new Object();
					}
					layers[id].order = i;
					//get maptip
					flamingo.parseString(xlayers[i], layers[id].language);
					for (var attr in xlayers[i].attributes) {
						var val:String = xlayers[i].attributes[attr];
						switch (attr.toLowerCase()) {
						case "identifydistance" :
						case "maptipdistance" :
						case "featurelimit" :
							layers[id][attr.toLowerCase()] = Number(val);
							break;
						case "subfields" :
						case "fields" :
							layers[id].subfields = val;
							break;
						default :
							layers[id][attr.toLowerCase()] = val;
							break;
						}
					}
				}
				//search for mydata                                                                                                                                      
				xmydatas = xlayers[i].childNodes;
				if (xmydatas.length>0) {
					for (var j:Number = xmydatas.length-1; j>=0; j--) {
						switch (xmydatas[j].nodeName.toLowerCase()) {
						case "mydatastring" :
							var mydata = xmydatas[j].firstChild.nodeValue;
							var fielddelimiter = ",";
							var recorddelimiter = "\n";
							var joinfield;
							var jointo;
							for (var attr in xmydatas[j].attributes) {
								var value = xmydatas[j].attributes[attr];
								switch (attr.toLowerCase()) {
								case "fielddelimiter" :
									fielddelimiter = value;
									break;
								case "recorddelimiter" :
									recorddelimiter = value;
									break;
								case "joinfield" :
									joinfield = value;
									break;
								case "jointo" :
									jointo = value;
									break;
								}
							}
							this.addMydata(id, jointo, mydata, joinfield, recorddelimiter, fielddelimiter);
							break;
						case "mydata" :
							break;
						case "layerdefstring" :
							layers[id].layerdefstring = xmydatas[j].firstChild.nodeValue;
							break;
						}
					}
				}
			}
		}
	}
	//                                  
	//
	if (visible == undefined) {
		visible = true;
	}
	// deal with arguments                                    
	var val = flamingo.getArgument(this, "visible");
	if (val != undefined) {
		this.setLayerProperty(val, "visible", true);
	}
	flamingo.deleteArgument(this, "visible");
	//
	var val = flamingo.getArgument(this, "hidden");
	if (val != undefined) {
		this.setLayerProperty(val, "visible", false);
	}
	flamingo.deleteArgument(this, "hidden");
	//thisObj.update();
	//get extra information about mapserver and the layers
	if (server == undefined) {
		return;
	}
	if (mapservice == undefined) {
		return;
	}
	var lConn = new Object();
	lConn.onResponse = function(connector:ArcServerConnector) {
		flamingo.raiseEvent(thisObj, "onResponse", thisObj, "init", connector);
	};
	lConn.onRequest = function(connector:ArcServerConnector) {
		//flamingo.raiseEvent(thisObj, "onGetServiceInfoRequest", thisObj, connector);
		flamingo.raiseEvent(thisObj, "onRequest", thisObj, "init", connector);
	};
	lConn.onError = function(error:String, objecttag:Object, requestid:String) {
		flamingo.raiseEvent(thisObj, "onError", thisObj, "init", error);
	};
	lConn.onGetServiceInfo = function(extent, servicelayers, objecttag, requestid) {
		for (var id in servicelayers) {
			if (layers[id] == undefined) {
				layers[id] = new Object();
			}
			for (var attr in servicelayers[id]) {
				if (layers[id][attr] == undefined) {
					layers[id][attr] = servicelayers[id][attr];
				}
			}
//			if (layers[id].type == "featureclass") {
			if (layers[id].type == "Feature Layer") {
				layers[id].queryable = true;
			} else {
				layers[id].queryable = false;
			}
		}
		for (var id in layers) {
			if (layers[id].name == undefined and layers[id].id == undefined) {
				delete layers[id];
			}
		}
		if (thisObj.forceidentifyids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "forceidentify", true);
		}
		if (thisObj.hidelegendids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "legend", false);
		}
		if (thisObj.showlegendids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "legend", true);
		}
		if (thisObj.visibleids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "visible", true);
		}
		if (thisObj.hiddenids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "visible", false);
		}
		if (thisObj.identifyids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "identify", true);
		}
		if (thisObj.maptipids.toUpperCase() == "#ALL#") {
			thisObj.setLayerProperty("#ALL#", "maptipable", true);
		}
		thisObj.update();
		flamingo.raiseEvent(thisObj, "onGetServiceInfo", thisObj);
		initialized = true;
	};
	var conn:ArcServerConnector = new ArcServerConnector(server);
	conn.addListener(lConn);
	conn.dataframe = dataframe;

	if (servlet.length>0) {
		conn.servlet = servlet;
	}
	conn.getServiceInfo(mapservice);
	
}
/**
* Sets the transparency of a layer.
* @param alpha:Number A number between 0 and 100, 0=transparent, 100=opaque
*/
function setAlpha(alpha:Number) {
	this._alpha = alpha;
}
/**
* Hides a layer.
*/
function hide():Void {
	visible = false;
	update();
	flamingo.raiseEvent(thisObj, "onHide", thisObj);
}
/**
* Shows a layer.
*/
function show():Void {
	visible = true;
	updateCaches();
	update();
	flamingo.raiseEvent(thisObj, "onShow", thisObj);
}
/**
* Updates a layer.
*/
function update():Void {
	_update(1);
}
function _update(nrtry:Number):Void {
	if (not visible) {
		_visible = false;
		return;
	}
	if (updating) {
		return;
	}
	if (server == undefined) {
		return;
	}
	if (mapservice == undefined) {
		return;
	}
	if (not map.hasextent) {
		return;
	}
	extent = map.getMapExtent();
	var ms:Number = map.getMapScale();
	if (minscale != undefined) {
		if (ms<=minscale) {
			flamingo.raiseEvent(thisObj, "onUpdate", thisObj, nrtry);
			flamingo.raiseEvent(thisObj, "onUpdateComplete", thisObj, 0, 0, 0);
			_visible = false;
			return;
		}
	}
	if (maxscale != undefined) {
		if (ms>maxscale) {
			flamingo.raiseEvent(thisObj, "onUpdate", thisObj, nrtry);
			flamingo.raiseEvent(thisObj, "onUpdateComplete", thisObj, 0, 0, 0);
			_visible = false;
			return;
		}
	}
	if (fullextent != undefined) {
		if (not map.isHit(fullextent)) {
			flamingo.raiseEvent(thisObj, "onUpdate", thisObj, nrtry);
			flamingo.raiseEvent(thisObj, "onUpdateComplete", thisObj, 0, 0, 0);
			_visible = false;
			return;
		}
	}
	updating = true;
	_visible = true;
	nrcache++;
	var cache:MovieClip = createEmptyMovieClip("mCache"+nrcache, nrcache);
	cache._alpha = 0;
	caches[nrcache] = cache;
	//
	var lConn:Object = new Object();
	lConn.onResponse = function(connector:ArcServerConnector) {
		thisObj._stoptimeout();
		flamingo.raiseEvent(thisObj, "onResponse", thisObj, "update", connector);
	};
	lConn.onRequest = function(connector:ArcServerConnector) {
		//trace(requestobject.request)
		flamingo.raiseEvent(thisObj, "onRequest", thisObj, "update", connector);
	};
	lConn.onError = function(error:String, objecttag:Object, requestid:String) {
		thisObj._stoptimeout();
		updating = false;
		if (nrtry<retryonerror) {
			nrtry++;
			_update(nrtry);
		} else {
			flamingo.raiseEvent(thisObj, "onError", thisObj, "update", error);
		}
	};
	
	//test//
//	lConn.onGetSelectedFeatureID = function(objecttag:Object, requestid:String){
//		trace("event");
//	};	
	lConn.onGetImage = function(ext:Object, imageurl:String, legurl:String, objecttag:Object, requestid:String) {
		if (legurl.length>0) {
			legendurl = legurl;
			flamingo.raiseEvent(thisObj, "onGetLegend", thisObj, legendurl);
		}
		thisObj._starttimeout();
		var requesttime = (new Date()-starttime)/1000;
		var listener:Object = new Object();
		listener.onLoadError = function(mc:MovieClip, error:String, httpStatus:Number) {
			thisObj._stoptimeout();
			updating = false;
			flamingo.raiseEvent(thisObj, "onError", thisObj, "update", error);
		};
		listener.onLoadProgress = function(mc:MovieClip, bytesLoaded:Number, bytesTotal:Number) {
			thisObj._stoptimeout();
			flamingo.raiseEvent(thisObj, "onUpdateProgress", thisObj, bytesLoaded, bytesTotal);
		};
		listener.onLoadInit = function(mc:MovieClip) {
			var loadtime = (new Date()-starttime)/1000;
			mc.extent = ext;
			//mc.requestedextent = objecttag;
			updateCache(mc);
			if (map.fadesteps>0) {
				mc.loadtime = loadtime;
				mc.requesttime = requesttime;
				mc.totalbytes = mc.getBytesTotal();
				var step = (100/map.fadesteps)+1;
				thisObj.onEnterFrame = function() {
					var cache = this.caches[nrcache];
					cache._alpha = cache._alpha+step;
					if (cache._alpha>=100) {
						delete this.onEnterFrame;
						flamingo.raiseEvent(this, "onUpdateComplete", this, cache.requesttime, cache.loadtime, cache.totalbytes);
						delete cache.requesttime;
						delete cache.loadtime;
						delete cache.totalbytes;
						this.updating = false;
						this._clearCache();
						if (not map.isEqualExtent(extent) or _getVisLayers() != vislayers) {
							this.update();
						}
					}
				};
			} else {
				cache._alpha = 100;
				flamingo.raiseEvent(thisObj, "onUpdateComplete", thisObj, requesttime, loadtime, mc.getBytesTotal());
				updating = false;
				_clearCache();
				if (not map.isEqualExtent(extent) or _getVisLayers() != vislayers) {
					thisObj.update();
				}
			}
		};
		var mcl:MovieClipLoader = new MovieClipLoader();
		mcl.addListener(listener);
		var starttime:Date = new Date();
		mcl.loadClip(imageurl, cache);
	};
	
	var conn:ArcServerConnector = new ArcServerConnector(server);
	conn.addListener(lConn);
	conn.dataframe = dataframe;
	if (servlet.length>0) {
		conn.servlet = servlet;
	}
	conn.transcolor = this.transcolor;
	conn.backgroundcolor = this.backgroundcolor;
	conn.legendcolor = this.legendcolor;
	conn.outputtype = outputtype;
	conn.legend = legend;
	var starttime = new Date();
	var vislayers = _getVisLayers();
	flamingo.raiseEvent(this, "onUpdate", this, nrtry);
//	conn.getSelectedFeatureId(mapservice, extent, {width:Math.ceil(map.__width), height:Math.ceil(map.__height)}, layers);
	
	conn.getImage(mapservice, extent, {width:Math.ceil(map.__width), height:Math.ceil(map.__height), dpi:96}, layers);
	thisObj._starttimeout();
}
function _starttimeout() {
	clearInterval(timeoutid);
	timeoutid = setInterval(this, "_timeout", (timeout*1000));
}
function _stoptimeout() {
	clearInterval(timeoutid);
}
function _timeout() {
	clearInterval(timeoutid);
	updating = false;
	flamingo.raiseEvent(thisObj, "onError", thisObj, "update", "timeout, connection failed...");
}
function _clearCache() {
	for (var nr in caches) {
		if (nr != nrcache) {
			caches[nr].removeMovieClip();
			delete caches[nr];
		}
	}
}
function _getLayerlist(list:String, field:String):Array {
	var layerlist:Array = new Array();
	var ms:Number = map.getScale();
	if (list.toUpperCase() == "#ALL#") {
		for (var id in layers) {
			if (layers[id].queryable) {
				if (layers[id][field] == false) {
					continue;
				}
				if (field == "identify" and layers[id].forceidentify == true) {
					layerlist.push(id);
				} else {
					if (layers[id].visible == false) {
						continue;
					}
					if (layers[id].minscale != undefined) {
						if (ms<layers[id].minscale) {
							continue;
						}
					}
					if (layers[id].maxscale != undefined) {
						if (ms>layers[id].maxscale) {
							continue;
						}
					}
					layerlist.push(id);
				}
			}
		}
	} else {
		var a:Array = list.split(",");
		for (var i = a.length-1; i>=0; i--) {
			var id = a[i];
			if (layers[id].queryable) {
				if (layers[id][field] == false) {
					continue;
				}
				if (field == "identify" and layers[id].forceidentify == true) {
					layerlist.push(id);
				} else {
					if (layers[id].visible == false) {
						continue;
					}
					if (layers[id].minscale != undefined) {
						if (ms<layers[id].minscale) {
							continue;
						}
					}
					if (layers[id].maxscale != undefined) {
						if (ms>layers[id].maxscale) {
							continue;
						}
					}
					//all tests passed, this layer can be identified                                                                      
					layerlist.push(id);
				}
			}
		}
	}
	return layerlist;
}
function cancelIdentify() {
	_identifylayers = new Array();
	this.identifyextent = undefined;
}
/**
* Identifies a layer.
* @param identifyextent:Object extent of the identify
*/
/**
* Identifies a layer.
* @param identifyextent:Object extent of the identify
*/
function identify(_identifyextent:Object) {
	this.identifyextent = undefined;
	_identifylayers = new Array();
	if (not this.initialized) {
		return;
	}
	if (identifyids.length<=0) {
		return;
	}
	if (not visible or not _visible) {
		return;
	}
	if (server == undefined) {
		return;
	}
	if (mapservice == undefined) {
		return;
	}
	if (fullextent != undefined) {
		if (not map.isHit(_identifyextent, fullextent)) {
			return;
		}
	}
	_identifylayers = new Array();
	_identifylayers = _getLayerlist(identifyids, "identify");
	this.nrlayersqueried = _identifylayers.length;
	if (_identifylayers.length == 0) {
		return;
	}
	this.identifyextent = map.copyExtent(_identifyextent);
	flamingo.raiseEvent(thisObj, "onIdentify", thisObj, identifyextent);	
	_identifylayer(this.identifyextent, new Date());
}

function _identifylayer(_identifyextent:Object, starttime:Date) {
	
	if (_identifylayers.length == 0) {
		var t = (new Date()-starttime)/1000;
		flamingo.raiseEvent(thisObj, "onIdentifyComplete", thisObj, t);
		return;
	}
	
	var lConn = new Object();
	lConn.onResponse = function(connector:ArcServerConnector) {
		//trace(connector.response);
		flamingo.raiseEvent(thisObj, "onResponse", thisObj, "identify", connector);
	};
	lConn.onRequest = function(connector:ArcServerConnector) {
		//trace(connector.request);
		flamingo.raiseEvent(thisObj, "onRequest", thisObj, "identify", connector);
	};
	lConn.onError = function(error:String, objecttag:Object, requestid:String) {
		flamingo.raiseEvent(thisObj, "onError", thisObj, "identify", error);
		if (_identifylayers.length>0) {
			_identifylayer(_identifyextent, starttime);
		} else {
			flamingo.raiseEvent(thisObj, "onIdentifyComplete", thisObj);
		}
	};
	lConn.onGetRasterInfo = function(layerid:String, data:Array, objecttag:Object) {
		if (map.isEqualExtent(thisObj.identifyextent, objecttag)) {
			// add data from mydata
			thisObj._completeWithMydata(layerid, data);
			//                                               
			var features = new Object();
			features[layerid] = data;
			flamingo.raiseEvent(thisObj, "onIdentifyData", thisObj, features, thisObj.identifyextent, (thisObj.nrlayersqueried-thisObj._identifylayers.length), thisObj.nrlayersqueried);
			if (not identifyall) {
				var b = false;
				for (var i = 0; i<data.length; i++) {
					for (var attr in data[i]) {
						if (data[i][attr] != undefined) {
							b = true;
							break;
						}
					}
				}
				if (b) {
					var t = (new Date()-starttime)/1000;
					flamingo.raiseEvent(thisObj, "onIdentifyComplete", thisObj, t);
				} else {
					_identifylayer(_identifyextent, starttime);
				}
			} else {
				_identifylayer(_identifyextent, starttime);
			}
		}
	};
	lConn.onGetFeatures = function(layerid:String, data:Array, count:Number, hasmore:Boolean, objecttag:Object) {
		if (map.isEqualExtent(thisObj.identifyextent, objecttag)) {
			// add data from mydata
			thisObj._completeWithMydata(layerid, data);
			//                                               
			var features = new Object();
			features[layerid] = data;
			flamingo.raiseEvent(thisObj, "onIdentifyData", thisObj, features, thisObj.identifyextent, (thisObj.nrlayersqueried-thisObj._identifylayers.length), thisObj.nrlayersqueried);

			if (not identifyall and count>0) {
				var t = (new Date()-starttime)/1000;
				flamingo.raiseEvent(thisObj, "onIdentifyComplete", thisObj, t);				
			} else {
				_identifylayer(_identifyextent, starttime);
			}
		}
	};
	var layerid:String = String(_identifylayers.pop());
	var conn:ArcServerConnector = new ArcServerConnector(server);
	if (servlet.length>0) {
		conn.servlet = servlet;
	}
	conn.addListener(lConn);
	var _featurelimit = layers[layerid].featurelimit;
	if (_featurelimit == undefined) {
		_featurelimit = this.featurelimit;
	}
	conn.featurelimit = _featurelimit;
	switch (layers[layerid].type) {
	case "featureclass" :
	case "Feature Layer" :
		//calculate the real identify extent based on the identify extent of the map
		//if the extent is actually a point 
		var _identifydistance = layers[layerid].identifydistance;
		if (_identifydistance == undefined) {
			_identifydistance = this.identifydistance;
		}
		var real_identifyextent = map.copyExtent(_identifyextent);
		if ((real_identifyextent.maxx-real_identifyextent.minx) == 0) {
			var w = map.getScale()*_identifydistance;
			real_identifyextent.minx = real_identifyextent.minx-(w/2);
			real_identifyextent.maxx = real_identifyextent.minx+w;
		}
		if ((real_identifyextent.maxy-real_identifyextent.miny) == 0) {
			var h = map.getScale()*_identifydistance;
			real_identifyextent.miny = real_identifyextent.miny-(h/2);
			real_identifyextent.maxy = real_identifyextent.miny+h;
		}
		var subfields:String = layers[layerid].subfields.split(",").join(" ");
		var query:String = layers[layerid].query;
		conn.getFeatures(mapservice, layerid, real_identifyextent, subfields, query, map.copyExtent(_identifyextent));
		break;
	case "image" :
//		var point = new Object();
//		point.x = (_identifyextent.maxx+_identifyextent.minx)/2;
//		point.y = (_identifyextent.maxy+_identifyextent.miny)/2;
//		conn.getRasterInfo(mapservice, layerid, point, layers[layerid].coordsys, map.copyExtent(_identifyextent));
		break;
	}
}
/** 
* Changes the layers collection.
* @param ids:String Comma seperated string of affected layerids. If keyword "#ALL#" is used, all layers will be affected.
* @param field:String Property that has to be changed. e.g. "visible", "legend", "identify"
* @param value:Object Value to be set.
* @example mylayer.setLayerProperty("39,BRZO","visible",true)
* mylayer.setLayerProperty("#ALL#","identify",false)
*/
function setLayerProperty(ids:String, field:String, value:Object) {
	if (ids.toUpperCase() == "#ALL#") {
		for (var id in layers) {
			layers[id][field] = value;
		}
	} else {
		var a_ids = flamingo.asArray(ids);
		for (var i = 0; i<a_ids.length; i++) {
			var id = a_ids[i];
			if (layers[id] == undefined and not initialized) {
				layers[id] = new Object();
				layers[id][field] = value;
			} else {
				layers[id][field] = value;
			}
			//update feature id for buffer when the query is removed
			if(field == "query" && value == ""){
				updateLayerFID(id);
			}
		}
	}
	flamingo.raiseEvent(thisObj, "onSetLayerProperty", thisObj, ids);
}
/** 
* Gets a property of a layer in the layers collection.
* @param id:String Layerid.
* @param field:String Property. e.g. "visible", "legend", "identify"
* @return Object Value of property.
*/
function getLayerProperty(id:String, field:String):Object {
	if (layers[id] == undefined) {
		return;
	}
	return layers[id][field];
}
/** 
* Returns a reference to the layers collection.
* Be carefull for making changes.
* @return Object Collection of layers. A layer is an object with several properties, such as name, id, minscale, maxscale etc.
*/
function getLayers():Object {
	return layers;
}
/** 
* Gets an array of layerids.
* @return Array List of layerids.
*/
function getLayerIds():Array {
	var a = new Array();
	for (var id in layers) {
		a.push(id);
	}
	return a;
}
/** 
* Moves the map to a scale where the (map)layer is visible.
* @param ids:String Comma seperated string of layers. If omitted the scale of the maplayer will be used.
* @param coord:Object [optional] Coordinate, an object with x and y. If undefined the map will zoom in the center of the current mapextent.
* @param updatedelay:Number [optional] Delay in milliseconds. If updatedelay is undefined or -1 there will be no onUpdate event.  
* @param movetime:Number [optional] Total time of move-animation. If movetime is 0, there wil be no animation. The Extent is set immediately. If movetime is undefined, the default movetime of the map will be used.  
*/
function moveToLayer(ids:String, coord:Object, updatedelay:Number, movetime:Number) {
	var zoomtoscale;
	if (ids == undefined or ids == "") {
		if (maxscale != undefined) {
			zoomtoscale = maxscale*0.9;
		}
		if (minscale != undefined) {
			zoomtoscale = minscale*1.1;
		}
	} else {
		var a_ids = ids.split(",");
		for (var i = 0; i<a_ids.length; i++) {
			var layer = layers[a_ids[i]];
			if (layer != undefined) {
				//first examine maxscale
				if (layer.maxscale != undefined) {
					if (zoomtoscale == undefined) {
						zoomtoscale = layer.maxscale*0.9;
					} else {
						zoomtoscale = Math.min(zoomtoscale, layer.maxscale*0.9);
					}
				} else if (layer.minscale != undefined) {
					if (zoomtoscale == undefined) {
						zoomtoscale = layer.minscale*1.1;
					} else {
						zoomtoscale = Math.max(zoomtoscale, layer.minscale*1.1);
					}
				}
			}
		}
	}
	if (zoomtoscale != undefined) {
		map.moveToScale(zoomtoscale, coord, updatedelay, movetime);
	}
}
function getLegend():String {
	return legendurl;
}
/** 
* Changes the visiblity of a layer or a sub-layer.
* @param vis:Boolean True (visible) or false (not visible).
* @param id:String [optional] A layerid. If omitted the entire maplayer will be effected.
*/
function setVisible(vis:Boolean, id:String) {
	if (id.length == 0 or id == undefined) {
		if (vis) {
			this.show();
		} else {
			this.hide();
		}
	} else {
		this.setLayerProperty(id, "visible", vis);
	}
}
/** 
* Checks if a maplayer or a layer of a maplayer is visible.
* @param id:String [optional] A layerid. If omitted the entire maplayer will be checked.
* @return Number -3, -2, -1, 0, 1, 2, or 3
* -3 = layer is not visible and maplayer is not visible
* -2 = (map)layer is not visible and (map)layer is out of scale
* -1 = (map)layer is not visible;
*  0 = layer does not exist
*  1 = (map)layer is visible;
*  2 = (map)layer is visible and (map)layer is out of scale
*  3 = layer is visible and maplayer is not visible
*/
function getVisible(id:String):Number {
	//returns 0 : not visible or 1:  visible or 2: visible but not in scalerange
	var ms:Number = map.getScale(extent);
	//var vis:Boolean = flamingo.getVisible(this)
	if (id.length == 0 or id == undefined) {
		//examine whole layer
		if (visible) {
			if (minscale != undefined) {
				if (ms<minscale) {
					return 2;
				}
			}
			if (maxscale != undefined) {
				if (ms>maxscale) {
					return 2;
				}
			}
			return 1;
		} else {
			if (minscale != undefined) {
				if (ms<minscale) {
					return -2;
				}
			}
			if (maxscale != undefined) {
				if (ms>maxscale) {
					return -2;
				}
			}
			return -1;
		}
	} else {
		var sublayer = layers[id];
		if (sublayer == undefined) {
			return 0;
		} else {
			if (sublayer.visible) {
				if (visible) {
					if (sublayer.minscale != undefined) {
						if (ms<sublayer.minscale) {
							return 2;
						}
					}
					if (sublayer.maxscale != undefined) {
						if (ms>sublayer.maxscale) {
							return 2;
						}
					}
					return 1;
				} else {
					return 3;
				}
			} else {
				if (visible) {
					if (sublayer.minscale != undefined) {
						if (ms<sublayer.minscale) {
							return -2;
						}
					}
					if (sublayer.maxscale != undefined) {
						if (ms>sublayer.maxscale) {
							return -2;
						}
					}
					return -1;
				} else {
					return -3;
				}
			}
		}
	}
}
function updateCaches() {
	for (var nr in caches) {
		updateCache(caches[nr]);
	}
}
function updateCache(layer:MovieClip) {
	if (layer == undefined) {
		return;
	}
	if (visible) {
		var ms = map.getScale();
		if (minscale != undefined) {
			if (ms<=minscale) {
				_visible = false;
				return;
			}
		}
		if (maxscale != undefined) {
			if (ms>maxscale) {
				_visible = false;
				return;
			}
		}
		_visible = true;
		var r:Object = map.extent2Rect(layer.extent);
		layer._x = r.x;
		layer._y = r.y;
		layer._width = r.width;
		layer._height = r.height;
	}
}
/** Gets the scale of the layer
* &return scale
*/
function getScale():Number {
	return map.getScale(extent);
}
function _getVisLayers():String {
	var s = "";
	for (var layer in layers) {
		if (layers[layer].visible) {
			s += "1";
		} else {
			s += "0";
		}
	}
	return s;
}
function _getString(item:Object, stringid:String):String {
	var lang = flamingo.getLanguage();
	var s = item.language[stringid][lang];
	if (s.length>0) {
		//option A
		return s;
	}
	s = item[stringid];
	if (s.length>0) {
		//option B
		return s;
	}
	for (var attr in item.language[stringid]) {
		//option C
		return item.language[stringid][attr];
	}
	//option D
	return "";
}
function stopMaptip() {
	this.showmaptip = false;
	this.maptipextent = undefined;
	this._maptiplayers = new Array();
}
function startMaptip(x:Number, y:Number) {
	if (not this.canmaptip) {
		return;
	}
	if (not this.initialized) {
		return;
	}
	if (maptipids.length<=0) {
		return;
	}
	if (not visible or not _visible) {
		return;
	}
	if (server == undefined) {
		return;
	}
	if (mapservice == undefined) {
		return;
	}
	this.showmaptip = true;
	var r = new Object();
	r.x = x-this.identifydistance/2;
	r.y = y-this.identifydistance/2;
	r.width = this.identifydistance;
	r.height = this.identifydistance;
	this.maptipextent = this.map.rect2Extent(r);
	if (this.fullextent != undefined) {
		if (not this.map.isHit(this.fullextent, this.maptipextent)) {
			return;
		}
	}
	this._maptiplayers = new Array();
	this._maptiplayers = _getLayerlist(maptipids, "maptip");
	_maptip();
}
function _maptip() {
	if (this._maptiplayers.length == 0) {
		return;
	}
	var layerid:String = String(_maptiplayers.pop());
	var maptipfields:String = layers[layerid].maptipfields;
	
	if (maptipfields == undefined or maptipfields.length == 0) {
		thisObj._maptip();
		return;
	}
	var lConn = new Object();
	lConn.onGetFeatures = function(layerid:String, data:Array, count:Number, hasmore:Boolean, objecttag:Object) {
		if (thisObj.showmaptip) {
			if (count>0) {
				if (thisObj.map.isEqualExtent(thisObj.maptipextent, objecttag)) {
					var maptip = thisObj._getString(thisObj.layers[layerid], "maptip");
					if (maptip.length == 0) {
						for (var field in data[0]) {
							if (maptip.length == 0) {
								maptip = data[0][field];
							} else {
								maptip += ","+data[0][field];
							}
						}
					} else {
						var maptipfields = flamingo.asArray(thisObj.layers[layerid].maptipfields, " ");
						for (var i = 0; i<maptipfields.length; i++) {
							var value;
							var maptipfield = maptipfields[i];
							if (maptipfield.indexOf(".", 0)>=0) {
								var value = data[0][maptipfield];
							} else {
								for (var field in data[0]) {
									if (field.substr(field.length-maptipfield.length-1) == "."+maptipfield) {
										value = data[0][field];
										break;
									}
								}
							}
							if (value != undefined) {
								maptip = maptip.split("["+maptipfield+"]").join(value);
							}
						}
					}
					if (maptip.length>=0) {
						flamingo.raiseEvent(thisObj, "onMaptipData", thisObj, maptip);
					}
				}
			}
			if (thisObj._maptiplayers.length>0) {
				thisObj._maptip();
			}
		}
	};
	var conn:ArcServerConnector = new ArcServerConnector(server);	
	if (servlet.length>0) {
		conn.servlet = servlet;
	}
	conn.addListener(lConn);
	conn.featurelimit = 1;
	var query:String = layers[layerid].query;
	
	conn.getFeatures(mapservice, layerid, maptipextent, maptipfields, query, this.map.copyExtent(this.maptipextent));
}
//custom functions 
//gets the id's of the visible features in the layer.
function updateLayerFID(layerId:String){
	var conn:ArcServerConnector = new ArcServerConnector(server);	
	var query:String = getLayerProperty(layerId, "query").toString();
	if(query == undefined){
		query = "";
	}
	conn.getQueryFeatureIDs(mapService.mapservice, layerId, query, layers);
	var lConn = new Object();
	
	lConn.onGetQueryFeatureIDs = function(selectedFID:Array, objecttag:Object, requestid:String) {
		map.refresh();
	};
	conn.addListener(lConn);	
}

function _getString(item:Object, stringid:String):String {
	var lang = flamingo.getLanguage();
	var s = item.language[stringid][lang];
	if (s.length>0) {
		//option A
		return s;
	}
	s = item[stringid];
	if (s.length>0) {
		//option B
		return s;
	}
	for (var attr in item.language[stringid]) {
		//option C
		return item.language[stringid][attr];
	}
	//option D
	return "";
}
function _stopMaptip() {
	this.showmaptip = false;
	this.maptipcoordinate = new Object();
	this._maptiplayers = new Array();
}
function _startMaptip(x:Number, y:Number) {
	this._maptiplayers = new Array();
	this.maptipcoordinate = new Object();
	if (not this.canmaptip) {
		return;
	}
	if (not this.initialized) {
		return;
	}
	if (maptipids.length<=0) {
		return;
	}
	if (not visible or not _visible) {
		return;
	}
	if (server == undefined) {
		return;
	}
	if (mapservice == undefined) {
		return;
	}
	if (this.fullextent != undefined) {
		if (not this.map.isHit({x:x, y:y}, this.fullextent)) {
			return;
		}
	}
	this.maptipcoordinate.x = x;
	this.maptipcoordinate.y = y;
	this.showmaptip = true;
	this._maptiplayers = _getLayerlist(maptipids, "maptipable");
	_maptip(x, y);
	var r = new Object();
	r.x = x-this.identifydistance/2;
	r.y = y-this.identifydistance/2;
	r.width = this.identifydistance;
	r.height = this.identifydistance;
	this.maptipextent = this.map.rect2Extent(r);
}
function _maptip(x:Number, y:Number) {
	if (not this.showmaptip) {
		return;
	}
	if (this._maptiplayers.length == 0) {
		return;
	}
	var lConn = new Object();

	lConn.onResponse = function(connector:ArcServerConnector) {
		//trace(connector.response);
		flamingo.raiseEvent(thisObj, "onResponse", thisObj, "maptip", connector);
	};
	lConn.onRequest = function(connector:ArcServerConnector) {
		//trace(connector.request);
		flamingo.raiseEvent(thisObj, "onRequest", thisObj, "maptip", connector);
	};
	lConn.onError = function(error:String, objecttag:Object, requestid:String) {
		flamingo.raiseEvent(thisObj, "onError", thisObj, "maptip", error);
		if (thisObj._maptiplayers.length>0) {
			thisObj._maptip(x, y);
		}
	};
	lConn.onGetRasterInfo = function(layerid:String, data:Array, objecttag:Object) {
		if (thisObj.showmaptip) {
			if (thisObj.maptipcoordinate.x == objecttag.x and thisObj.maptipcoordinate.y == objecttag.y) {
				thisObj._completeWithMydata(layerid, data);
				var maptip = thisObj._getString(thisObj.layers[layerid], "maptip");
				maptip = thisObj._makeMaptip(layerid, maptip, data[0]);
				if (maptip.length>=0) {
					flamingo.raiseEvent(thisObj, "onMaptipData", thisObj, maptip);
					if (not thisObj.maptipall) {
						return;
					}
				}
			}
			if (thisObj._maptiplayers.length>0) {
				thisObj._maptip(x, y);
			}
		}
	};
	lConn.onGetFeatures = function(layerid:String, data:Array, count:Number, hasmore:Boolean, objecttag:Object) {
		if (thisObj.showmaptip) {
			if (count>0) {
				if (thisObj.maptipcoordinate.x == objecttag.x and thisObj.maptipcoordinate.y == objecttag.y) {
					thisObj._completeWithMydata(layerid, data);
					var maptip = thisObj._getString(thisObj.layers[layerid], "maptip");
					maptip = thisObj._makeMaptip(layerid, maptip, data[0]);
					if (maptip.length>=0) {
						flamingo.raiseEvent(thisObj, "onMaptipData", thisObj, maptip);
						if (not thisObj.maptipall) {
							return;
						}
					}
				}
			}
			if (thisObj._maptiplayers.length>0) {
				thisObj._maptip(x, y);
			}
		}
	};
	//
	var layerid:String = String(_maptiplayers.pop());
	var conn:ArcServerConnector = new ArcServerConnector(server);

	if (servlet.length>0) {
		conn.servlet = servlet;
	}
	conn.addListener(lConn);
	conn.featurelimit = 1;
	var maptip = _getString(layers[layerid], "maptip");

	var maptipfields = _getMaptipFields(layerid, maptip);
	
	if (maptipfields == undefined or maptipfields.length == 0) {
		thisObj._maptip(x, y);
		return;
	}

	switch (layers[layerid].type) {
	case "Feature Layer" :
		var query:String = layers[layerid].query;
		var flds = maptipfields;
		var _maptipdistance = layers[layerid].maptipdistance;
		if (_maptipdistance == undefined) {
			_maptipdistance = this.maptipdistance;
		}
		var _maptipextent = new Object();
		var w = map.getScale()*_maptipdistance;
		var h = map.getScale()*_maptipdistance;
		_maptipextent.minx = x-(w/2);
		_maptipextent.miny = y-(h/2);
		_maptipextent.maxx = _maptipextent.minx+w;
		_maptipextent.maxy = _maptipextent.miny+h;

		conn.getFeatures(mapservice, layerid, _maptipextent, flds, query, {x:x, y:y});
		break;
	case "image" :
//		conn.getRasterInfo(mapservice, layerid, {x:x, y:y}, layers[layerid].coordsys, {x:x, y:y});
		break;
	}
}
function _getValue(record:Object, field:String):String {
	var value;
	for (var fld in record) {
		if (fld.toLowerCase() == field.toLowerCase()) {
			value = record[fld];
			break;
		}
//		if (fld.indexOf(".", 0)>=0 and field.indexOf(".", 0)<0) {
			//field = "."+field;
//		}
		if (fld.substr(fld.length-field.length).toLowerCase() == field.toLowerCase()) {
			value = record[fld];
			break;
		}
	}
	return value;
}
//
//
function _string2Table(s:String, rdel:String, fdel:String):Array {
	var table:Array = new Array();
	var record:Object;
	var records:Array;
	var values:Array;
	var fields:Array;
	//
	s = flamingo.trim(s);
	records = flamingo.asArray(s, rdel);
	fields = flamingo.asArray(records[0], fdel);
	for (var i = 1; i<records.length; i++) {
		record = new Object();
		values = flamingo.asArray(records[i], fdel);
		for (var j = 0; j<fields.length; j++) {
			record[fields[j]] = values[j];
		}
		table.push(record);
	}
	return table;
}
//
function _getMaptipFields(layerid:String, maptip:String):String {
	layers[layerid].maptipfields = new Object();
	var flds:Array = new Array();
	var fld:String;
	var temp:Object = new Object();
	var end:Number;
	var begin:Number = maptip.indexOf("[");
	while (begin>=0) {
		end = maptip.indexOf("]", begin);
		if (end>=0) {
			var fld = maptip.substring(begin+1, end);
			layers[layerid].maptipfields[fld] = "";
			temp[fld] = "";
		} else {
			break;
		}
		begin = maptip.indexOf("[", begin+1);
	}
	//
	for (var jointo in layers[layerid].mydatajoins) {
		for (var joinfield in layers[layerid].mydatajoins[jointo]) {
			for (var maptipfield in temp) {
				if (joinfield.toLowerCase() == maptipfield.toLowerCase()) {
					delete temp[maptipfield];
					temp[jointo] = "";
				}
			}
		}
	}
	for (var maptipfield in temp) {
		flds.push(maptipfield);
	}
	//
	return flds.join(" ");
}
function _makeMaptip(layerid:String, maptip:String, record:Object):String {
	var val:String;
	var b:Boolean = false;
	for (var fld in layers[layerid].maptipfields) {
		val = _getValue(record, fld);
		if (val == undefined) {
			val = "";
		} else {
			b = true;
		}
		maptip = maptip.split("["+fld+"]").join(val);
	}
	if (b) {
		return maptip;
	} else {
		return "";
	}
}
/**
* Dispatched when the layer gets a request object from the connector.
* @param layer:MovieClip a reference to the layer.
* @param type:String "update", "identify" or "init"
* @param requestobject:Object the object returned from the ArcServerConnector, containing the raw requests and other properties.
*/
//public function onRequest(layer:MovieClip, type:String, requestobject:Object):Void {
//
/**
* Dispatched when the layer gets a response object from the connector.
* @param layer:MovieClip a reference to the layer.
* @param type:String "update", "identify" or "init"
* @param responseobject:Object the object returned from the ArcServerConnector, containing the raw response and other properties.
*/
//public function onResponse(layer:MovieClip, type:String, responseobject:Object):Void {
//
/**
* Dispatched when there is an error.
* @param layer:MovieClip a reference to the layer.
* @param type:String "update", "identify" or "init"
* @param error:String error message
*/
//public function onError(layer:MovieClip, type:String, error:String):Void {
//
/**
* Dispatched when the layer is identified.
* @param layer:MovieClip a reference to the layer.
* @param identifyextent:Object the extent that is identified
*/
//public function onIdentify(layer:MovieClip, identifyextent:Object):Void {
//
/**
* Dispatched when the layer is identified and data is returned
* @param layer:MovieClip a reference to the layer.
* @param data:Object data object with the information 
* @param identifyextent:Object the original extent that is identified 
* @param nridentified:Number Number of sublayers thas has already been identified.
* @param total:Number Total number of sublayers that has to be identified 
*/
//public function onIdentifyData(layer:MovieClip, data:Object, identifyextent:Object, nridentified:Number, total:Number):Void {
//
/**
* Dispatched when the identify is completed.
* @param layer:MovieClip a reference to the layer.
* @param identifytime:Number total time of the identify 
*/
//public function onIdentifyComplete(layer:MovieClip, identifytime:Number):Void {
//	
/**
* Dispatched when the starts an update sequence.
* @param layer:MovieClip a reference to the layer.
* @param nrtry:Number   number of retry after an error. 
*/
//public function onUpdate(layer:MovieClip, nrtry):Void {
//
/**
* Dispatched when the layerimage is downloaded.
* @param layer:MovieClip a reference to the layer.
* @param bytesloaded:Number   Number of bytes already downloaded. 
* @param bytestotal:Number   Total of bytes to be downloaded.
*/
//public function onUpdateProgress(layer:MovieClip, bytesloaded:Number, bytestotal:Number):Void {
//
/**
* Dispatched when the layer is completely updated.
* @param layer:MovieClip a reference to the layer.
* @param updatetime:Object total time of the update sequence
*/
//public function onUpdateComplete(layer:MovieClip, updatetime:Number):Void {
//
/**
* Dispatched when the layer is hidden.
* @param layer:MovieClip a reference to the layer.
*/
//public function onHide(layer:MovieClip):Void {
//
/**
* Dispatched when the layer is shown.
* @param layer:MovieClip a reference to the layer.
*/
//public function onShow(layer:MovieClip):Void {
//
/**
* Dispatched when a legend is returned during an update sequence.
* @param layer:MovieClip a reference to the layer.
* @param legendurl:String the url of the legend.
*/
//public function onGetLegend(layer:MovieClip, legendurl:String):Void {
//
/**
* Dispatched when a the layer is up and running and ready to update for the first time.
* @param layer:MovieClip a reference to the layer.
*/
//public function onInit(layer:MovieClip):Void {
//
/**
* Dispatched when a the layer gets its initial information from the server.
* @param layer:MovieClip a reference to the layer.
*/
//public function onGetServiceInfo(layer:MovieClip):Void {
//	
/**
* Dispatched when a the layers collection is changed by setLayerProperty().
* @param layer:MovieClip A reference to the layer.
* @param ids:String  The affected layers.
*/
//public function onSetLayerProperty(layer:MovieClip, ids:String):Void {
//
/**
* Dispatched when a layer has data for a maptip.
* @param layer:MovieClip A reference to the layer.
* @param maptip:String  the maptip
*/
//public function onMaptipData(layer:MovieClip, maptip:String):Void {
//