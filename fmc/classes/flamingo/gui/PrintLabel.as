﻿// This file is part of Flamingo MapComponents.
// Author: Michiel J. van Heek.

/** @component PrintLabel 
* A component that shows a text in a certain layout, within a print template.
* A user can change the text by clicking on it. 
* The text “[scale]” is substituted for the current scale of the corresponding map.
* @file flamingo/tpc/classes/flamingo/gui/PrintLabel.as  (sourcefile)
* @file flamingo/tpc/PrintLabel.fla (sourcefile)
* @file flamingo/tpc/PrintLabel.swf (compiled component, needed for publication on internet)
*/


/** @tag <tpc:PrintLabel> 
* This tag defines a print label. The print label should be registered as a listener to a map within the same template as the print label. 
* This way the print label can substitute the text “[scale]” to the actual and current scale of that map.
* @class flamingo.gui.PrintLabel extends AbstractComponent
* @hierarchy child node of PrintTemplate.
* @example
	<tpc:PrintTemplate id="printTemplate0" name="horizontaal A3" dpi="135" format="A3" orientation="landscape"
		listento="printLegend0,printMonitor0" maps="printMap0">
		....
			<tpc:PrintLabel name="titel" top="20"  left="50%" listento="printMap0"
			text="Grondwatergebieden (schaal: [scale])" fontfamily="arial" fontsize="60" alignment="center"/>
	</tpc:PrintTemplate>
* @attr text	(default value: “”) Text to be displayed.
* @attr fontfamily	(“serif-embed”, “sans-serif-embed”, “monospace-embed”, or any system font, default value: Flamingo's general style setting) 
* Name of the font in which the text be displayed. If a system font is used instead of one of the three embedded  fonts, 
* parts of the print label may not be visible on the print, despite the fact that they are visible in the preview.
* @attr fontsize	(default value: Flamingo's general style setting) Size of the font in which the text be displayed.
* @attr alignment	("left", "center", "right", default value: “left”) Alignment of the text relative to the position of the print label component.
*/

import flamingo.gui.*;

import mx.controls.Label;
import mx.controls.TextArea;
import mx.utils.Delegate;

class flamingo.gui.PrintLabel extends AbstractComponent {
    
    private var text:String = "";
    private var fontFamily:String = null;
    private var fontSize:Number = null;
    private var alignment:String = "left";
    
    private var printTemplate:MovieClip = null;
    private var mapPrintLabelAdapter:MapPrintLabelAdapter = null;
    
    private var label:Label = null;
    private var textArea:TextArea = null;
    
    function setAttribute(name:String, value:String):Void {
        if (name == "text") {
            text = value;
        } else if (name == "fontfamily") {
            fontFamily = value;
        } else if (name == "fontsize") {
            fontSize = Number(value);
        } else if (name == "alignment") {
            alignment = value;
        }
    }
    
    function init():Void {
        var style:Object = _global.flamingo.getStyleSheet("flamingo").getStyle(".general");
        if (fontFamily == null) {
            fontFamily = style.fontFamily;
        }
        if (fontSize == null) {
            fontSize = style.fontSize;
        }
        
        printTemplate = getParent("PrintTemplate");
    }
    
    function go():Void {
        var maps:Array = printTemplate.getMaps();
        if (maps.length > 0) {
            mapPrintLabelAdapter = new MapPrintLabelAdapter(this);
            _global.flamingo.addListener(mapPrintLabelAdapter, maps[0], this);
        }
        
        addLabel();
    }
    
    function setText(text:String):Void {
        if (this.text == text) {
            return;
        }
        
        this.text = text;
        
        setComponentsText();
    }
    
    private function addLabel():Void {
        label = Label(attachMovie("Label", "mLabel", 0, {autoSize: alignment}));
        if (fontFamily.indexOf("embed") > -1) {
            label.setStyle("embedFonts", true);
        }
        setComponentsText();
        
        var env:PrintLabel = this;
        label.onPress = function():Void {
            env.addTextArea();
        }
    }
    
    private function addTextArea():Void {
        var initObject:Object = new Object();
        initObject["hScrollPolicy"] = "off";
        initObject["vScrollPolicy"] = "off";
        textArea = TextArea(attachMovie("TextArea", "mTextArea", 1, initObject));
        if (fontFamily.indexOf("embed") > -1) {
            textArea.setStyle("embedFonts", true);
        }
        textArea.addEventListener("change", Delegate.create(this, onChangeTextArea));
        textArea.addEventListener("focusOut", Delegate.create(this, onFocusOutTextArea));
        textArea.setFocus();
        setComponentsText();
    }
    
    private function removeTextArea():Void {
        if (textArea != null) {
            textArea.removeMovieClip();
            textArea = null;
        }
    }
    
    function onChangeTextArea():Void {
        setText(textArea.text);
    }
    
    function onFocusOutTextArea():Void {
        removeTextArea();
    }
        
    function setComponentsText():Void {
        var numLines:Number = 1;
        for (var i:Number = 0; i < text.length; i++) {
            if (text.charCodeAt(i) == 13) {
                numLines++;
            }
        }
		
        if (text.indexOf("[scale]") <> -1)  {
            var maps:Array = printTemplate.getMaps();
            if (maps.length > 0) {
                var scale:Number = Math.round(maps[0].getCurrentScale() / (0.0254 / 72) * getParent("PrintTemplate").getDPIFactor());
                label.text = text.split("[scale]").join("1:" + scale);
            } else {
                label.text = text.split("[scale]").join("1:???");
            }
        } else if (text.indexOf("[curdate]") <> -1) {
			var curDate:Date = new Date(); 
			var curDateStr:String = curDate.getDate() + "-" + String(curDate.getMonth() + 1) + "-"+ curDate.getFullYear() + " " + curDate.getHours() + ":" + curDate.getMinutes();
			label.text = text.split("[curdate]").join(curDateStr);
		} else {
			label.text = text
		}
        label.setSize(label._width, numLines * fontSize * 1.3);
        
        if (textArea != null) {
            textArea.text = text;
            textArea._x = label._x - 2;
            textArea.setSize(label._width + 20, numLines * fontSize * 1.3 + 20);
        }
    }
    
}
