package debug;

import haxe.CallStack;
import sys.io.File;
import sys.FileSystem;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.iris.Iris;
#end

class HaxeDebugger
{
    public static var enabled:Bool = true;
    public static var logToFile:Bool = true;
    public static var logPath:String = "";

    static inline var RESET = "\x1b[0m";
    static inline var RED = "\x1b[31m";
    static inline var GREEN = "\x1b[32m";
    static inline var YELLOW = "\x1b[33m";
    static inline var MAGENTA = "\x1b[35m";
    static inline var CYAN = "\x1b[36m";

    static function getLogPath():String
    {
        if (logPath == "")
        {
            var date = Date.now();
            var dateStr = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + "_" + date.getHours() + "-" + date.getMinutes() + "-" + date.getSeconds();
            logPath = "./debug/Haxe/Haxe-debug-" + dateStr + ".log";
        }
        return logPath;
    }

    public static function log(message:String, ?level:String = "INFO"):Void
    {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var logMessage = '[$timestamp] [$level] $message';

        var color = switch(level) {
            case "ERROR": RED;
            case "WARNING": YELLOW;
            case "SUCCESS": GREEN;
            case "HSCRIPT": MAGENTA;
            default: CYAN;
        }

        Sys.println(color + logMessage + RESET);

        if (logToFile)
        {
            try {
                var path = getLogPath();
                var file = sys.io.File.append(path, false);
                file.writeString(logMessage + "\n");
                file.close();
            } catch(e:Dynamic) {}
        }
    }

    public static function logScript(scriptPath:String, message:String, ?level:String = "HSCRIPT"):Void
    {
        log('[$scriptPath] $message', level);
    }

    #if HSCRIPT_ALLOWED
    public static function enableTraceCapture(script:HScript, scriptPath:String):Void
    {
        try
        {
            var logFile = getLogPath();

            script.set("trace", function(v:Dynamic) {
                var msg = Std.string(v);
                var timestamp = Date.now().toString();

                if (logToFile)
                {
                    try {
                        var file = sys.io.File.append(logFile, false);
                        file.writeString('[$timestamp] [$scriptPath] [TRACE] $msg\n');
                        file.close();
                    } catch(e:Dynamic) {}
                }

                Sys.println('[$timestamp] [$scriptPath] [TRACE] $msg');
                return null;
            });

            logScript(scriptPath, "Trace capture installed", "SUCCESS");
        }
        catch(e:Dynamic)
        {
            logScript(scriptPath, 'Failed to capture trace: $e', "ERROR");
        }
    }
    #end

    public static function checkHxFile(path:String):Bool
    {
        if (!FileSystem.exists(path))
        {
            log('Haxe script not found: $path', "ERROR");
            return false;
        }

        var content = File.getContent(path);
        var lineCount = content.split("\n").length;
        log('Haxe script found: $path ($lineCount lines)', "SUCCESS");
        return true;
    }

    #if HSCRIPT_ALLOWED
    public static function testHxScript(scriptPath:String):Void
    {
        log('Testing Haxe script: $scriptPath', "INFO");

        if (!checkHxFile(scriptPath)) return;

        try {
            var script = new HScript(null, scriptPath);
            enableTraceCapture(script, scriptPath);
            log('Haxe script compiled successfully: $scriptPath', "SUCCESS");
            script.destroy();
        } catch(e:Dynamic) {
            log('Haxe script compilation failed: $scriptPath - $e', "ERROR");
        }
    }
    #end

    public static function scanModsForHx():Void
    {
        log('Scanning mods for Haxe scripts...', "INFO");

        var modsPath = "mods/";
        if (!FileSystem.exists(modsPath))
        {
            log('Mods folder not found', "WARNING");
            return;
        }

        var searchPaths = [
            "mods/",
            "mods/" + Mods.currentModDirectory + "/scripts/",
            "mods/" + Mods.currentModDirectory + "/custom_events/",
            "mods/" + Mods.currentModDirectory + "/custom_notetypes/",
            "mods/" + Mods.currentModDirectory + "/stages/",
            "mods/" + Mods.currentModDirectory + "/characters/"
        ];

        if (PlayState.SONG != null)
        {
            var songName = Paths.formatToSongPath(PlayState.SONG.song);
            searchPaths.push("mods/" + Mods.currentModDirectory + "/data/" + songName + "/");
        }

        var foundScripts:Array<String> = [];

        for (basePath in searchPaths)
        {
            if (!FileSystem.exists(basePath)) continue;

            function scanDir(dir:String):Void
            {
                if (!FileSystem.exists(dir)) return;
                var files = FileSystem.readDirectory(dir);
                for (file in files)
                {
                    var fullPath = dir + file;
                    if (FileSystem.isDirectory(fullPath))
                        scanDir(fullPath + "/");
                    else if (file.toLowerCase().endsWith(".hx"))
                    {
                        foundScripts.push(fullPath);
                        log('Found Haxe script: $fullPath', "SUCCESS");
                        #if HSCRIPT_ALLOWED
                        testHxScript(fullPath);
                        #end
                    }
                }
            }

            scanDir(basePath);
        }

        log('Total Haxe scripts found: ' + foundScripts.length, "INFO");
    }

    public static function logError(error:Dynamic, stack:Array<StackItem>):Void
    {
        log('=== HAXE SCRIPT ERROR ===', "ERROR");
        log('Error: $error', "ERROR");
        log('Stack trace:', "ERROR");

        for (item in stack)
        {
            log('  $item', "ERROR");
        }

        log('=========================', "ERROR");
    }

    public static function clearLog():Void
    {
        if (!enabled) return;
        var debugDir = "./debug/Haxe/";
        if (FileSystem.exists(debugDir))
        {
            var files = FileSystem.readDirectory(debugDir);
            for (file in files)
            {
                if (file.endsWith(".log"))
                {
                    var filePath = debugDir + file;
                    FileSystem.deleteFile(filePath);
                }
            }
        }
    }
}