package debug;

import haxe.CallStack;
import sys.io.File;
import sys.FileSystem;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

class LuaDebugger
{
    public static var enabled:Bool = true;
    public static var logToFile:Bool = true;
    public static var logPath:String = "";
    public static var verbose:Bool = true;

    static inline var RESET = "\x1b[0m";
    static inline var RED = "\x1b[31m";
    static inline var GREEN = "\x1b[32m";
    static inline var YELLOW = "\x1b[33m";
    static inline var BLUE = "\x1b[34m";
    static inline var MAGENTA = "\x1b[35m";
    static inline var CYAN = "\x1b[36m";

    static function getLogPath():String
    {
        if (logPath == "")
        {
            var date = Date.now();
            var dateStr = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + "_" + date.getHours() + "-" + date.getMinutes() + "-" + date.getSeconds();
            logPath = "./debug/Lua/Lua-debug-" + dateStr + ".log";
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
            case "LUA": MAGENTA;
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

    public static function logLua(scriptPath:String, message:String, ?level:String = "LUA"):Void
    {
        log('[$scriptPath] $message', level);
    }

    #if LUA_ALLOWED
    public static function enableDebugMode(funk:FunkinLua):Void
    {
        try
        {
            funk.set("luaDebugMode", true);
            funk.set("luaDeprecatedWarnings", true);

            var luaState = funk.lua;

            var logFile = getLogPath();
            var scriptPath = funk.scriptName;

            var luaCode = '
                local oldDebugPrint = debugPrint
                debugPrint = function(...)
                    local args = {...}
                    local msg = table.concat(args, " ")
                    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
                    local f = debug.getinfo(2, "S").source or "' + scriptPath + '"

                    local logFile = io.open("' + logFile + '", "a")
                    if logFile then
                        logFile:write("[" .. timestamp .. "] [" .. f .. "] " .. msg .. "\\n")
                        logFile:flush()
                        logFile:close()
                    end

                    oldDebugPrint(...)
                end
            ';

            if (LuaL.dostring(luaState, luaCode) != 0)
            {
                var err = Lua.tostring(luaState, -1);
                Lua.pop(luaState, 1);
                logLua(scriptPath, 'Failed to override debugPrint: $err', "ERROR");
            }
            else
            {
                logLua(scriptPath, "Debug mode enabled and print capture installed", "SUCCESS");
            }
        }
        catch(e:Dynamic)
        {
            logLua(funk.scriptName, 'Failed to enable debug mode: $e', "ERROR");
        }
    }
    #end

    public static function checkLuaFile(path:String):Bool
    {
        if (!FileSystem.exists(path))
        {
            log('Lua file not found: $path', "ERROR");
            return false;
        }

        var content = File.getContent(path);
        var lineCount = content.split("\n").length;
        log('Lua file found: $path ($lineCount lines)', "SUCCESS");
        return true;
    }

    #if LUA_ALLOWED
    public static function testLuaScript(scriptPath:String):Void
    {
        log('Testing Lua script: $scriptPath', "INFO");

        if (!checkLuaFile(scriptPath)) return;

        try {
            var funk = new FunkinLua(scriptPath);
            enableDebugMode(funk);
            log('Lua script compiled successfully: $scriptPath', "SUCCESS");
        } catch(e:Dynamic) {
            log('Lua compilation failed: $scriptPath - $e', "ERROR");
        }
    }
    #end

    public static function scanModsForLua():Void
    {
        log('Scanning mods for Lua scripts...', "INFO");

        var modsPath = "mods/";
        if (!FileSystem.exists(modsPath))
        {
            log('Mods folder not found', "WARNING");
            return;
        }

        var mods = FileSystem.readDirectory(modsPath);
        var foundScripts:Array<String> = [];

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
                    else if (file.toLowerCase().endsWith(".lua"))
                    {
                        foundScripts.push(fullPath);
                        log('Found Lua script: $fullPath', "SUCCESS");
                        #if LUA_ALLOWED
                        testLuaScript(fullPath);
                        #end
                    }
                }
            }

            scanDir(basePath);
        }

        log('Total Lua scripts found: ' + foundScripts.length, "INFO");
    }

    public static function watchLuaCalls(scriptPath:String, functionName:String, args:Array<Dynamic>):Void
    {
        if (!enabled) return;

        var argsStr = "";
        if (args != null)
        {
            var strArgs = [];
            for (arg in args)
                strArgs.push(Std.string(arg));
            argsStr = strArgs.join(", ");
        }

        log('Calling $functionName($argsStr) in $scriptPath', "LUA");
    }

    public static function logError(error:Dynamic, stack:Array<StackItem>):Void
    {
        log('=== LUA ERROR ===', "ERROR");
        log('Error: $error', "ERROR");
        log('Stack trace:', "ERROR");

        for (item in stack)
        {
            log('  $item', "ERROR");
        }

        log('================', "ERROR");
    }

    public static function clearLog():Void
    {
        if (!enabled) return;
        var debugDir = "./debug/Lua/";
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