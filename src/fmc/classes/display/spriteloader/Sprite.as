import display.spriteloader.event.SpriteMapEvent;
import display.spriteloader.SpriteMap;
import display.spriteloader.SpriteSettings;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import mx.utils.Delegate;
/** 
 * display.spriteloader.Sprite
 * @author Stijn De Ryck 
 */
class display.spriteloader.Sprite extends MovieClip {

	//used to register this class as though it was in the Library
	private static var symbolName:String = "__Packages.display.spriteloader.Sprite";
	private static var symbolOwner:Function = Sprite;
	private static var symbolLinked = Object.registerClass(symbolName, symbolOwner);
	private var _size:Number = 20;
	private var _spriteMap:SpriteMap;
	private var _mapOffsetX:Number = 0;
	private var _mapOffsetY:Number = 0;
	private var _mapAreaWidth:Number = 0;
	private var _mapAreaHeight:Number = 0;
	private var thisObj:Sprite;
	
    /**
     * constructor
     */
	public function Sprite() 
	{
			thisObj = this;
	}
	/**
	 * create
	 * @param	spriteMap
	 * @param	target
	 * @param	instanceName
	 * @param	settings
	 * @param	depth
	 * @return
	 */
	public static function create(spriteMap:SpriteMap, target:MovieClip,instanceName:String,settings:SpriteSettings,depth:Number):Sprite
	{
		var params:Object = (settings instanceof SpriteSettings) ? settings : new SpriteSettings();
		params.spriteMap = spriteMap;
		if (depth == undefined) depth = target.getNextHighestDepth();
		var ico:Sprite = Sprite(target.attachMovie(symbolName, instanceName, depth, params));
		if (!spriteMap.loaded) {
			spriteMap.addEventListener(SpriteMapEvent.LOAD_COMPLETE, function(){ico.invalidate()}); // wrapped in function to keep the this-context on draw()
		}else {
			ico.invalidate();
		}
		return ico;
	}
	
	
	private function invalidate()
	{
		var bmpArea:BitmapData = new BitmapData(_mapAreaWidth,_mapAreaHeight,true,0xffffffff);
		bmpArea.copyPixels(spriteMap.bitmapData, new Rectangle(_mapOffsetX, _mapOffsetY, _mapAreaWidth, _mapAreaHeight), new Point(0, 0));
		this.attachBitmap(bmpArea,0);
	}
	
	
	/**
	 * applyNewSettings
	 * @param	settings
	 */
	public function applyNewSettings(settings:SpriteSettings):Void 
	{
		for ( var prop:String in  settings)
		{
			//We only process defined properties
			if (settings[prop] != undefined)
			{
				/*don't apply each SpriteSetting prop idividually to the setters of this class, 
				  because they would trigger an invalidate / redraw for each setter that is altered.
				  Instead we target the private vars that are named simmilarly but with underscore.
				  when done with defining vars in loop trigger single redraw. */
				var propNamePrivate:String = ((prop.substr(0, 1)) == '_') ? prop : '_' + prop;  /*_x, _y, _visible, and _alpha allready have an underscore.*/
				/*apply sprite area settings to private class vars and the others 
				  to the extended Movieclip public setters (_x, _y, _visible, and _alpha)*/
				this[propNamePrivate] = settings[prop]; 
			}
		}
		//now redraw
		invalidate();
		
	}
	
	/**
	 * getter spriteMap
	 */
	public function get spriteMap():SpriteMap 
	{
		return _spriteMap;
	}
	/**
	 * setter spriteMap
	 */
	public function set spriteMap(value:SpriteMap):Void 
	{
		//only allow once from the create() function which does an attachMovie( with an initParamsObject ) that gets applied 
		//to this class instance, then prevent further access.
		if (!_spriteMap) {
			_spriteMap = value;
		}else {
			trace('SpriteIcon:set spriteMap() is not accessible');
		}
		
	}
	/**
	 * getter mapOffsetX
	 */
	public function get mapOffsetX():Number 
	{
		return _mapOffsetX;
	}
	/**
	 * setter mapOffsetX
	 */
	public function set mapOffsetX(value:Number):Void 
	{
		_mapOffsetX = value;
		invalidate();
	}
	/**
	 * getter mapOffsetY
	 */
	public function get mapOffsetY():Number 
	{
		return _mapOffsetY;
	}
	/**
	 * setter mapOffsetY
	 */
	public function set mapOffsetY(value:Number):Void 
	{
		_mapOffsetY = value;
		invalidate();
	}
	/**
	 * getter mapAreaWidth
	 */
	public function get mapAreaWidth():Number 
	{
		return _mapAreaWidth;
	}
	/**
	 * setter mapAreaWidth
	 */
	public function set mapAreaWidth(value:Number):Void 
	{
		_mapAreaWidth = value;
		invalidate();
	}
	/**
	 * getter mapAreaHeight
	 */
	public function get mapAreaHeight():Number 
	{
		return _mapAreaHeight;
	}
	/**
	 * setter mapAreaHeight
	 */
	public function set mapAreaHeight(value:Number):Void 
	{
		_mapAreaHeight = value;
		invalidate();
	}
	
	

}