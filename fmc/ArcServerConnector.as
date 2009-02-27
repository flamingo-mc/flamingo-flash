﻿/*-----------------------------------------------------------------------------
Created by : Abeer.Mahdi@realworld-systems.com
		     Realworld systems 
			 tel: 0345 614406
-----------------------------------------------------------------------------*/
class ArcServerConnector {
	//meta
	var version:String = "F2";
	//algemeen
	var server:String = "";
	var service:String = "";
	var servlet:String = "/ArcGIS/services/";
	var dataframe = "Layers";
	var xmlheader:String = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>";
	//getServiceInfo defaults
	var renderer:Boolean = false;
	var extensions:Boolean = false;
	var fields:Boolean = false;
	var mapscale:Number;
	//getImage defaults
	var outputtype:String = "png24";
	var map:Boolean = true;
	var backgroundcolor:Number = 0xFFFFFF;
	var transcolor:Number = 0xFFFFFF;
	var layerliststring:String = "";
	var legend:Boolean = false;
	var legendcolor:Number = 0xffffff;
	var legendwidth:Number = 250;
	var legendfont:String = "arial";
	var titlefontsize:Number = 12;
	var valuefontsize:Number = 12;
	var layerfontsize:Number = 12;
	var legendcolumns:Number = 1;
	//getFeatures defaults
	var featurelimit:Number = 10;
	var skipfeatures:Boolean = false;
	var geometry:Boolean = false;
	var envelope:Boolean = false;
	var beginrecord:Number = 1;
	var request:String;
	var response:String;
	var responsetime:Number;
	var error:String;
	var url:String;
	var requesttype:String;
	var subFields:Array=new Array();
	var featureNumber:Number = 0;
	var imageurl:String;
	var selectedFID:Array = new Array();
	//-----------------------
	private var busy:Boolean = false;
	private var layerid:String;
	private var events:Object;
	private var requestid:Number = 0;
	//private var requesttype:String;
	//private var url:String;
	//private var xrequest:XML;
	//private var xresponse:XML;
	//private var error:String;
	//private var time:Date;
	//-----------------------
	//-----------------------
	function addListener(listener:Object) {
		events.addListener(listener);
	}
	function removeListener(listener:Object) {
		events.removeListener(listener);
	}
	function ArcServerConnector(server:String) {
		this.server = server;
		events = new Object();
		AsBroadcaster.initialize(events);
	}
	private function _getUrl():String {
		var _server:String = this.server;
		var _service:String = this.service;
		var _servlet:String = this.servlet;
		if (_server == "") {
			_server = _root._url;
			var p:Number = _server.indexOf("//", 0);
			p = _server.indexOf("/", p+2);
			_server = _server.substr(0, p);
		}
		if (_server.substr(_server.length-1, 1).toLowerCase() != "/") {
			_server = _server+"/";
		}
		if (_server.substr(0, 4).toLowerCase() != "http" and _server.substr(0, 4).toLowerCase() != "file") {
			_server = "http://"+_server;
		}
		var extra = "";
		if (_servlet.substr(0, 1).toLowerCase() == "/") {
			_servlet = _servlet.substr(1, _servlet.length-1);
		}
		var extra:String = "";
		var service:String = "";
		return (_server+_servlet+_service+"/MapServer");
	}
	private function _sendrequest(sxml:String, requesttype:String, objecttag:Object):Number {
		if (this.busy) {
			this.error = "busy processing request...";
			this.events.broadcastMessage("onError", this.error, objecttag, this.requestid);
			return;
		}
		this.requestid++;
		this.requesttype = requesttype;
		this.busy = true;
		this.url = this._getUrl(requesttype);
		this.request = sxml;
		var xrequest:XML = new XML(sxml);
		xrequest.contentType = "text/xml";
		var xresponse:XML = new XML();
		xresponse.ignoreWhite = true;
		var thisObj:Object = this;
		this.error = "";
		this.response = "";
		this.events.broadcastMessage("onRequest", this);
		
		xresponse.onLoad = function(success:Boolean):Void  {
			thisObj.response = this.toString();
			thisObj.responsetime = (new Date()-starttime)/1000;

			if (success) {
				if (this.firstChild.nodeName == "ERROR") {
					thisObj.error = this.firstChild.childNodes[0].nodeValue;
					thisObj.events.broadcastMessage("onResponse", thisObj);
					thisObj.events.broadcastMessage("onError", thisObj.error, objecttag, thisObj.requestid);
				} else if (this.firstChild.firstChild.nodeName == "ERROR") {
					thisObj.error = this.firstChild.firstChild.childNodes[0].nodeValue;
					thisObj.events.broadcastMessage("onResponse", thisObj);
					thisObj.events.broadcastMessage("onError", thisObj.error, objecttag, thisObj.requestid);
				} else if (this.firstChild.firstChild.firstChild.nodeName == "ERROR") {
					error = this.firstChild.firstChild.firstChild.childNodes[0].nodeValue;
					thisObj.events.broadcastMessage("onResponse", thisObj);
					thisObj.events.broadcastMessage("onError", thisObj.error, objecttag, thisObj.requestid);
				} else {
					thisObj.events.broadcastMessage("onResponse", thisObj);
					switch (requesttype) {
					case "getServices" :
						thisObj._processServices(this, objecttag, thisObj.requestid);
						break;
					case "getImage" :
						thisObj._processImage(this, objecttag, thisObj.requestid);
						break;
					case "getQueryFeatureIDs" :
						thisObj._processQueryFeatureIDs(this, objecttag, thisObj.requestid);
						break;
					case "getServiceInfo" :
						thisObj._processServiceInfo(this, objecttag, thisObj.requestid);
						break;
					case "getFeatures" :
						thisObj._processFeatures(this, objecttag, thisObj.requestid);
						break;
					}
				}
			} else {
				thisObj.error = "connection failed...";
				thisObj.events.broadcastMessage("onResponse", thisObj);
				thisObj.events.broadcastMessage("onError", thisObj.error, objecttag, thisObj.requestid);
			}
			thisObj.busy = false;
			delete this;
		};
		var starttime:Date = new Date();
		xrequest.sendAndLoad(url, xresponse);
		return (thisObj.requestid);
	}
	function getServices(objecttag:Object):Number {
		var sxml:String = this.xmlheader+"\n";
		return (this._sendrequest(sxml, "getServices", objecttag));
	}
	private function _processServices(xml:XML, objecttag:Object, requestid:Number):Void {
		var services:Object = new Object();
		var xnSERVICES = xml.firstChild.firstChild.firstChild.childNodes;
		for (var i = 0; i<xnSERVICES.length; i++) {
			if (xnSERVICES[i].nodeName == "SERVICE") {
				var s:Object = new Object();
				s.name = xnSERVICES[i].attributes.name;
				s.servicegroup = xnSERVICES[i].attributes.servicegroup;
				s.access = xnSERVICES[i].attributes.access;
				s.type = xnSERVICES[i].attributes.type;
				s.version = xnSERVICES[i].attributes.version;
				s.status = xnSERVICES[i].attributes.status;
				services[s.name] = s;
			}
		}
		this.events.broadcastMessage("onGetServices", services, objecttag, requestid);
	}
	function getServiceInfo(service:String, objecttag:Object):Number {
		if (service != undefined) {
			this.service = service;
		}
		var sxml:String = this.xmlheader+"\n";//+"\n<GETCLIENTSERVICES/>";
		sxml += "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"";
		sxml +="xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"";
		sxml +="xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n<SOAP-ENV:Body>\n<m:GetServerInfo xmlns:m=\"http://www.esri.com/schemas/ArcGIS/9.2\">\n";
		sxml +="<MapName>"+dataframe+"</MapName>\n</m:GetServerInfo>\n</SOAP-ENV:Body>\n</SOAP-ENV:Envelope>"
		return (this._sendrequest(sxml, "getServiceInfo", objecttag));
	}
	private function _processServiceInfo(xml:XML, objecttag:Object, requestid:Number):Void {
		var layer:Object;
		var field:Object;
		var layers = new Object();
		var extent = new Object();
		var scalefactor:Number = 4000;
		var xnSI = xml.firstChild.firstChild.firstChild.firstChild.childNodes;
		for (var i:Number = 0; i<xnSI.length; i++)
		{
			switch(xnSI[i].nodeName)
			{
				case "MapLayerInfos" :
					var layersInfo = xnSI[i].childNodes;
					for (var j:Number = 0; j<layersInfo.length; j++)
					{
						layer = new Object();
						var layerChilds = layersInfo[j].childNodes;
						for(var k:Number = 0; k<layerChilds.length; k++)
						{
							layer.legend = true;
							layer.query = "";
							switch(layerChilds[k].nodeName)
							{
								case "LayerType" :
									layer.type = layerChilds[k].childNodes[0].nodeValue;
									break;
								case "Name" :
									layer.name = layerChilds[k].childNodes[0].nodeValue;
									break;
								case "LayerID" :
									layer.id = layerChilds[k].childNodes[0].nodeValue;
									break;
								case "MinScale" :
									if(layerChilds[k].childNodes[0].nodeValue == 0){
										layer.maxscale = undefined;
									}
									else{
										layer.maxscale = (layerChilds[k].childNodes[0].nodeValue)/scalefactor;
									}
									break;
								case "MaxScale" :
									if(layerChilds[k].childNodes[0].nodeValue == 0){
										layer.minscale = undefined;
									}
									else{
										layer.minscale = (layerChilds[k].childNodes[0].nodeValue)/scalefactor;
									}
									break;
//								case "Extent":
//									var layerExtent = layerChilds[k].childNodes[0].childNodes;
//									for(var g:Number = 0; g<layerExtent.length; g++)
//									{
//										switch(layerExtent[g].nodeName){
//											case "XMin":
//												layer.minx = this._asNumber(layerExtent[g].childNodes[0].nodeValue);
//												break;
//											case "YMin":
//												layer.miny = this._asNumber(layerExtent[g].childNodes[0].nodeValue);
//												break;
//											case "XMax":
//												layer.maxx = this._asNumber(layerExtent[g].childNodes[0].nodeValue);
//												break;
//											case "YMax":
//												layer.maxy = this._asNumber(layerExtent[g].childNodes[0].nodeValue);
//											break;
//										}
//									}
//								break;
								case "Fields" :
									layer.fields = new Object();
									var field_array = layerChilds[k].childNodes[0].childNodes;
									for(var l:Number = 0; l<field_array.length; l++)
									{
										field = new Object();
										var field_info = field_array[l].childNodes;
										for(var m:Number = 0; m<field_info.length; m++)
										{
											switch(field_info[m].nodeName)
											{
												case "Name" :
													field.name = field_info[m].childNodes[0].nodeValue;
													field.shortname = field_info[m].childNodes[0].nodeValue;
													break;
												case "Type" :
													field.type = field_info[m].childNodes[0].nodeValue;
													break;
												case "Length" :
													field.size = field_info[m].childNodes[0].nodeValue;
													break;
												case "Precision" :
													field.precision = field_info[m].childNodes[0].nodeValue;
													break;
											}
										}
										layer.fields[field.name] = field;
									}
									break;
							}
						}
						layers[layer.id] = layer;
					}
					break;

				case "DefaultMapDescription" :
					var mapDescription = xnSI[i].childNodes;
					for (var j:Number = 0; j<mapDescription.length; j++)
					{
						switch(mapDescription[j].nodeName){
							case "LayerDescriptions":
								var layerDescriptions = mapDescription[j].childNodes;
								for(var k:Number = 0; k<layerDescriptions.length; k++)
								{
									var layerDescription = layerDescriptions[k].childNodes;
									var layerID;
									for(var l:Number = 0; l<layerDescription.length; l++)
									{
										switch(layerDescription[l].nodeName)
										{
											case "LayerID": 
												layerID = layerDescription[l].childNodes[0].nodeValue;
												break;
											case "Visible":
												layers[layerID].visible = layerDescription[l].childNodes[0].nodeValue;
												break;
											case "DefinitionExpression":
												layers[layerID].query = layerDescription[l].childNodes[0].nodeValue;
												break;
										}	
									}
								}
							break;
						}
					}
				break;
				case "Extent" :
					var extentInfo = xnSI[i].childNodes;
					for (var j:Number = 0; j<extentInfo.length; j++)
					{
						switch(extentInfo[j].nodeName)
						{
							case "XMin":
								extent.minx = this._asNumber(extentInfo[j].childNodes[0].nodeValue);
								break;
							case "YMin":
								extent.miny = this._asNumber(extentInfo[j].childNodes[0].nodeValue);
								break;
							case "XMax":
								extent.maxx = this._asNumber(extentInfo[j].childNodes[0].nodeValue);
								break;
							case "YMax":
								extent.maxy = this._asNumber(extentInfo[j].childNodes[0].nodeValue);
								break;
						}
					}
					break;
			}
		}
		this.events.broadcastMessage("onGetServiceInfo", extent, layers, objecttag, requestid);
	}
	function getImage(service:String, extent:Object, size:Object, layers:Object, objecttag:Object):Number {
		if (service != undefined) {
			this.service = service;
		}
		var str:String = this.xmlheader+"\n";
		var rgb1:Object = _getRGB(this.backgroundcolor);
		
		str += "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" ";
        str +="xmlns:SOAP-ENC=\" http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" ";
        str += "xmlns:xsd=\" http://www.w3.org/2001/XMLSchema\" xmlns:m0=\"http://www.esri.com/schemas/ArcGIS/9.3\">\n<SOAP-ENV:Body>\n";
        str += "<m:ExportMapImage xmlns:m=\"http://www.esri.com/schemas/ArcGIS/9.3\">\n<MapDescription>\n";
        str +="<Name>"+dataframe+"</Name>\n<MapArea xsi:type=\"m0:MapExtent\">\n<Extent xsi:type=\"m0:EnvelopeN\">\n";
		str += "<XMin>"+extent.minx+"</XMin>\n";
		str += "<YMin>"+extent.miny+"</YMin>\n";
		str += "<XMax>"+extent.maxx+"</XMax>\n";
		str += "<YMax>"+extent.maxy+"</YMax>\n";
		str +="</Extent>\n</MapArea>\n<LayerDescriptions>";

		for(var i in layers){
			if(layers[i].id != undefined && layers[i].visible != undefined){
				str +="<LayerDescription>\n<LayerID>"+layers[i].id+"</LayerID>\n";
				str +="<Visible>"+layers[i].visible+"</Visible>\n<ShowLabels>true</ShowLabels>\n";
				if(layers[i].query != undefined) {
					str +="<ScaleSymbols>true</ScaleSymbols>\n<SelectionFeatures>\n";
					for(var j:Number = 0; j< selectedFID.length; j++){
						str += "<Int>"+selectedFID[j]+"</Int>\n";		
					}
					str +="</SelectionFeatures>\n<SetSelectionSymbol>true</SetSelectionSymbol>";
					
					if(layers[i].query != undefined && layers[i].query != "") {
						var q:String = layers[i].query.toString();
						str +="<DefinitionExpression>"+q+"</DefinitionExpression>\n";				
					}
				}
				str +="</LayerDescription>";
			}
		}
		str +="</LayerDescriptions>\n<TransparentColor xsi:type=\"m:RgbColor\">\n<Red>255</Red>\n<Green>255</Green>\n<Blue>255</Blue>\n";
		str +="<UseWindowsDithering>true</UseWindowsDithering>\n<AlphaValue>50</AlphaValue>\n</TransparentColor>\n";
		str +="</MapDescription>\n<ImageDescription>\n<ImageType>\n<ImageFormat>esriImagePNG24</ImageFormat>\n"; 
		str +="<ImageReturnType>esriImageReturnURL</ImageReturnType>\n</ImageType>\n<ImageDisplay>\n<ImageHeight>"+size.height+"</ImageHeight>\n";
        str +="<ImageWidth>"+size.width+"</ImageWidth>\n<ImageDPI>"+size.dpi+"</ImageDPI>\n</ImageDisplay>\n</ImageDescription>\n";
        str +="</m:ExportMapImage>\n</SOAP-ENV:Body>\n</SOAP-ENV:Envelope>"; 
		//trace(str);
		return (this._sendrequest(str, "getImage", objecttag));
	}

	private function _processImage(xml:XML, objecttag:Object, requestid:Number):Void {
//		trace(xml);
		var extent = new Object();

		var legendurl:String;
		var xnIMAGE:Array = xml.firstChild.firstChild.firstChild.childNodes;
		if(xnIMAGE[0].nodeName == "faultcode"){
			return;
		}
		var result:Array = xnIMAGE[0].childNodes;
		var result2:Array = result[0].childNodes;
		imageurl = result2[0].nodeValue;
		var resultExtent:Array = result[1].childNodes;
		var XMin = resultExtent[0].firstChild.nodeValue;
		var YMin = resultExtent[1].firstChild.nodeValue;
		var XMax = resultExtent[2].firstChild.nodeValue;
		var YMax = resultExtent[3].firstChild.nodeValue;

		extent.minx = this._asNumber(XMin);
		extent.miny = this._asNumber(YMin);
		extent.maxx = this._asNumber(XMax);
		extent.maxy = this._asNumber(YMax);

		this.events.broadcastMessage("onGetImage", extent, imageurl , legendurl, objecttag, requestid);
	}
	//gets the id of features in a layer.
	function getQueryFeatureIDs(service:String, layerid:String, query:String, objecttag:Object){
		if (service != undefined) {
			this.service = service;
		}
		if(layerid == "undefined"){
			return;
		}
		this.layerid = layerid;
		var str:String = this.xmlheader+"\n";
		str +="<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" ";
		str +="xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" ";
		str +="xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n<SOAP-ENV:Body>\n";
		str +="<m:QueryFeatureIDs xmlns:m=\"http://www.esri.com/schemas/ArcGIS/9.3\">";
		str +="<MapName>Layers</MapName>\n";
		str +="<LayerID>"+layerid+"</LayerID>\n";
		str +="<QueryFilter><WhereClause>"+query+"</WhereClause>\n</QueryFilter>";
		str +="</m:QueryFeatureIDs>\n</SOAP-ENV:Body>\n</SOAP-ENV:Envelope>";
		return (this._sendrequest(str, "getQueryFeatureIDs", objecttag));
	}
	private function _processQueryFeatureIDs(xml:XML, objecttag:Object, requestid:Number):Void {
		var xnQuery:Array = xml.firstChild.firstChild.firstChild.childNodes;
		var fid:Array = xnQuery[0].childNodes[0].childNodes;
		for (var i:Number = 0; i<fid.length; i++)
		{
			if(fid[i].nodeName == "Int"){
				selectedFID[i] = fid[i].firstChild.nodeValue;
			}
		}
		this.events.broadcastMessage("onGetQueryFeatureIDs", selectedFID, objecttag, requestid);
	}
	
	function getFeatures(service:String, layerid:String, extent:Object, subfields:String, query:String, objecttag:Object):Number {
		if(layerid == "undefined"){
			return;
		}
		this.layerid = layerid;
		if (service != undefined) {
			this.service = service;
		}
		if (subfields == undefined) {
			subFields[0] = "#ALL#";
		}
		else{
			var a_subfield = subfields.split(",");
			for (var i = 0; i<a_subfield.length; i++) {
				subFields[i] = a_subfield[i];
			}
		}
		
		if (query == undefined) {
			query = "";
		}

		var str:String = this.xmlheader+"\n";
		str +="<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" ";
		str +="xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" ";
		str +="xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n<SOAP-ENV:Body>\n";
		str +="<m:Identify xmlns:m=\"http://www.esri.com/schemas/ArcGIS/9.3\">\n<MapDescription>\n";
        str +="<Name>"+dataframe+"</Name>\n<LayerDescriptions>\n";

		if(layerid != undefined)
		{
			str +="<LayerDescription>\n<LayerID>"+layerid+"</LayerID>\n";
			if(query != undefined &&query != "") 
			{
				str +="<DefinitionExpression>"+query+"</DefinitionExpression>\n";				
			}
			str +="</LayerDescription>";
		}
		str +="</LayerDescriptions>\n</MapDescription>/n";
		
		str +="<MapImageDisplay>\n<ImageHeight>0</ImageHeight>\n";
		str +="<ImageWidth>0</ImageWidth>\n<ImageDPI>96</ImageDPI>\n</MapImageDisplay>\n";
		str +="<SearchShape xsi:type=\"m:EnvelopeN\">\n";

		if(extent != undefined)
		{
			str +="<XMin>"+extent.minx+"</XMin>\n";
			str +="<YMin>"+extent.miny+"</YMin>\n";
			str +="<XMax>"+extent.maxx+"</XMax>\n";
			str +="<YMax>"+extent.maxy+"</YMax>\n";
		}
		str +="</SearchShape>\n";		
		str +="<Tolerance>0</Tolerance>\n<IdentifyOption>esriIdentifyAllLayers</IdentifyOption>\n";
		str +="<LayerIDs>\n<Int>"+layerid+"</Int></LayerIDs>\n</m:Identify>\n</SOAP-ENV:Body>\n</SOAP-ENV:Envelope>";
		//trace(str);
		return (this._sendrequest(str, "getFeatures", objecttag));
	}
	private function _processFeatures(xml:XML, objecttag:Object, requestid:Number):Void {
		//trace(xml);
		var hasmore:Boolean = false;
		var count:Number=0;
		var data:Array = new Array();
		var xy:Object = new Object();
		var FEATURES = xml.firstChild.firstChild.firstChild.firstChild.childNodes;
		for (var i = 0; i<FEATURES.length; i++) {
			var record:Object = new Object();
			var FEATURE = FEATURES[i].childNodes;
			for (var j = 0; j<FEATURE.length; j++) {
				switch (FEATURE[j].nodeName) {
				case "Properties" :
					var FIELDS = FEATURE[j].firstChild.childNodes;
					for (var k = 0; k<FIELDS.length; k++) {
						var featureKey:String= FIELDS[k].firstChild.firstChild.nodeValue;
						var featureValue = FIELDS[k].lastChild.firstChild.nodeValue;
						record[featureKey] = featureValue;
					}
					count = FIELDS.length;
					break;
				case "Shape" :
					var SHAPE = FEATURE[j].childNodes;
					for (var k = 0; k<SHAPE.length; k++) {
						switch (SHAPE[k].nodeName) {							
						case "Extent" :
							var EXTENT = SHAPE[k].childNodes;
							var ext:Object = new Object();
							for(var l = 0; l<EXTENT.length; l++) {
								switch (EXTENT[l].nodeName) {
								case "XMin" :
									ext.minx = EXTENT[l].firstChild.nodeValue;
									break;
								case "YMin" :
									ext.miny = EXTENT[l].firstChild.nodeValue;
									break;
								case "XMax" :
									ext.maxx = EXTENT[l].firstChild.nodeValue;
									break;
								case "YMax" :
									ext.maxy = EXTENT[l].firstChild.nodeValue;
									break;
								}
							}
							record["SHAPE.ENVELOPE"] = ext;										
							break;
							case "X" :
								xy.x = SHAPE[k].firstChild.nodeValue;
								break;
							case "Y" :
								xy.y = SHAPE[k].firstChild.nodeValue;
								var range:Number = 10;
								var ext:Object = new Object();							
								ext.minx = Number(xy.x) - range;
								ext.miny = Number(xy.y) - range;
								ext.maxx = Number(xy.x) + range;
								ext.maxy = Number(xy.y) + range;
								record["SHAPE.ENVELOPE"] = ext;	
								break;
						}
					}
					count = SHAPE.length;
					break;
				}
			}
			data.push(record);
		}
		if(count > 1)
		{
			hasmore = true;
		}
		this.events.broadcastMessage("onGetFeatures", this.layerid, data, count, hasmore, objecttag, requestid);
	}
	private function _asNumber(s:String):Number {
		if (s == undefined) {
			return (undefined);
		}
		if (s.indexOf(",", 0) != -1) {
			var a:Array = s.split(",");
			s = a[0]+"."+a[1];
		}
		return (Number(s));
	}
	private function _stripGeodatabase(s:String):String {
		var a:Array = s.split(".");
		return (a[a.length-1]);
	}
	private function _getRGB(hex:Number):Object {
		return ({r:hex >> 16, g:(hex & 0x00FF00) >> 8, b:hex & 0x0000FF});
	}
}