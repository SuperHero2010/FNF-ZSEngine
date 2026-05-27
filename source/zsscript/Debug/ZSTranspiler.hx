package;

class ZSTranspiler {
    public static var errors:Array<String> = [];
    public static var currentLine:Int = 0;

    public static function transpile(zsSource:String):Null<String> {
        errors = [];
        var luaCode = new StringBuf();
        var lines = zsSource.split("\n");
        var directiveFound = false;
        var directiveLineIndex = -1;

        var libErrors = ZSLibValidator.validate(zsSource);
        if (libErrors.length > 0) {
            errors = libErrors;
            return null;
        }

        for (i in 0...lines.length) {
            var line = trimStr(lines[i]);
            if (line == "" || line.indexOf("-/") == 0) continue;
            if (line == "! ZS-LUA") {
                directiveFound = true;
                directiveLineIndex = i;
                break;
            } else {
                errors.push('Error: File must start with "! ZS-LUA"');
                errors.push('  Found: "$line"');
                return null;
            }
        }

        if (!directiveFound) {
            errors.push('Error: File must start with "! ZS-LUA"');
            return null;
        }

        lines[directiveLineIndex] = "";

        var indentationStack:Array<Int> = [0];
        var lastIndent = 0;
        var inBlockComment = false;
        var i = 0;

        while (i < lines.length) {
            currentLine = i + 1;
            var rawLine = lines[i];
            var originalIndent = getIndentLevel(rawLine);
            var trimmedLine = trimStr(rawLine);
            var skipLine = false;

            if (trimmedLine == "") {
                var nextLine = "";
                for (j in i+1...lines.length) {
                    var nextTrimmed = trimStr(lines[j]);
                    if (nextTrimmed != "") {
                        nextLine = nextTrimmed;
                        break;
                    }
                }
                var isNextFunction = (nextLine != "" && nextLine.charAt(nextLine.length - 1) == ":");
                var isNextPrint = (nextLine.indexOf("print:") == 0 || nextLine.indexOf("print(debug):") == 0);
                if (isNextFunction || isNextPrint) {
                    i++;
                    continue;
                }
                luaCode.add("\n");
                i++;
                continue;
            }

            if (!inBlockComment && trimmedLine.indexOf("*/-") == 0) {
                var closePos = trimmedLine.indexOf("/-*");
                if (closePos > 0) {
                    var content = trimmedLine.substring(3, closePos);
                    var afterClose = trimmedLine.substring(closePos + 3);
                    for (_ in 0...originalIndent) luaCode.add(" ");
                    luaCode.add("--[[" + content + "]]" + afterClose + "\n");
                } else {
                    inBlockComment = true;
                    for (_ in 0...originalIndent) luaCode.add(" ");
                    luaCode.add("--[[" + trimmedLine.substr(3) + "\n");
                }
                lastIndent = originalIndent;
                i++;
                continue;
            }

            if (inBlockComment) {
                var closePos = trimmedLine.indexOf("/-*");
                if (closePos >= 0) {
                    inBlockComment = false;
                    var beforeClose = trimmedLine.substring(0, closePos);
                    var afterClose = trimmedLine.substring(closePos + 3);
                    for (_ in 0...originalIndent) luaCode.add(" ");
                    luaCode.add(beforeClose + "]]" + afterClose + "\n");
                } else {
                    for (_ in 0...originalIndent) luaCode.add(" ");
                    luaCode.add(trimmedLine + "\n");
                }
                lastIndent = originalIndent;
                i++;
                continue;
            }

            if (trimmedLine.indexOf("-/") == 0) {
                for (_ in 0...originalIndent) luaCode.add(" ");
                luaCode.add("--" + trimmedLine.substr(2) + "\n");
                lastIndent = originalIndent;
                i++;
                continue;
            }

            if (trimmedLine.indexOf("import ") == 0) {
                i++;
                continue;
            }

            var inlineComment = "";
            var commentPos = trimmedLine.indexOf(" -/");
            if (commentPos > -1) {
                inlineComment = " --" + trimStr(trimmedLine.substring(commentPos + 3));
                trimmedLine = trimStr(trimmedLine.substring(0, commentPos));
            }

            var isPrintLine = (trimmedLine.indexOf("print:") == 0 || trimmedLine.indexOf("print(debug):") == 0);

            if (!inBlockComment) {
                var codeToCheck = trimmedLine;
                if (codeToCheck.indexOf('"') > -1) {
                    errors.push('Error at line $currentLine: Straight double quotes " are not allowed in ZS');
                    errors.push('  → Use curly quotes “ and ” instead');
                    return null;
                }
                if (codeToCheck.indexOf("'") > -1) {
                    errors.push('Error at line $currentLine: Straight single quotes \' are not allowed in ZS');
                    errors.push('  → Use curly quotes ‘ and ’ instead');
                    return null;
                }
            }

            if (isPrintLine) {
                trimmedLine = trimmedLine.split("+").join("..");
            }

            var colonPos = trimmedLine.indexOf(":");
            var isLibraryCall = false;
            var isEventDef = false;

            if (colonPos > 0) {
                var beforeColon = trimStr(trimmedLine.substring(0, colonPos));
                var afterColon = trimStr(trimmedLine.substring(colonPos + 1));

                if (afterColon == "") {
                    if (beforeColon.indexOf("<") > -1) {
                        var eventName = beforeColon.split("<")[0];
                        var param = beforeColon.substring(beforeColon.indexOf("<") + 1, beforeColon.indexOf(">"));
                        trimmedLine = "function " + eventName + "(" + param + ")";
                    } else {
                        trimmedLine = "function " + beforeColon + "()";
                    }
                }
                else if (beforeColon == "print" || beforeColon == "print(debug)") {
                    isPrintLine = true;
                }
                else if (afterColon.indexOf("(") > -1 || afterColon.indexOf("<") > -1) {
                    var spaceIdx = afterColon.indexOf(" ");
                    if (spaceIdx > 0) {
                        var funcName = afterColon.substring(0, spaceIdx);
                        var args = afterColon.substring(funcName.length + 1);
                        trimmedLine = beforeColon + "." + funcName + "(" + args + ")";
                    } else {
                        trimmedLine = beforeColon + "." + afterColon;
                    }
                }
                else {
                    var spaceIdx = afterColon.indexOf(" ");
                    if (spaceIdx > 0) {
                        var firstWord = afterColon.substring(0, spaceIdx);
                        var rest = afterColon.substring(firstWord.length + 1);

                        var hasOperator = (rest.indexOf("×") > -1 || rest.indexOf("÷") > -1 || 
                                        rest.indexOf("+") > -1 || rest.indexOf("-") > -1 ||
                                        rest.indexOf("*") > -1 || rest.indexOf("/") > -1);

                        if (hasOperator) {
                            trimmedLine = beforeColon + "." + afterColon;
                        } else {
                            trimmedLine = beforeColon + "." + firstWord + "(" + rest + ")";
                        }
                    } else {
                        trimmedLine = beforeColon + "." + afterColon;
                    }
                }
            }

            if (isEventDef) {
                var beforeColon = trimStr(trimmedLine.substring(0, trimmedLine.indexOf(":")));
                var paramPattern = ~/<([^>]+)>/g;
                if (paramPattern.match(beforeColon)) {
                    var eventName = beforeColon.split("<")[0];
                    var param = paramPattern.matched(1);
                    trimmedLine = "function " + eventName + "(" + param + ")";
                } else {
                    trimmedLine = "function " + beforeColon + "()";
                }
            }

            if (!isEventDef && !isLibraryCall) {
                var funcCallPattern = ~/([a-zA-Z_][a-zA-Z0-9_]*)<([^>]+)>/g;
                trimmedLine = funcCallPattern.replace(trimmedLine, "$1($2)");
                trimmedLine = ~/([a-zA-Z_][a-zA-Z0-9_]*)<>/g.replace(trimmedLine, "$1()");
            }

            trimmedLine = convertQuotes(trimmedLine);
            trimmedLine = fixMinusSigns(trimmedLine);

            var luaLine = trimmedLine;
            for (pattern in ZSPatterns.patterns) {
                var regex = new EReg(pattern.pattern, "g");
                luaLine = regex.replace(luaLine, pattern.replacement);
            }

            luaLine = luaLine.split("≠").join("~=");
            luaLine = luaLine.split("≤").join("<=");
            luaLine = luaLine.split("≥").join(">=");
            luaLine = luaLine.split("−=").join("-=");
            luaLine = luaLine.split("×=").join("*=");
            luaLine = luaLine.split("÷=").join("/=");
            luaLine = luaLine.split("×").join("*");
            luaLine = luaLine.split("÷").join("/");
            luaLine = luaLine.split("−").join("-");

            if (luaLine.indexOf("else if ") == 0) {
                luaLine = "elseif " + luaLine.substr(8);
            }

            if (originalIndent <= lastIndent && trimmedLine != "" && !isBlockStarter(trimmedLine)) {
                while (indentationStack.length > 1 && originalIndent <= indentationStack[indentationStack.length - 1]) {
                    var blockIndent = indentationStack[indentationStack.length - 1];
                    for (_ in 0...blockIndent) luaCode.add(" ");
                    luaCode.add("end\n");
                    indentationStack.pop();
                    skipLine = true;
                }
            }

            if (skipLine) continue;

            if (originalIndent == 0 && (luaLine.indexOf("function ") == 0)) {
                while (indentationStack.length > 1) {
                    var blockIndent = indentationStack[indentationStack.length - 1];
                    for (_ in 0...blockIndent) luaCode.add(" ");
                    luaCode.add("end\n");
                    indentationStack.pop();
                }
                luaCode.add("\n");
                indentationStack = [0];
                lastIndent = 0;
            }

            for (_ in 0...originalIndent) luaCode.add(" ");
            luaCode.add(luaLine + inlineComment + "\n");

            if (luaLine.indexOf("function ") == 0 || 
                luaLine.indexOf(" then") > -1 || 
                luaLine.indexOf(" do") > -1 || 
                luaLine == "repeat" || 
                luaLine.indexOf("else") == 0) {
                indentationStack.push(originalIndent);
            }

            lastIndent = originalIndent;
            i++;
        }

        while (indentationStack.length > 1) {
            var blockIndent = indentationStack[indentationStack.length - 1];
            for (_ in 0...blockIndent) luaCode.add(" ");
            luaCode.add("end\n");
            indentationStack.pop();
        }

        return luaCode.toString();
    }

    static function getIndentLevel(line:String):Int {
        var spaces = 0;
        for (i in 0...line.length) {
            var c = line.charAt(i);
            if (c == ' ' || c == '\t') spaces++;
            else break;
        }
        return spaces;
    }

    static function fixMinusSigns(line:String):String {
        var subRegex = ~/([0-9>][^ ]*) *- *([0-9<][^ ]*)/g;
        line = subRegex.replace(line, "$1 − $2");
        var subNoSpace = ~/([0-9>][^ ]*)-([0-9<][^ ]*)/g;
        line = subNoSpace.replace(line, "$1 − $2");
        var negRegex = ~/(^|[=\(\{,;+*\/÷−]) *- *([0-9<][^ ]*)/g;
        line = negRegex.replace(line, "$1 -$2");
        return line;
    }

    static function convertQuotes(line:String):String {
        var result = "";
        for (i in 0...line.length) {
            var c = line.charAt(i);
            if (c == "“" || c == "”") result += '"';
            else if (c == "‘" || c == "’") result += "'";
            else result += c;
        }
        return result;
    }

    static function isBlockStarter(line:String):Bool {
        var l = trimStr(line);
        if (l.charAt(l.length - 1) == ":") return true;
        if (l.indexOf("if ") == 0 && (l.charAt(l.length - 1) == ":" || l.indexOf(" then") > -1)) return true;
        if (l.indexOf("else if ") == 0 && (l.charAt(l.length - 1) == ":" || l.indexOf(" then") > -1)) return true;
        if (l == "else" || l == "else:") return true;
        if (l.indexOf("for ") == 0 && (l.charAt(l.length - 1) == ":" || l.indexOf(" do") > -1)) return true;
        if (l.indexOf("while ") == 0 && (l.charAt(l.length - 1) == ":" || l.indexOf(" do") > -1)) return true;
        return false;
    }

    static function trimStr(s:String):String {
        var start = 0;
        var end = s.length - 1;
        while (start <= end && (s.charAt(start) == ' ' || s.charAt(start) == '\t' || s.charAt(start) == '\r' || s.charAt(start) == '\n')) start++;
        while (end >= start && (s.charAt(end) == ' ' || s.charAt(end) == '\t' || s.charAt(end) == '\r' || s.charAt(end) == '\n')) end--;
        return s.substring(start, end + 1);
    }
}