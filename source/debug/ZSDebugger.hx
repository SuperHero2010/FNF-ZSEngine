package debug;

import sys.io.File;
import haxe.CallStack;

class ZSDebugger {
    public static var enabled:Bool = true;
    public static var logFile:String = "";
    public static var transpilerLogFile:String = "";

    public static function init():Void {
        if (!enabled) return;

        var date = Date.now();
        var dateStr = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDay() + "_" + date.getHours() + "-" + date.getMinutes() + "-" + date.getSeconds();

        logFile = "./debug/ZS/ZS-debug-" + dateStr + ".log";
        transpilerLogFile = "./debug/ZS/ZS-transpiler-" + dateStr + ".log";

        var header = "=== ZS Debug Log ===\nDate: " + date.toString() + "\n\n";
        File.saveContent(logFile, header);
        File.saveContent(transpilerLogFile, header);
    }

    public static function log(message:String):Void {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var logMessage = "[" + timestamp + "] " + message + "\n";

        try {
            var content = File.getContent(logFile);
            File.saveContent(logFile, content + logMessage);
        } catch(e:Dynamic) {
            File.saveContent(logFile, logMessage);
        }
    }

    public static function logTranspiler(message:String):Void {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var logMessage = "[" + timestamp + "] " + message + "\n";

        try {
            var content = File.getContent(transpilerLogFile);
            File.saveContent(transpilerLogFile, content + logMessage);
        } catch(e:Dynamic) {
            File.saveContent(transpilerLogFile, logMessage);
        }
    }

    public static function logError(message:String, ?stack:CallStack):Void {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var logMessage = "[" + timestamp + "] ERROR: " + message + "\n";

        if (stack != null) {
            logMessage += "Stack trace:\n" + CallStack.toString(stack) + "\n";
        }

        try {
            var content = File.getContent(logFile);
            File.saveContent(logFile, content + logMessage);
        } catch(e:Dynamic) {
            File.saveContent(logFile, logMessage);
        }
    }

    public static function logTranspilerError(message:String, line:Int, content:String):Void {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var logMessage = "[" + timestamp + "] ERROR at line " + line + ": " + message + "\n";
        logMessage += "  Content: \"" + content + "\"\n";

        try {
            var fileContent = File.getContent(transpilerLogFile);
            File.saveContent(transpilerLogFile, fileContent + logMessage);
        } catch(e:Dynamic) {
            File.saveContent(transpilerLogFile, logMessage);
        }
    }

    public static function logTranspilerSuccess(inputPath:String, outputLength:Int):Void {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var logMessage = "[" + timestamp + "] SUCCESS: " + inputPath + " -> " + outputLength + " chars\n";

        try {
            var content = File.getContent(transpilerLogFile);
            File.saveContent(transpilerLogFile, content + logMessage);
        } catch(e:Dynamic) {
            File.saveContent(transpilerLogFile, logMessage);
        }
    }

    public static function close():Void {
        if (!enabled) return;

        var timestamp = Date.now().toString();
        var footer = "\n=== End of Log ===\n";

        try {
            var content = File.getContent(logFile);
            File.saveContent(logFile, content + footer);
        } catch(e:Dynamic) {}

        try {
            var content = File.getContent(transpilerLogFile);
            File.saveContent(transpilerLogFile, content + footer);
        } catch(e:Dynamic) {}
    }

    public static function clearLog():Void
    {
        if (!enabled) return;
        var debugDir = "./debug/ZS/";
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