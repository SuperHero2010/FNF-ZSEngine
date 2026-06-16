package;

import haxe.ds.Map;

class ZSLibValidator {
    public static var errors:Array<String> = [];

    public static var builtinLibs:Array<String> = [
        "math", "string", "table", "io", "os", "debug", "coroutine", "package"
    ];

    static function trimStr(s:String):String {
        var start = 0;
        var end = s.length - 1;
        while (start <= end && (s.charAt(start) == ' ' || s.charAt(start) == '\t' || s.charAt(start) == '\r' || s.charAt(start) == '\n')) start++;
        while (end >= start && (s.charAt(end) == ' ' || s.charAt(end) == '\t' || s.charAt(end) == '\r' || s.charAt(end) == '\n')) end--;
        return s.substring(start, end + 1);
    }

    public static function getLibMap(source:String):Map<String, String> {
        var libMap:Map<String, String> = new Map();
        var lines = source.split("\n");
        var inBlockComment = false;

        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmed = trimStr(line);

            if (trimmed.indexOf("*/-") == 0) {
                inBlockComment = true;
                continue;
            }
            if (inBlockComment) {
                if (trimmed.indexOf("/-*") >= 0) {
                    inBlockComment = false;
                }
                continue;
            }

            if (trimmed == "" || trimmed.indexOf("-/") == 0) continue;

            if (trimmed.indexOf("import ") == 0) {
                var rest = trimStr(trimmed.substr(7));
                var libName = "";
                var alias = "";

                if (rest.indexOf(" as ") > -1) {
                    var parts = rest.split(" as ");
                    libName = trimStr(parts[0]);
                    alias = trimStr(parts[1]);
                } else {
                    libName = rest;
                    alias = rest;
                }

                libMap.set(alias, libName);
            }
        }

        return libMap;
    }

    public static function validate(source:String):Array<String> {
        errors = [];
        var lines = source.split("\n");
        var inBlockComment = false;

        var libMap:Map<String, String> = new Map();
        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmed = trimStr(line);

            trace('First pass line ${i+1}: trimmed="$trimmed"');

            if (trimmed.indexOf("*/-") == 0) {
                inBlockComment = true;
                continue;
            }
            if (inBlockComment) {
                if (trimmed.indexOf("/-*") >= 0) {
                    inBlockComment = false;
                }
                continue;
            }

            if (trimmed == "" || trimmed.indexOf("-/") == 0) continue;

            if (trimmed.indexOf("import ") == 0) {
                trace('  Found import at line ${i+1}: "$trimmed"');
                var rest = trimStr(trimmed.substr(7));
                var libName = "";
                var alias = "";

                if (rest.indexOf(" as ") > -1) {
                    var parts = rest.split(" as ");
                    libName = trimStr(parts[0]);
                    alias = trimStr(parts[1]);
                } else {
                    libName = rest;
                    alias = rest;
                }

                libMap.set(alias, libName);
                trace('Import collected: alias="$alias" -> libName="$libName"');
            }
        }

        inBlockComment = false;
        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmed = trimStr(line);

            if (trimmed.indexOf("*/-") == 0) {
                inBlockComment = true;
                continue;
            }
            if (inBlockComment) {
                if (trimmed.indexOf("/-*") >= 0) {
                    inBlockComment = false;
                }
                continue;
            }

            if (trimmed == "" || trimmed.indexOf("-/") == 0) continue;

            if (trimmed.indexOf("import ") == 0) continue;

            var colonPos = trimmed.indexOf(":");
            if (colonPos > 0) {
                var beforeColon = trimmed.substring(0, colonPos);
                var libName = beforeColon.split("<")[0];
                libName = libName.split(" ")[0];
                libName = trimStr(libName);

                var afterColon = trimStr(trimmed.substring(colonPos + 1));

                if (afterColon == "") {
                    continue;
                }

                var trimmedLine = trimStr(line);
                var isZSKeyword = false;

                var zsKeywords = ["change", "read", "print", "register", "apply", "import", "local", "global"];
                for (kw in zsKeywords) {
                    if (trimmedLine.indexOf(kw + " ") == 0 || trimmedLine.indexOf(kw + "<") == 0 || trimmedLine.indexOf(kw + ":") == 0 || trimmedLine == kw) {
                        isZSKeyword = true;
                        break;
                    }
                }

                if (isZSKeyword) {
                    continue;
                }

                if (!libMap.exists(libName) && !builtinLibs.contains(libName)) {
                    errors.push('Error at line ${i+1}: Unknown library "$libName". Did you forget to import it?');
                }
            }
        }

        return errors;
    }
}