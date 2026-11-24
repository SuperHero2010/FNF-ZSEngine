package backend;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import backend.Song.SwagSong;

class CoolUtil
{
	public static final MIN_VALUE_DOUBLE = 2.225073858507201383090232717332404064219215980462331830553327416887204434813918195854283159012511020564067339731035811005152434161553460108856012385377718821130777993532002330479610147442583636071921565046942503734208375250806650616658158948720491179968591639648500635908770118304874799780887753749949451580451605050915399856582470818645113537935804992115981085766051992433352114352390148795699609591288891602992641511063466313393663477586513029371762047325631781485664350872122828637642044846811407613911477062801689853244110024161447421618567166150540154285084716752901903161322778896729707373123334086988983175067838846926092773977972858659654941091369095406136467568702398678315290680984617210924625396728515625e-308;

	public static function checkForUpdates(url:String = null):String {
		if (url == null || url.length == 0)
			url = "https://raw.githubusercontent.com/SuperHero2010/FNF-ZSEngine/main/gitVersion.txt";
		var version:String = states.MainMenuState.zsEngineVersion.trim();
		if (ClientPrefs.data.checkForUpdates) {
			trace('checking for updates...');
			var http = new haxe.Http(url);
			http.onData = function (data:String)
			{
				var newVersion:String = data.split('\n')[0].trim();
				trace('version online: $newVersion, your version: $version');
				if (newVersion != version) {
					trace('versions aren\'t matching! please update');
					version = newVersion;
					http.onData = null;
					http.onError = null;
					http = null;
				}
			}
			http.onError = function (error) {
				trace('error: $error');
			}
			http.request();
		}
		return version;
	}
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

	inline public static function logX(value:Float, exp:Float) {
		return Math.log(value) / Math.log(exp);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	inline public static function floatToStringPrecision(number:Float, prec:Int, exponent:Bool = false){
		var str:String;
		var abs:Null<Float> = Math.abs(number);
		var len:Null<Int>;
		var result:String;
		if(!exponent || (abs >= Math.pow(0.1, prec) && abs < Math.pow(10, 6))) {
			str = Std.string(Math.fround(abs * Math.pow(10, prec)));
			len = str.length;
			if(len <= prec){
				// Smaller than 1
				while(len < prec){
					str = '0' + str;
					len++;
				}
				result = '0.' + str;
			} else {
				// Larger than 1
				if (str.length == prec) result = str;
				else {
					result = str.substr(0, str.length - prec) + (prec > 0 ? '.' + str.substr(str.length - prec) : '');
				}
			}
		} else {
			str = Std.string(Math.fround(abs * Math.pow(10, Math.floor(-logX(abs, 10))) * Math.pow(10, prec) * 10));
			result = (number > MIN_VALUE_DOUBLE ? str.substr(0, 1) + '.' + str.substr(1) : '0') + 'e' + Math.floor(logX(abs, 10));
		}
		str = null; len = null; abs = null;
		return (number < 0 ? "-" : "") + result;
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function getNoteAmount(song:SwagSong, ?bothSides:Bool = true, ?oppNotes:Bool = false):Int
	{
		var total:Int = 0;
		for (section in song.notes)
		{
			if (bothSides)
			{
				// Count only actual notes, exclude events (events have negative noteData)
				for (songNotes in section.sectionNotes)
				{
					if(songNotes != null && songNotes.length > 1 && songNotes[1] >= 0)
						total += 1;
				}
			}
			else
			{
				for (songNotes in section.sectionNotes)
				{
					// Exclude events (negative noteData)
					if(songNotes == null || songNotes.length < 2 || songNotes[1] < 0) continue;

					if (!oppNotes && (songNotes[1] < 4 ? section.mustHitSection : !section.mustHitSection))
						total += 1;
					if (oppNotes && (songNotes[1] < 4 ? !section.mustHitSection : section.mustHitSection))
						total += 1;
				}
			}
		}
		return total;
	}
}