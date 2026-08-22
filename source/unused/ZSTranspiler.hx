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

        for (i in 0...lines.length) {
            var line = StringTools.trim(lines[i]);
            if (line == "" || line.startsWith("-/")) continue;

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

        for (i in 0...lines.length) {
            currentLine = i + 1;
            var rawLine = lines[i];
            var originalIndent = getIndentLevel(rawLine);
            var trimmedLine = StringTools.trim(rawLine);

            trimmedLine = convertQuotes(trimmedLine);
            trimmedLine = fixMinusSigns(trimmedLine);

            trimmedLine = trimmedLine.split("!=").join("~=");
            trimmedLine = trimmedLine.split("−=").join("-=");
            trimmedLine = trimmedLine.split("×=").join("*=");
            trimmedLine = trimmedLine.split("÷=").join("/=");

            if (!inBlockComment)
            {
                if (trimmedLine.indexOf("~=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "~=" is not allowed in ZS');
                    errors.push('  → Use "!=" instead');
                    errors.push('  Found: "$trimmedLine"');
                    return null;
                }
                if (trimmedLine.indexOf("-=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "-=" is not allowed in ZS');
                    errors.push('  → Use "−=" instead');
                    errors.push('  Found: "$trimmedLine"');
                    return null;
                }
                if (trimmedLine.indexOf("*=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "*=" is not allowed in ZS');
                    errors.push('  → Use "×=" instead');
                    errors.push('  Found: "$trimmedLine"');
                    return null;
                }
                if (trimmedLine.indexOf("/=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "/=" is not allowed in ZS');
                    errors.push('  → Use "÷=" instead');
                    errors.push('  Found: "$trimmedLine"');
                    return null;
                }
            }

            if (originalIndent < lastIndent) {
                var levelsToClose = 0;
                while (originalIndent < indentationStack[indentationStack.length - 1]) {
                    indentationStack.pop();
                    levelsToClose++;
                }
                for (_ in 0...levelsToClose) {
                    luaCode.add("end\n");
                }
            }

            if (trimmedLine.indexOf("-/") == 0) {
                for (_ in 0...originalIndent) {
                    luaCode.add(" ");
                }
                luaCode.add("--" + trimmedLine.substr(2) + "\n");
                lastIndent = originalIndent;
                continue;
            }

            if (trimmedLine.indexOf(" -/") > -1) {
                var parts = trimmedLine.split(" -/");
                var codePart = parts[0];
                var commentPart = parts[1];

                var match = ZSPatterns.matchPattern(codePart);
                if (match != null) {
                    var luaLine = ZSPatterns.applyPattern(match.pattern, match.args);
                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }
                    luaCode.add(luaLine + " --" + commentPart + "\n");
                } else {
                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }
                    luaCode.add(codePart + " --" + commentPart + "\n");
                }
                lastIndent = originalIndent;
                continue;
            }

            trace('Line $currentLine: raw="$rawLine", trimmed="$trimmedLine", indent=$originalIndent');

            if (!inBlockComment && trimmedLine.indexOf("*/-") == 0) {
                var closePos = trimmedLine.indexOf("/-*");
                if (closePos > 0) {
                    var content = trimmedLine.substring(3, closePos);
                    var afterClose = trimmedLine.substring(closePos + 3);
                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }
                    luaCode.add("--[[" + content + "]]" + afterClose + "\n");
                } else {
                    inBlockComment = true;
                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }
                    luaCode.add("--[[" + trimmedLine.substr(3) + "\n");
                }
                lastIndent = originalIndent;
                continue;
            }

            if (inBlockComment) {
                var closePos = trimmedLine.indexOf("/-*");
                if (closePos >= 0) {
                    inBlockComment = false;
                    var beforeClose = trimmedLine.substring(0, closePos);
                    var afterClose = trimmedLine.substring(closePos + 3);
                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }
                    luaCode.add(beforeClose + "]]" + afterClose + "\n");
                } else {
                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }
                    luaCode.add(trimmedLine + "\n");
                }
                lastIndent = originalIndent;
                continue;
            }

            if (trimmedLine == "" || trimmedLine == null) {
                for (_ in 0...originalIndent) {
                    luaCode.add(" ");
                }
                luaCode.add("\n");
                lastIndent = originalIndent;
                continue;
            }

            if (trimmedLine.indexOf("else if ") == 0) {
                trimmedLine = "elseif " + trimmedLine.substr(8);
            }

            if (trimmedLine.indexOf("return") == 0 || trimmedLine.indexOf(" return ") > -1) {
                errors.push('Error at line $currentLine: "return" keyword is not allowed in ZS. Use "proceed" or "halt" instead');
                errors.push('  → $trimmedLine');
                return null;
            }

            if (trimmedLine.indexOf("function ") == 0) {
                errors.push('Error at line $currentLine: "function" keyword is not allowed in ZS');
                errors.push('  → Use "onCreate:" or "onUpdate<elapsed>:" instead');
                errors.push('  Found: "$trimmedLine"');
                return null;
            }

            if (trimmedLine == "end" || trimmedLine.indexOf(" end ") > -1 || trimmedLine.indexOf("\tend") > -1) {
                errors.push('Error at line $currentLine: "end" keyword is not allowed in ZS');
                errors.push('  → ZS uses indentation instead of "end"');
                errors.push('  Found: "$trimmedLine"');
                return null;
            }

            if (trimmedLine.indexOf("--") == 0 || trimmedLine.indexOf(" -- ") > -1) {
                errors.push('Error at line $currentLine: Lua comments "--" are not allowed in ZS');
                errors.push('  → Use "-/" for comments');
                errors.push('  Found: "$trimmedLine"');
                return null;
            }

            var match = ZSPatterns.matchPattern(trimmedLine);
            if (match != null) {
                try {
                    var luaLine = ZSPatterns.applyPattern(match.pattern, match.args);

                    for (_ in 0...originalIndent) {
                        luaCode.add(" ");
                    }

                    var isReturnFreeKeyword = (match.pattern.category == "control" && (match.pattern.zs == "proceed" || match.pattern.zs == "halt" || match.pattern.zs == "haltLua" || match.pattern.zs == "haltScript" || match.pattern.zs == "haltAll"));

                    if (!isReturnFreeKeyword) {
                        var shouldPush = false;
                        if (luaLine.indexOf("function ") == 0) {
                            shouldPush = true;
                        }
                        else if (luaLine.indexOf(" then") > -1) {
                            shouldPush = true;
                        }
                        else if (luaLine.indexOf(" do") > -1) {
                            shouldPush = true;
                        }
                        else if (luaLine == "repeat") {
                            shouldPush = true;
                        }
                        else if (luaLine.indexOf("else") == 0) {
                            shouldPush = true;
                        }

                        if (shouldPush) {
                            indentationStack.push(originalIndent);
                        }
                    }

                    luaCode.add(luaLine + "\n");
                } catch(e:Dynamic) {
                    errors.push('Error at line $currentLine: Failed to apply pattern');
                    errors.push('  → $trimmedLine');
                    return null;
                }
            } else {
                errors.push('Error at line $currentLine: Unrecognized ZS syntax');
                errors.push('  → "$trimmedLine"');
                errors.push('  This line was not converted. Use proper ZS syntax.');
                return null;
            }

            lastIndent = originalIndent;
        }

        while (indentationStack.length > 1) {
            luaCode.add("end\n");
            indentationStack.pop();
        }

        return luaCode.toString();
    }

    static function getIndentLevel(line:String):Int {
        var spaces = 0;
        for (i in 0...line.length) {
            var char = line.charAt(i);
            if (char == " " || char == "\t") {
                spaces++;
            } else {
                break;
            }
        }
        return spaces;
    }

    static function fixMinusSigns(line:String):String {
        var subtractionRegex = ~/([0-9\)\]\} ]) *- *([0-9\(\[\{])/g;
        line = subtractionRegex.replace(line, "$1 − $2");
        var negativeRegex = ~/(^|[=\(\{,;+*\/÷−]) *- *([0-9])/g;
        line = negativeRegex.replace(line, "$1 -$2");

        return line;
    }

    static function convertQuotes(line:String):String {
        var result = "";
        var inString = false;

        for (i in 0...line.length) {
            var char = line.charAt(i);

            if (char == "“" || char == "”") {
                result += '"';
            }
            else if (char == "‘" || char == "’") {
                result += "'";
            }
            else {
                result += char;
            }
        }

        return result;
    }
}