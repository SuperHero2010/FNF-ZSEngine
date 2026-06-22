package;

#if android
import android.content.Context;
#end

import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

import backend.Highscore;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;
	public static var isConsoleAvailable:Bool = true;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		// Console availability detection (from H-Slice)
		try {
			Sys.stdout().writeString("Console Available!\n");
		} catch (e:Dynamic) {isConsoleAvailable = false;}

		#if (cpp && windows)
		backend.Native.fixScaling();
		#end

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// Modified and improved by SuperHero2010 for ZS Engine
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	/* Old function if you want to show the exact line of code that caused the crash, but it won't work
	function getSourceLine(filePath:String, lineNumber:Int):String
	{
		try
		{
			// Remove leading ./ or ../ from path if present
			var cleanPath = filePath;
			if (cleanPath.startsWith("./")) cleanPath = cleanPath.substr(2);
			if (cleanPath.startsWith("../")) cleanPath = cleanPath.substr(3);

			var possiblePaths = [
				cleanPath,
				"src/" + cleanPath,
				"source/" + cleanPath,
				"../" + cleanPath,
				"./" + cleanPath
			];

			var foundPath:String = null;
			for (path in possiblePaths)
			{
				if (FileSystem.exists(path))
				{
					foundPath = path;
					break;
				}
			}

			if (foundPath == null)
				return "     [Source file not found: " + filePath + "]";

			var content = sys.io.File.getContent(foundPath);
			var lines = content.split("\n");

			if (lineNumber - 1 >= 0 && lineNumber - 1 < lines.length)
			{
				var line = lines[lineNumber - 1];
				var trimmedLine = rtrim(line);
				return "     -> " + trimmedLine;
			}
			return "     [Line " + lineNumber + " not found]";
		}
		catch(e:Dynamic)
		{
			return "     [Could not read source: " + e + "]";
		}
	}

	function rtrim(str:String):String
	{
		var i = str.length - 1;
		while (i >= 0 && str.charAt(i) == ' ') i--;
		return str.substr(0, i + 1);
	}
	*/

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		var memInfo:String = "";
		#if cpp
		var memUsage = cpp.vm.Gc.memUsage();
		memInfo = "\n\n=== MEMORY INFO ===\n";
		memInfo += "Memory Usage: " + (memUsage / (1024 * 1024)) + " MB\n";
		#end

		var chartInfo:String = "";
		if (PlayState.SONG != null)
		{
			chartInfo = "\n\n=== CHART INFO ===\n";
			chartInfo += "Song: " + PlayState.SONG.song + "\n";
			if (PlayState.SONG.notes != null)
			{
				var totalNotes:Int = 0;
				for (section in PlayState.SONG.notes)
				{
					if (section != null && section.sectionNotes != null)
						totalNotes += section.sectionNotes.length;
				}
				chartInfo += "Total Notes: " + totalNotes + "\n";
				chartInfo += "Total Sections: " + PlayState.SONG.notes.length + "\n";
			}
		}

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		dateNow = dateNow.replace("/", "-");

		path = "./crash/" + "ZSEngine_" + dateNow + ".txt";

		errMsg += "=== ZS ENGINE CRASH REPORT ===\n";
		errMsg += "Date: " + Date.now().toString() + "\n";
		errMsg += "Platform: " + Sys.systemName() + "\n";
		errMsg += "\n=== STACK TRACE ===\n";

		var stackIndex:Int = 0;
		for (stackItem in callStack)
		{
			stackIndex++;
			errMsg += '[$stackIndex] $stackItem\n';
		}

		errMsg += "\n=== ERROR ===\n";
		errMsg += "Uncaught Error: " + e.error + "\n";

		errMsg += memInfo;
		errMsg += chartInfo;

		errMsg += "\n=== CRASH HANDLER INFO ===\n";
		errMsg += "Original crash handler by: sqirra-rng (Izzy Engine)\n";
		errMsg += "Modified and improved by: SuperHero2010 (ZS Engine)\n";

		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/SuperHero2010/FNF-ZSEngine/issues\n";
		#end

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		try {
			File.saveContent(path, errMsg);
			Sys.println("Crash dump saved in " + Path.normalize(path));
		} catch(saveError:Dynamic) {
			Sys.println("Failed to save crash dump: " + saveError);
		}

		Sys.println(errMsg);

		#if !html5
		try {
			Application.current.window.alert("ZSEngine has crashed!\n\nCrash log saved to:\n" + Path.normalize(path) + "\n\nPlease report this error if you continue to experience issues.", "ZS Engine - Crash");
		} catch(alertError:Dynamic) {}
		#end

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		Sys.exit(1);
	}
	#end
}