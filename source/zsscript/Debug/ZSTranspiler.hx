package;

import ZSPatternGenerator.Pattern;

class ZSTranspiler {
    public static var errors:Array<String> = [];
    public static var currentLine:Int = 0;
    public static var log:Array<String> = [];
    public static var userDefinedFunctions:Array<String> = [];
    public static var nounExceptions:Array<String> = [
        "luaDebugMode",
        "luaDeprecatedWarnings",
        "scriptName",
        "modFolder",
        "currentModDirectory",

        "version",
        "buildTarget",

        "Function_StopLua",
        "Function_StopHScript",
        "Function_StopAll",
        "Function_Stop",
        "Function_Continue",

        "screenWidth",
        "screenHeight",

        "songName",
        "songPath",
        "loadedSongName",
        "loadedSongPath",
        "bpm",
        "songLength",
        "startedCountdown",
        "seenCutscene",
        "inGameOver",

        "chartPath",
        "curStage",
        "scrollSpeed",
        "hasVocals",

        "difficulty",
        "difficultyName",
        "difficultyPath",
        "difficultyNameTranslation",

        "isStoryMode",
        "weekRaw",
        "week",

        "curBpm",
        "curSection",
        "curBeat",
        "curStep",
        "curDecBeat",
        "curDecStep",
        "crochet",
        "stepCrochet",
        "mustHitSection",
        "altAnim",
        "gfSection",

        "score",
        "misses",
        "hits",
        "combo",
        "deaths",
        "rating",
        "ratingName",
        "ratingFC",
        "totalPlayed",
        "totalNotesHit",

        "playbackRate",
        "healthGainMult",
        "healthLossMult",
        "instakillOnMiss",
        "practice",
        "botPlay",

        "defaultPlayerStrumX0",
        "defaultPlayerStrumY0",
        "defaultPlayerStrumX1",
        "defaultPlayerStrumY1",
        "defaultPlayerStrumX2",
        "defaultPlayerStrumY2",
        "defaultPlayerStrumX3",
        "defaultPlayerStrumY3",
        "defaultOpponentStrumX0",
        "defaultOpponentStrumY0",
        "defaultOpponentStrumX1",
        "defaultOpponentStrumY1",
        "defaultOpponentStrumX2",
        "defaultOpponentStrumY2",
        "defaultOpponentStrumX3",
        "defaultOpponentStrumY3",

        "defaultBoyfriendX",
        "defaultBoyfriendY",
        "defaultOpponentX",
        "defaultOpponentY",
        "defaultGirlfriendX",
        "defaultGirlfriendY",
        "boyfriendName",
        "dadName",
        "gfName",

        "downscroll",
        "middlescroll",
        "framerate",
        "ghostTapping",
        "hideHud",
        "timeBarType",
        "scoreZoom",
        "cameraZoomOnBeat",
        "flashingLights",
        "noteOffset",
        "healthBarAlpha",
        "noResetButton",
        "lowQuality",
        "shadersEnabled",
        "guitarHeroSustains",
        "noteSkin",
        "splashSkin",
        "splashAlpha",
        "noteSkinPostfix",
        "splashSkinPostfix"
    ];

    public static function extractUserDefinedFunctions(zsSource:String):Array<String> {
        var functions = [];
        var lines = zsSource.split("\n");

        for (line in lines) {
            var trimmed = trimStr(line);
            if (trimmed.indexOf("<") > -1 && trimmed.charAt(trimmed.length - 1) == ":") {
                var colonPos = trimmed.indexOf(":");
                var beforeColon = trimmed.substring(0, colonPos);
                var funcName = beforeColon.split("<")[0];
                if (funcName.length > 0 && !functions.contains(funcName)) {
                    functions.push(funcName);
                }
            }
        }

        return functions;
    }

    public static function extractKeywordsFromPatterns():Array<String> {
        var keywords = ["local", "global", "if", "then", "else", "not", "and", "or", "nothing", "give", "back"];
        var allPatterns = ZSPatterns.getPatterns();

        for (pattern in allPatterns) {
            var patternStr = pattern.pattern;
            var replacementStr = pattern.replacement;

            if (patternStr.indexOf("^") == 0) {
                var spacePos = patternStr.indexOf(" ");
                if (spacePos > 0) {
                    var keyword = patternStr.substring(1, spacePos);
                    if (keyword.length > 0 && !keywords.contains(keyword) && keyword != "nil" && keyword != "return" && keyword != "elseif" && keyword != "function") {
                        keywords.push(keyword);
                    }
                }
            }

            var parenPos = replacementStr.indexOf("(");
            if (parenPos > 0) {
                var funcName = replacementStr.substring(0, parenPos);
                if (funcName.length > 0 && !keywords.contains(funcName) && funcName != "nil" && funcName != "return" && funcName != "elseif" && funcName != "function") {
                    keywords.push(funcName);
                }
            }

            var literalWords = patternStr.split(" ");
            for (word in literalWords) {
                var cleanWord = word;
                if (cleanWord.indexOf("^") == 0) cleanWord = cleanWord.substring(1);
                if (cleanWord.indexOf("(") == 0) cleanWord = cleanWord.substring(1);
                if (cleanWord.indexOf(")") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf(")"));
                if (cleanWord.indexOf("?") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf("?"));
                if (cleanWord.indexOf("$") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf("$"));
                if (cleanWord.indexOf("[") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf("["));
                if (cleanWord.indexOf("+") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf("+"));
                if (cleanWord.indexOf("*") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf("{"));
                if (cleanWord.indexOf(".") > -1) cleanWord = cleanWord.substring(0, cleanWord.indexOf("."));

                cleanWord = trimStr(cleanWord);

                if (cleanWord.length > 0 && !keywords.contains(cleanWord) && cleanWord != "nil" && cleanWord != "return" && cleanWord != "elseif" && cleanWord != "function" && cleanWord != "^" && cleanWord != "$" && cleanWord != "?" && cleanWord != "+" && cleanWord != "*") {
                    keywords.push(cleanWord);
                }
            }
        }

        return keywords;
    }

    public static function validateNouns(zsSource:String):Array<String> {
        var validationErrors:Array<String> = [];
        var lines = zsSource.split("\n");

        var validKeywords = extractKeywordsFromPatterns();

        for (i in 0...lines.length) {
            var line = trimStr(lines[i]);
            if (line == "" || line.indexOf("-/") == 0) continue;
            if (line == "! ZS-LUA") continue;

            if (line.indexOf("*/-") == 0 || line.indexOf("/-*") >= 0) continue;

            if (line.charAt(line.length - 1) == ":") continue;

            if (line.indexOf(" -/") > -1) {
                line = trimStr(line.substring(0, line.indexOf(" -/")));
            }

            var words = line.split(" ");
            for (j in 0...words.length) {
                var word = words[j];
                var cleanWord = trimStr(word);

                var wordToCheck = cleanWord;
                var lastChar = wordToCheck.charAt(wordToCheck.length - 1);
                if (lastChar == ":" || lastChar == "," || lastChar == "." || lastChar == ";" || lastChar == "(" || lastChar == ")") {
                    wordToCheck = wordToCheck.substring(0, wordToCheck.length - 1);
                }

                if (wordToCheck == "" || wordToCheck.indexOf("<") >= 0 || wordToCheck.indexOf(">") >= 0) continue;

                if (validKeywords.contains(wordToCheck)) continue;

                if (nounExceptions.contains(wordToCheck)) continue;
                var isNumber = true;
                for (k in 0...wordToCheck.length) {
                    var c = wordToCheck.charAt(k);
                    if (!((c >= '0' && c <= '9') || c == '.' || c == '-')) {
                        isNumber = false;
                        break;
                    }
                }
                if (isNumber && wordToCheck.length > 0) continue;

                if (wordToCheck.indexOf("'") >= 0 || wordToCheck.indexOf('"') >= 0 || wordToCheck.indexOf("“") >= 0 || wordToCheck.indexOf("”") >= 0 || wordToCheck.indexOf("‘") >= 0 || wordToCheck.indexOf("’") >= 0) continue;

                if (wordToCheck == "true" || wordToCheck == "false") continue;

                if (wordToCheck == "+" || wordToCheck == "-" || wordToCheck == "×" || wordToCheck == "÷" ||
                    wordToCheck == "−" || wordToCheck == "=" || wordToCheck == "≠" || wordToCheck == "≤" ||
                    wordToCheck == "≥" || wordToCheck == "<" || wordToCheck == ">") continue;

                var isNounCandidate = false;
                if (wordToCheck.length > 0) {
                    var firstChar = wordToCheck.charAt(0);
                    if ((firstChar >= 'a' && firstChar <= 'z') || (firstChar >= 'A' && firstChar <= 'Z') || firstChar == '_') {
                        isNounCandidate = true;
                        for (k in 0...wordToCheck.length) {
                            var c = wordToCheck.charAt(k);
                            if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_')) {
                                isNounCandidate = false;
                                break;
                            }
                        }
                    }
                }

                if (isNounCandidate) {
                    var isFunctionCall = false;

                    if (j + 1 < words.length) {
                        var nextWord = trimStr(words[j + 1]);
                        if (nextWord.charAt(0) == '<' || nextWord == "read" || nextWord == "with" || nextWord == "to" || nextWord == "for") {
                            isFunctionCall = true;
                        }
                    }

                    if (!isFunctionCall && j > 0) {
                        var prevWord = trimStr(words[j - 1]);
                        if (prevWord == "change" || prevWord == "call" || prevWord == "to" || prevWord == "with" || prevWord == "for") {
                            isFunctionCall = true;
                        }
                    }

                    if (isFunctionCall) continue;

                    validationErrors.push('Error at line ${i + 1}: Noun "$wordToCheck" missing <> wrapper');
                    validationErrors.push('  → Use "<$wordToCheck>" instead');
                }
            }
        }

        return validationErrors;
    }

    public static function transpile(zsSource:String):Null<String> {
        errors = [];
        log = [];
        userDefinedFunctions = extractUserDefinedFunctions(zsSource);
        var luaCode = new StringBuf();
        var lines = zsSource.split("\n");
        var directiveFound = false;
        var directiveLineIndex = -1;

        var libErrors = ZSLibValidator.validate(zsSource);
        if (libErrors.length > 0) {
            errors = libErrors;
            return null;
        }

        var nounErrors = validateNouns(zsSource);
        if (nounErrors.length > 0) {
            errors = nounErrors;
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
        var blockTypeStack:Array<String> = [];
        var lastIndent = 0;
        var inBlockComment = false;
        var inString:Bool = false;
        var stringChar:String = "";
        var i = 0;

        while (i < lines.length) {
            currentLine = i + 1;
            var rawLine = lines[i];
            var originalIndent = getIndentLevel(rawLine);
            var trimmedLine = trimStr(rawLine);
            var skipLine = false;

            trace('LINE $currentLine: raw="$rawLine", indent=$originalIndent');

            var valErrors = ZSParenthesisValidator.validateLine(rawLine, currentLine);
            if (valErrors.length > 0) {
                ZSTranspiler.errors = valErrors;
                return null;
            }

            var pendingNewline = false;
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
                pendingNewline = true;
                i++;
                continue;
            }

            if (!inBlockComment && trimmedLine.indexOf("*/-") == 0) {
                var closePos = trimmedLine.indexOf("/-*");
                if (closePos > 0) {
                    var content = trimmedLine.substring(3, closePos);
                    var afterClose = trimmedLine.substring(closePos + 3);
                    for (_ in 0...originalIndent) {
                        trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                    luaCode.add("--[[" + content + "]]" + afterClose + "\n");
                } else {
                    inBlockComment = true;
                    for (_ in 0...originalIndent) {
                        trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
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
                    for (_ in 0...originalIndent) {
                        trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                    luaCode.add(beforeClose + "]]" + afterClose + "\n");
                } else {
                    for (_ in 0...originalIndent) {
                        trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                    luaCode.add(trimmedLine + "\n");
                }
                lastIndent = originalIndent;
                i++;
                continue;
            }

            if (trimmedLine.indexOf("-/") == 0) {
                for (_ in 0...originalIndent) {
                    trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                    luaCode.add(" ");
                }
                trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                luaCode.add("--" + trimmedLine.substr(2) + "\n");
                lastIndent = originalIndent;
                i++;
                continue;
            }

            if (trimmedLine.indexOf("import ") == 0) {
                var rest = trimStr(trimmedLine.substr(7));
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

                var builtinLibs = ["math", "string", "table", "io", "os", "debug", "coroutine", "package"];
                if (builtinLibs.contains(libName)) {
                    if (alias == libName) {
                        i++;
                        continue;
                    } else {
                        for (_ in 0...originalIndent) {
                            trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                            luaCode.add(" ");
                        }
                        trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                        luaCode.add("local " + alias + " = " + libName + "\n");
                        i++;
                        continue;
                    }
                } else {
                    for (_ in 0...originalIndent) {
                        trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "' + trimmedLine + '" at indent ' + originalIndent);
                    luaCode.add("local " + alias + " = require(\"" + libName + "\")\n");
                    i++;
                    continue;
                }
            }

            var inlineComment = "";
            var commentPos = trimmedLine.indexOf(" -/");
            if (commentPos > -1) {
                inlineComment = " --" + trimStr(trimmedLine.substring(commentPos + 3));
                trimmedLine = trimStr(trimmedLine.substring(0, commentPos));
            }

            inString = false;
            stringChar = "";
            for (i in 0...trimmedLine.length) {
                var c = trimmedLine.charAt(i);
                if (!inString && (c == '"' || c == "'" || c == "“" || c == "”" || c == "‘" || c == "’")) {
                    inString = true;
                    stringChar = c;
                } else if (inString && c == stringChar) {
                    inString = false;
                }
            }

            if (!inBlockComment && !inString) {
                var codeToCheck = trimmedLine;
                if (codeToCheck.indexOf('nil') > -1) {
                    errors.push('Error at line $currentLine: \'nil\' is prohibited in ZS');
                    return null;
                }
                if (codeToCheck.indexOf('return') > -1) {
                    errors.push('Error at line $currentLine: \'return\' is prohibited in ZS');
                    return null;
                }
                if (codeToCheck.indexOf('function') > -1) {
                    errors.push('Error at line $currentLine: \'function\' is prohibited in ZS');
                    return null;
                }
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

                if (codeToCheck.indexOf("elseif") > -1) {
                    errors.push('Error at line $currentLine: Lua "elseif" is not allowed in ZS');
                    errors.push('  → Use "else if" instead');
                    return null;
                }

                if (codeToCheck.indexOf("~=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "~=" is not allowed in ZS');
                    errors.push('  → Use "≠" instead');
                    return null;
                }
                if (codeToCheck.indexOf("<=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "<=" is not allowed in ZS');
                    errors.push('  → Use "≤" instead');
                    return null;
                }
                if (codeToCheck.indexOf(">=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator ">=" is not allowed in ZS');
                    errors.push('  → Use "≥" instead');
                    return null;
                }
                if (codeToCheck.indexOf("-=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "-=" is not allowed in ZS');
                    errors.push('  → Use "−=" instead');
                    return null;
                }
                if (codeToCheck.indexOf("*=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "*=" is not allowed in ZS');
                    errors.push('  → Use "×=" instead');
                    return null;
                }
                if (codeToCheck.indexOf("/=") > -1) {
                    errors.push('Error at line $currentLine: Lua operator "/=" is not allowed in ZS');
                    errors.push('  → Use "÷=" instead');
                    return null;
                }
                if (codeToCheck.indexOf("--") > -1) {
                    errors.push('Error at line $currentLine: Lua comment "--" is not allowed in ZS');
                    errors.push('  → Use "-/" for comments instead');
                    return null;
                }
                if (codeToCheck.indexOf("--[[") > -1 || codeToCheck.indexOf("]]") > -1 || codeToCheck.indexOf("]]--") > -1) {
                    errors.push('Error at line $currentLine: Lua block comment "--[[ ... ]]"/"--[[ ... ]]--" is not allowed in ZS');
                    errors.push('  → Use "*/- ... /-*" for block comments instead');
                    return null;
                }

                if (codeToCheck.indexOf("local ") == 0 && codeToCheck.indexOf("local <") != 0) {
                    errors.push('Error at line $currentLine: "local" must be followed by noun wrapper "<...>"');
                    errors.push('  Found: "$codeToCheck"');
                    errors.push('  Use "local <name> = value"');
                    return null;
                }
                if (codeToCheck.indexOf("global ") == 0 && codeToCheck.indexOf("global <") != 0) {
                    errors.push('Error at line $currentLine: "global" must be followed by noun wrapper "<...>"');
                    errors.push('  Found: "$codeToCheck"');
                    errors.push('  Use "global <name> = value"');
                    return null;
                }
                if (codeToCheck.indexOf("=") > -1 && codeToCheck.indexOf("<") == -1) {
                    var isRawAssignment = ~/^[a-zA-Z_][a-zA-Z0-9_]* =/;
                    if (isRawAssignment.match(codeToCheck)) {
                        errors.push('Error at line $currentLine: Raw Lua assignment detected');
                        errors.push('  Found: "$codeToCheck"');
                        errors.push('  Use "change <property> to value" instead');
                        return null;
                    }
                }
                if (codeToCheck.indexOf("(") > -1 && codeToCheck.indexOf("<") == -1) {
                    var isRawCall = ~/^[a-zA-Z_][a-zA-Z0-9_]*\(/;
                    if (isRawCall.match(codeToCheck)) {
                        errors.push('Error at line $currentLine: Raw Lua function call detected');
                        errors.push('  Found: "$codeToCheck"');
                        errors.push('  Use natural ZS syntax instead (e.g., "call method", "play sound", etc.)');
                        return null;
                    }
                }
                if (codeToCheck.indexOf(";") > -1) {
                    errors.push('Error at line $currentLine: Semicolon ";" is not allowed in ZS');
                    errors.push('  → ZS uses natural line breaks, not semicolons');
                    return null;
                }

                var patterns = [
                    ~/[0-9] *- *[0-9]/, ~/[0-9]-[0-9]/, ~/[0-9] *-[0-9]/, ~/[0-9]- *[0-9]/,
                    ~/> *- *</, ~/>-</, ~/> *-</, ~/>- *</,
                    ~/[0-9] *- *</, ~/[0-9]-</, ~/[0-9]- *</, ~/[0-9] *-</,
                    ~/> *- *[0-9]/, ~/>-[0-9]/, ~/>- *[0-9]/, ~/> *-[0-9]/,
                    ~/\) *- *[0-9]/, ~/\)-[0-9]/, ~/\) *-[0-9]/, ~/\)- *[0-9]/,
                    ~/[0-9] *- *\(/, ~/[0-9]-\(/, ~/[0-9] *-\(/, ~/[0-9]- *\(/,
                    ~/\) *- *</, ~/\)-</, ~/\) *-</, ~/\)- *</,
                    ~/> *- *\(/, ~/>\-\(/, ~/> *-\(/, ~/>\- *\(/,
                    ~/\) *-\(/, ~/\)\-\(/,
                    ~/[0-9] *\* *[0-9]/, ~/[0-9]\*[0-9]/, ~/[0-9] *\*[0-9]/, ~/[0-9]\* *[0-9]/,
                    ~/> *\* *</, ~/>\*</, ~/> *\*</, ~/>\* *</,
                    ~/[0-9] *\* *</, ~/[0-9]\* *</, ~/[0-9]\*</, ~/[0-9] *\*</,
                    ~/> *\* *[0-9]/, ~/>\*[0-9]/, ~/>\* *[0-9]/, ~/> *\*[0-9]/,
                    ~/\) *\* *[0-9]/, ~/\)\*[0-9]/, ~/\) *\*[0-9]/, ~/\)\* *[0-9]/,
                    ~/[0-9] *\* *\(/, ~/[0-9]\*\(/, ~/[0-9] *\*\(/, ~/[0-9]\* *\(/,
                    ~/\) *\* *</, ~/\)\*</, ~/\) *\*</, ~/\)\* *</,
                    ~/> *\* *\(/, ~/>\*\(/, ~/> *\*\(/, ~/>\* *\(/,
                    ~/\) *\*\(/, ~/\)\*\(/,
                    ~/[0-9] *\/ *[0-9]/, ~/[0-9]\/[0-9]/, ~/[0-9] *\/[0-9]/, ~/[0-9]\/ *[0-9]/,
                    ~/> *\/ *</, ~/>\/</, ~/> *\/</, ~/>\/ *</,
                    ~/[0-9] *\/ *</, ~/[0-9]\/ *</, ~/[0-9]\/</, ~/[0-9] *\/</,
                    ~/> *\/ *[0-9]/, ~/>\/[0-9]/, ~/>\/ *[0-9]/, ~/> *\/[0-9]/,
                    ~/\) *\/ *[0-9]/, ~/\)\/[0-9]/, ~/\) *\/[0-9]/, ~/\)\/ *[0-9]/,
                    ~/[0-9] *\/ *\(/, ~/[0-9]\/\(/, ~/[0-9] *\/\(/, ~/[0-9]\/ *\(/,
                    ~/\) *\/ *</, ~/\)\/</, ~/\) *\/</, ~/\)\/ *</,
                    ~/> *\/ *\(/, ~/>\//, ~/> *\/\(/, ~/>\//,
                    ~/\) *\/\(/, ~/\)\/\(/
                ];

                for (pattern in patterns) {
                    if (pattern.match(codeToCheck)) {
                        var opType = "operator";
                        if (trimmedLine.indexOf("-") > -1) opType = "subtraction";
                        else if (trimmedLine.indexOf("*") > -1) opType = "multiplication";
                        else if (trimmedLine.indexOf("/") > -1) opType = "division";
                        var correctSymbol = opType == "subtraction" ? "−" : (opType == "multiplication" ? "×" : "÷");
                        errors.push('Error at line $currentLine: "$opType" operator is not allowed');
                        errors.push('  → Use "$correctSymbol" instead');
                        return null;
                    }
                }
            }

            var colonPos = trimmedLine.indexOf(":");
            if (colonPos > 0) {
                if (isInsideTableLiteral(trimmedLine, colonPos)) {}
                else {
                    var beforeColon = trimStr(trimmedLine.substring(0, colonPos));
                    var afterColon = trimStr(trimmedLine.substring(colonPos + 1));
                    trace('COLON HANDLER: line=$currentLine, before="$beforeColon", after="$afterColon"');

                    if (afterColon == "") {
                        if (beforeColon.indexOf("<") > -1) {
                            var funcName = beforeColon.split("<")[0];
                            var allParams = [];
                            var pos = 0;
                            var temp = beforeColon;
                            while (true) {
                                var start = temp.indexOf("<", pos);
                                if (start == -1) break;
                                var end = temp.indexOf(">", start);
                                if (end == -1) break;
                                allParams.push(temp.substring(start + 1, end));
                                pos = end + 1;
                            }
                            trimmedLine = "function " + funcName + "(" + allParams.join(", ") + ")";
                        } else {
                            trimmedLine = "function " + beforeColon + "()";
                        }
                    }
                    else if (beforeColon == "print" || beforeColon == "print(debug)") {}
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
                    else if (afterColon.indexOf(" ") > -1) {
                        var spaceIdx = afterColon.indexOf(" ");
                        var firstWord = afterColon.substring(0, spaceIdx);
                        var rest = afterColon.substring(firstWord.length + 1);
                        if (rest.indexOf(",") > -1) {
                            trimmedLine = beforeColon + "." + firstWord + "(" + rest + ")";
                        } else {
                            var hasOperator = (rest.indexOf("−") > -1 || rest.indexOf("×") > -1 || rest.indexOf("÷") > -1 || rest.indexOf("+") > -1);
                            if (hasOperator) {
                                trimmedLine = beforeColon + "." + afterColon;
                            } else {
                                trimmedLine = beforeColon + "." + firstWord + "(" + rest + ")";
                            }
                        }
                    }
                    else {
                        trimmedLine = beforeColon + "." + afterColon;
                    }
                }
            }

            trimmedLine = fixMinusSigns(trimmedLine);

            log.push('BEFORE ZSPatterns: trimmedLine="$trimmedLine"');
            var luaLine = trimmedLine;
            var allPatterns = ZSPatterns.getPatterns();

            log.push('=== APPLYING PATTERNS ===');
            log.push('Input line: "' + luaLine + '"');

            var matchedAtStart = false;
            for (pattern in allPatterns) {
                var regex = new EReg(pattern.pattern, "g");
                if (regex.match(luaLine)) {
                    var matchPos = regex.matchedPos().pos;
                    if (matchPos == 0) {
                        log.push('  MATCHED at start: ' + pattern.pattern);
                        luaLine = replaceMultiPattern(regex, pattern, luaLine, luaLine);
                        log.push('  -> "' + luaLine + '"');
                        matchedAtStart = true;
                        break;
                    }
                }
            }

            if (!matchedAtStart) {
                var changed = true;
                while (changed) {
                    changed = false;
                    for (pattern in allPatterns) {
                        var regex = new EReg(pattern.pattern, "g");
                        if (regex.match(luaLine)) {
                            var before = luaLine;
                            luaLine = regex.replace(luaLine, pattern.replacement);
                            if (before != luaLine) {
                                changed = true;
                                log.push('  NESTED MATCHED: ' + pattern.pattern);
                                log.push('  -> "' + luaLine + '"');
                            }
                        }
                    }
                }
            }
            log.push('AFTER ZSPatterns: luaLine="$luaLine"');

            luaLine = convertQuotes(luaLine);

            if (luaLine.indexOf(":") == -1 && luaLine.indexOf("function") == -1) {
                var funcCallMixedPattern = ~/^([a-zA-Z_][a-zA-Z0-9_]*)<([^>]+)(?:, *<([^>]+)>)*>, (.+)$/;
                if (funcCallMixedPattern.match(luaLine)) {
                    var funcName = funcCallMixedPattern.matched(1);
                    var nounArgs = funcCallMixedPattern.matched(2);
                    var directArgs = funcCallMixedPattern.matched(4);
                    var allNounArgs = [nounArgs];
                    var rest = luaLine.substring(luaLine.indexOf(">") + 1);
                    while (rest.indexOf("<") > -1) {
                        var start = rest.indexOf("<");
                        var end = rest.indexOf(">", start);
                        if (end == -1) break;
                        allNounArgs.push(rest.substring(start + 1, end));
                        rest = rest.substring(end + 1);
                    }
                    var combinedArgs = allNounArgs.join(", ");
                    if (directArgs != "") {
                        luaLine = funcName + "(" + combinedArgs + ", " + directArgs + ")";
                    } else {
                        luaLine = funcName + "(" + combinedArgs + ")";
                    }
                }
                else {
                    var funcCallNounPattern = ~/^([a-zA-Z_][a-zA-Z0-9_]*)<([^>]+)(?:, *<([^>]+)>)*>$/;
                    if (funcCallNounPattern.match(luaLine)) {
                        var funcName = funcCallNounPattern.matched(1);
                        var allNounArgs = [];
                        var temp = luaLine;
                        while (temp.indexOf("<") > -1) {
                            var start = temp.indexOf("<");
                            var end = temp.indexOf(">", start);
                            if (end == -1) break;
                            allNounArgs.push(temp.substring(start + 1, end));
                            temp = temp.substring(end + 1);
                        }
                        luaLine = funcName + "(" + allNounArgs.join(", ") + ")";
                    }
                }

                if (luaLine.indexOf("<") == -1) {
                    var funcCallDirectPattern = ~/^([a-zA-Z_][a-zA-Z0-9_]*) (.+)$/;
                    if (funcCallDirectPattern.match(luaLine)) {
                        var funcName = funcCallDirectPattern.matched(1);
                        var args = funcCallDirectPattern.matched(2);
                        trace('=== funcCallDirectPattern matched: funcName="$funcName", args="$args" ===');
                        var keywords = ["if", "else", "else if", "then", "end", "while", "do", "repeat", "until", "for", "in", "function", "local", "global", "return", "break", "and", "or", "not", "true", "false", "nil"];

                        if (!keywords.contains(funcName)) {
                            var processedArgs = args;
                            for (pattern in allPatterns) {
                                var pRegex = new EReg(pattern.pattern, "g");
                                if (pRegex.match(processedArgs)) {
                                    processedArgs = pRegex.replace(processedArgs, pattern.replacement);
                                }
                            }
                            processedArgs = convertEmptyToNil(processedArgs);
                            trace('    -> wrapping: funcName + "(" + processedArgs + ")" = "$funcName($processedArgs)"');
                            luaLine = funcName + "(" + processedArgs + ")";
                        }
                    }
                }
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
            luaLine = convertGroupingBrackets(luaLine);
            trace('AFTER convertGroupingBrackets: luaLine="$luaLine"');

            if (luaLine.indexOf("else if ") == 0) {
                luaLine = "elseif " + luaLine.substr(8);
            }

            var startParen = luaLine.indexOf("(");
            if (startParen > -1) {
                var beforeParen = StringTools.trim(luaLine.substring(0, startParen));
                var isFunctionCall = false;

                if (beforeParen.length > 0 && beforeParen.indexOf(" ") == -1) {
                    var firstChar = beforeParen.charAt(0);
                    if ((firstChar >= 'a' && firstChar <= 'z') || (firstChar >= 'A' && firstChar <= 'Z') || firstChar == '_') {
                        isFunctionCall = true;
                    }
                }

                if (isFunctionCall) {
                    var depth = 1;
                    var endParen = startParen + 1;
                    while (endParen < luaLine.length && depth > 0) {
                        var ch = luaLine.charAt(endParen);
                        if (ch == '(') depth++;
                        if (ch == ')') depth--;
                        endParen++;
                    }
                    endParen--;

                    if (endParen > startParen) {
                        var beforeParenFull = luaLine.substring(0, startParen);
                        var content = luaLine.substring(startParen + 1, endParen);
                        var afterParen = luaLine.substring(endParen + 1);

                        trace('BEFORE splitArgs: content="$content"');

                        var args = splitArgs(content);
                        for (j in 0...args.length) {
                            var arg = args[j];
                            var trimmedArg = StringTools.trim(arg);

                            var isTableLiteral = (trimmedArg.indexOf("{") == 0 && trimmedArg.lastIndexOf("}") == trimmedArg.length - 1);
                            var isListLiteral = (trimmedArg.indexOf("[") == 0 && trimmedArg.lastIndexOf("]") == trimmedArg.length - 1);

                            if (isTableLiteral) {
                                args[j] = processTableLiteral(arg);
                                trace('Argument $j is table literal, processed: "${args[j]}"');
                                continue;
                            } else if (isListLiteral) {
                                args[j] = arg;
                                trace('Argument $j is list literal, keeping: "${args[j]}"');
                                continue;
                            } else if (trimmedArg == "") {
                                args[j] = "nil";
                                trace('Argument $j is empty, replacing with nil');
                                continue;
                            } else {
                                trace('Argument $j before parse: "${args[j]}"');
                                var originalArg = args[j];
                                var parsed = ZSParser.parseExpression(args[j]);
                                args[j] = parsed;
                                trace('Argument $j after parse: "${args[j]}"');

                                var parts = originalArg.split(" ");
                                trace('    -> parts.length=${parts.length}, parts=$parts');
                                if (parts.length > 1) {
                                    var firstWord = parts[0];
                                    var rest = originalArg.substring(firstWord.length + 1);
                                    var firstChar = trimStr(rest).charAt(0);
                                    trace('    -> firstWord="$firstWord", rest="$rest", firstChar="$firstChar"');

                                    var hasComma = rest.indexOf(",") > -1;
                                    if (hasComma && isKnownFunction(firstWord)) {
                                        args[j] = firstWord + "(" + rest + ")";
                                        trace('    -> Argument $j converted to function call (has comma): "${args[j]}"');
                                    } else if (firstChar != "+" && firstChar != "-" && firstChar != "*" && firstChar != "/") {
                                        args[j] = firstWord + "(" + rest + ")";
                                        trace('    -> Argument $j converted to function call: "${args[j]}"');
                                    } else {
                                        trace('    -> Not converting (firstChar is operator)');
                                    }
                                }
                            }
                        }
                        var parsedContent = args.join(", ");
                        luaLine = beforeParenFull + "(" + parsedContent + ")" + afterParen;
                        trace('splitArgs result: $args');
                    }
                }
            }

            luaLine = ~/<([^>]+)>/g.replace(luaLine, "$1");
            luaLine = addOperatorSpacing(luaLine);

            if (originalIndent == 0 && (luaLine.indexOf("function ") == 0)) {
                while (indentationStack.length > 1) {
                    var blockIndent = indentationStack[indentationStack.length - 1];
                    for (_ in 0...blockIndent) {
                        trace('OUTPUT: "end" at indent $blockIndent');
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "end" at indent ' + blockIndent);
                    luaCode.add("end\n");
                    indentationStack.pop();
                    blockTypeStack.pop();
                }
                trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
                luaCode.add("\n");
                lastIndent = 0;
            }

            trace('=== DEDENT CHECK at line $currentLine ===');
            trace('  originalIndent=$originalIndent, lastIndent=$lastIndent');
            trace('  trimmedLine="$trimmedLine"');
            trace('  blockTypeStack=$blockTypeStack');
            trace('  indentationStack=$indentationStack');
            trace('  condition1: originalIndent <= lastIndent = ${originalIndent <= lastIndent}');
            trace('  condition2: !isBlockStarter = ${!isBlockStarter(trimmedLine)}');

            var isElseOrElseIf = (trimmedLine.indexOf("else if") == 0 || trimmedLine.indexOf("else") == 0);

            if (originalIndent <= lastIndent && trimmedLine != "" && !isBlockStarter(trimmedLine) && !isElseOrElseIf) {
                while (indentationStack.length > 1 && originalIndent <= indentationStack[indentationStack.length - 1]) {
                trace('  CLOSING BLOCKS...');
                    var blockIndent = indentationStack[indentationStack.length - 1];
                    trace('    adding "end" with indent $blockIndent');
                    for (_ in 0...blockIndent) {
                        trace('OUTPUT: "end" at indent $blockIndent');
                        luaCode.add(" ");
                    }
                    trace('OUTPUT: "end" at indent ' + blockIndent);
                    luaCode.add("end\n");
                    indentationStack.pop();
                    blockTypeStack.pop();
                }
                trace('  after closing, stack=$indentationStack');
            }

            if (skipLine) {
                lastIndent = originalIndent;
                i++;
                continue;
            }

            var isConditionalStart = (luaLine.indexOf("if ") == 0 && luaLine.indexOf(" then") > -1);
            var isLoopStart = (luaLine.indexOf("for ") == 0 && luaLine.indexOf(" do") > -1) || (luaLine.indexOf("while ") == 0 && luaLine.indexOf(" do") > -1);
            var isFunctionStart = (luaLine.indexOf("function ") == 0);
            var isRepeat = (luaLine == "repeat");
            var isElseOrElseIf = (luaLine.indexOf("else if") == 0 || luaLine.indexOf("else") == 0);
            var isBlockStarter = (isConditionalStart || isLoopStart || isFunctionStart || isRepeat);

            if (!isBlockStarter && !isElseOrElseIf) {
                for (_ in 0...originalIndent) {
                    trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
                    luaCode.add(" ");
                }
                trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
                luaCode.add(luaLine + inlineComment + "\n");
                lastIndent = originalIndent;
                i++;
                continue;
            }

            if (isBlockStarter) {
                if (indentationStack.length > 1 && originalIndent == indentationStack[indentationStack.length - 1]) {
                    var lastBlock = blockTypeStack.length > 0 ? blockTypeStack[blockTypeStack.length - 1] : "";
                    if (lastBlock == "if") {
                        var blockIndent = indentationStack[indentationStack.length - 1];
                        for (_ in 0...blockIndent) {
                            trace('OUTPUT: "end" at indent $blockIndent');
                            luaCode.add(" ");
                        }
                        trace('OUTPUT: "end" at indent ' + blockIndent);
                        if (pendingNewline) {
                            luaCode.add("\n");
                            pendingNewline = false;
                        }
                        luaCode.add("end\n\n");
                        indentationStack.pop();
                        blockTypeStack.pop();
                        trace('Closed if block before starting new block at same indent');
                    } else if (lastBlock != "else" && lastBlock != "else if") {
                        var blockIndent = indentationStack[indentationStack.length - 1];
                        for (_ in 0...blockIndent) {
                            trace('OUTPUT: "end" at indent $blockIndent');
                            luaCode.add(" ");
                        }
                        trace('OUTPUT: "end" at indent ' + blockIndent);
                        if (pendingNewline) {
                            luaCode.add("\n");
                            pendingNewline = false;
                        }
                        luaCode.add("end\n\n");
                        indentationStack.pop();
                        blockTypeStack.pop();
                        trace('Closed previous block "$lastBlock" before pushing new block at same indent');
                    }
                }

                for (_ in 0...originalIndent) {
                    trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
                    luaCode.add(" ");
                }
                trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
                luaCode.add(luaLine + inlineComment + "\n");

                if (isConditionalStart) {
                    indentationStack.push(originalIndent);
                    blockTypeStack.push("if");
                    trace('  PUSH if: stack=$indentationStack');
                } else if (isLoopStart) {
                    indentationStack.push(originalIndent);
                    blockTypeStack.push("loop");
                    trace('  PUSH loop: stack=$indentationStack');
                } else if (isFunctionStart) {
                    indentationStack.push(originalIndent);
                    blockTypeStack.push("function");
                    trace('  PUSH function: stack=$indentationStack');
                } else if (isRepeat) {
                    indentationStack.push(originalIndent);
                    blockTypeStack.push("repeat");
                    trace('  PUSH repeat: stack=$indentationStack');
                }
                lastIndent = originalIndent;
                i++;
                continue;
            }

            for (_ in 0...originalIndent) {
                trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
                luaCode.add(" ");
            }
            trace('OUTPUT: "' + luaLine + '" at indent ' + originalIndent);
            luaCode.add(luaLine + inlineComment + "\n");

            lastIndent = originalIndent;
            i++;
        }

        while (indentationStack.length > 1) {
            var blockIndent = indentationStack[indentationStack.length - 1];
            for (_ in 0...blockIndent) {
                log.push('OUTPUT: "end" at indent $blockIndent');
                luaCode.add(" ");
            }
            log.push('OUTPUT: "end" at indent ' + blockIndent);
            luaCode.add("end\n");
            indentationStack.pop();
            blockTypeStack.pop();
        }

        var result = luaCode.toString();

        #if sys
        try {
            var logContent = log.join("\n");
            sys.io.File.saveContent("transpiler.log", logContent);
        } catch (e:Dynamic) {
            trace("Error: " + e);
        }
        #end

        return result;
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
        line = subNoSpace.replace(line, "$1−$2");
        var negRegex = ~/(^|[=\(\{,;+*\/÷−]) *- *([0-9<][^ ]*)/g;
        line = negRegex.replace(line, "$1-$2");
        var subRegex2 = ~/([0-9>][^ ]*)- *([0-9<][^ ]*)/g;
        line = subRegex2.replace(line, "$1− $2");
        var subRegex3 = ~/([0-9>][^ ]*) *-([0-9<][^ ]*)/g;
        line = subRegex3.replace(line, "$1 −$2");
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
        if (l.indexOf("else if") == 0 || l.indexOf("else") == 0) return false;
        if (l.charAt(l.length - 1) == ":") return true;
        if (l.indexOf("if ") == 0 && (l.charAt(l.length - 1) == ":" || l.indexOf(" then") > -1)) return true;
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

    static function splitArgs(content:String):Array<String> {
        trace('=== splitArgs INPUT: "$content" ===');
        var args = [];
        var current = "";
        var depth = 0;
        var inQuote = false;
        var i = 0;
        while (i < content.length) {
            var c = content.charAt(i);
            trace('  pos $i: char="$c", depth=$depth, inQuote=$inQuote, current="$current"');
            if (c == '"' || c == "'" || c == '‘' || c == '’' || c == "“" || c == "”") {
                inQuote = !inQuote;
                current += c;
            } else if (!inQuote && (c == '(' || c == '[' || c == '{')) {
                depth++;
                current += c;
            } else if (!inQuote && (c == ')' || c == ']' || c == '}')) {
                depth--;
                current += c;
            } else if (!inQuote && depth == 0 && c == ',') {
                var trimmedCurrent = trimStr(current);
                var firstWord = trimmedCurrent.split(" ")[0];
                if (isKnownFunction(firstWord)) {
                    trace('    -> not splitting, first word is known function: "$firstWord", keeping comma');
                    current += c;
                } else {
                    trace('    -> splitting at comma, pushing "$current"');
                    args.push(current);
                    current = "";
                }
            } else if (!inQuote && depth == 0 && c == '-' && i + 1 < content.length && isDigit(content.charAt(i + 1)) && StringTools.trim(current) != "") {
                trace('    -> found negative number, pushing "$current" and starting new arg');
                args.push(current);
                current = "-";
                i++;
                while (i < content.length && isDigit(content.charAt(i))) {
                    current += content.charAt(i);
                    i++;
                }
                args.push(current);
                current = "";
                continue;
            } else if (!inQuote && depth == 0 && c == ' ' && current == "") {
                i++;
                continue;
            } else {
                current += c;
            }
            i++;
        }
        if (current != "") args.push(current);
        trace('=== splitArgs OUTPUT: $args ===');
        return args;
    }

    static function isDigit(c:String):Bool {
        return c >= '0' && c <= '9';
    }

    static function isKnownFunction(keyword:String):Bool {
        for (func in userDefinedFunctions) {
            if (keyword == func || keyword.indexOf(func) == 0) {
                return true;
            }
        }

        var knownFunctions = [
            "read", "instance", "change", "add", "remove", "scale", "center",
            "create", "load", "play", "fade", "shake", "flash", "trigger",
            "start", "cancel", "call", "run", "register", "flush", "erase",
            "precache", "tween"
        ];

        for (func in knownFunctions) {
            if (keyword == func || keyword.indexOf(func) == 0) {
                return true;
            }
        }

        return false;
    }

    static function isMultiConditionCheck(line:String):Bool {
        var l = trimStr(line);
        var i = 0;
        var len = l.length;
        while (i < len) {
            if (i + 7 <= len && l.substring(i, i + 7) == "else if") return true;
            if (i + 4 <= len && l.substring(i, i + 4) == "else") {
                if (i + 4 == len || !isAlphaNum(l.charAt(i + 4))) return true;
            }
            i++;
        }
        return false;
    }

    static function isAlphaNum(c:String):Bool {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
    }

    static function addOperatorSpacing(line:String):String {
        line = ~/([0-9a-zA-Z_\)\]\}]) *- *(?=[0-9a-zA-Z_\(\[\{])/g.replace(line, "$1 - ");
        line = ~/([0-9a-zA-Z_\)\]\}])\*([0-9a-zA-Z_\(\[\{])/g.replace(line, "$1 * $2");
        line = ~/([0-9a-zA-Z_\)\]\}])\/([0-9a-zA-Z_\(\[\{])/g.replace(line, "$1 / $2");

        return line;
    }

    static function processTableLiteral(table:String):String {
        trace('=== processTableLiteral INPUT: "$table" ===');
        var result = "";
        var inString = false;
        var stringChar = "";
        var depth = 0;
        var i = 0;
        var currentValue = "";

        while (i < table.length) {
            var c = table.charAt(i);
            trace('  pos $i: char="$c", depth=$depth, inString=$inString, currentValue="$currentValue", result="$result"');

            if (!inString && (c == '"' || c == "'" || c == '‘' || c == '’' || c == "“" || c == "”")) {
                inString = true;
                stringChar = c;
                currentValue += c;
                i++;
                continue;
            }

            if (inString && c == stringChar) {
                inString = false;
                currentValue += c;
                i++;
                continue;
            }

            if (!inString && (c == '{' || c == '[' || c == '(')) {
                depth++;
                currentValue += c;
                i++;
                continue;
            }

            if (!inString && (c == '}' || c == ']' || c == ')')) {
                currentValue += c;
                depth--;
                if (depth == 0 && trimStr(currentValue) == "") {
                    result += "nil";
                    currentValue = "";
                } else if (depth == 0) {
                    result += currentValue;
                    currentValue = "";
                }
                i++;
                continue;
            }

            if (!inString && depth == 0 && c == ',') {
                if (trimStr(currentValue) == "") {
                    result += "nil";
                } else {
                    result += currentValue;
                }
                result += c;
                currentValue = "";
                i++;
                continue;
            }

            if (!inString && depth > 0 && c == ',') {
                trace('    -> depth > 0 comma, currentValue="$currentValue"');
                var trimmedValue = trimStr(currentValue);
                if (trimmedValue == "") {
                    var lastChar = result.length > 0 ? result.charAt(result.length - 1) : "";
                    if (lastChar == ')' || lastChar == ']' || lastChar == '}') {
                        trace('    -> empty value after closing bracket, skipping nil insertion');
                        result += c + " ";
                    } else {
                        trace('    -> empty value, adding nil, comma and space to result');
                        result += "nil" + c;
                    }
                } else {
                    trace('    -> adding trimmed value + comma + space: "$trimmedValue" + "$c" + " "');
                    result += trimmedValue + c + " ";
                }
                currentValue = "";
                i++;
                continue;
            }

            currentValue += c;
            i++;
        }

        if (currentValue != "") {
            if (trimStr(currentValue) == "") {
                result += "nil";
            } else {
                result += currentValue;
            }
        }

        trace('=== processTableLiteral OUTPUT: "$result" ===');
        return result;
    }

    static function convertGroupingBrackets(line:String):String {
        var result = "";
        var i = 0;
        var len = line.length;
        var inString = false;
        var stringChar = "";
        var inComment = false;
        var parenDepth = 0;

        while (i < len) {
            var c = line.charAt(i);
            if (!inString && !inComment && i + 1 < len && c == '-' && line.charAt(i + 1) == '/') {
                inComment = true;
                i += 2;
                continue;
            }

            if (!inString && !inComment && i + 2 < len && c == '*' && line.charAt(i + 1) == '/' && line.charAt(i + 2) == '-') {
                inComment = true;
                i += 3;
                continue;
            }

            if (inComment && i + 2 < len && c == '/' && line.charAt(i + 1) == '-' && line.charAt(i + 2) == '*') {
                inComment = false;
                result += c + line.charAt(i + 1) + line.charAt(i + 2);
                i += 3;
                continue;
            }

            if (!inString && !inComment && (c == '"' || c == "'" || c == "‘" || c == "’" || c == "“" || c == "”")) {
                inString = true;
                stringChar = c;
                result += c;
                i++;
                continue;
            }

            if (inString && c == stringChar) {
                inString = false;
                result += c;
                i++;
                continue;
            }

            if (inString || inComment) {
                result += c;
                i++;
                continue;
            }

            if (c == '(') {
                parenDepth++;
                result += c;
                i++;
                continue;
            }

            if (c == ')') {
                parenDepth--;
                result += c;
                i++;
                continue;
            }

            if (c == '[' || c == '{') {
                var openChar = c;
                var closeChar = (openChar == '[') ? ']' : '}';
                var depth = 1;
                var j = i + 1;
                while (j < len && depth > 0) {
                    var ch = line.charAt(j);
                    if (ch == openChar) depth++;
                    if (ch == closeChar) depth--;
                    j++;
                }
                var inner = line.substring(i + 1, j - 1);

                var isLiteral = false;
                var inString = false;
                var k = 0;
                while (k < inner.length) {
                    var ch = inner.charAt(k);
                    if (ch == '"' || ch == "'" || ch == "‘" || ch == "’" || ch == "“" || ch == "”") {
                        inString = !inString;
                    }
                    if (!inString && (ch == ',' || ch == ':')) {
                        isLiteral = true;
                        break;
                    }
                    k++;
                }
                var isListAccess = (inner.indexOf("<") != -1 && inner.indexOf(">") != -1);
                var isEmptyTable = (openChar == '{' && trimStr(inner) == "");
                var isEmptyList = (openChar == '[' && trimStr(inner) == "");

                if (isLiteral || isListAccess || isEmptyTable || isEmptyList) {
                    var processedInner = convertEmptyToNil(inner);
                    result += openChar + processedInner + closeChar;
                } else if (parenDepth > 0) {
                    var processedInner = convertEmptyToNil(inner);
                    result += openChar + processedInner + closeChar;
                } else {
                    result += "(" + convertGroupingBrackets(inner) + ")";
                }
                i = j;
            } else {
                result += c;
                i++;
            }
        }
        return result;
    }

    static function convertEmptyToNil(str:String):String {
        var result = "";
        var inString = false;
        var stringChar = "";
        var inBrackets = 0;
        var i = 0;

        while (i < str.length) {
            var c = str.charAt(i);

            if (!inString && (c == '"' || c == "'" || c == "‘" || c == "’" || c == "“" || c == "”")) {
                inString = true;
                stringChar = c;
                result += c;
                i++;
                continue;
            }

            if (inString && c == stringChar) {
                inString = false;
                result += c;
                i++;
                continue;
            }

            if (inString) {
                result += c;
                i++;
                continue;
            }

            if (c == '(' || c == '[' || c == '{') {
                inBrackets++;
                result += c;
                i++;
                continue;
            }

            if (c == ')' || c == ']' || c == '}') {
                inBrackets--;
                result += c;
                i++;
                continue;
            }

            if (inBrackets > 0 && c == ',') {
                var j = i + 1;
                var spaceCount = 0;
                while (j < str.length && str.charAt(j) == ' ') {
                    spaceCount++;
                    j++;
                }
                if (j < str.length && (str.charAt(j) == ',' || str.charAt(j) == ')' || str.charAt(j) == ']' || str.charAt(j) == '}')) {
                    result += ", nil";
                    if (str.charAt(j) == ',') {
                        result += ",";
                        i = j;
                    } else {
                        i = j - 1;
                    }
                    continue;
                }
                result += c;
                i++;
                continue;
            }

            if (inBrackets > 0 && c == ' ') {
                var j = i + 1;
                while (j < str.length && str.charAt(j) == ' ') {
                    j++;
                }
                if (j < str.length && (str.charAt(j) == ',' || str.charAt(j) == ')' || str.charAt(j) == ']' || str.charAt(j) == '}')) {
                    var prevChar = result.length > 0 ? result.charAt(result.length - 1) : '';
                    if (prevChar != ',' && prevChar != '(' && prevChar != '[' && prevChar != '{') {
                        result += ", nil";
                    } else {
                        result += " nil";
                    }
                    i = j - 1;
                    continue;
                }
            }

            result += c;
            i++;
        }

        return result;
    }

    static function isInsideTableLiteral(line:String, colonPos:Int):Bool {
        var braceDepth = 0;
        for (i in 0...colonPos) {
            var c = line.charAt(i);
            if (c == '{') braceDepth++;
            if (c == '}') braceDepth--;
        }
        var hasCommaOrQuote = false;
        for (i in 0...colonPos) {
            var c = line.charAt(i);
            if (c == ',' || c == '"' || c == "'" || c == "“" || c == "”") {
                hasCommaOrQuote = true;
                break;
            }
        }
        return braceDepth > 0 && hasCommaOrQuote;
    }

    static function replaceMultiPattern(regex:EReg, pattern:Pattern, luaLine:String, trimmedLine:String):String {
        var result = trimmedLine;
        var allPatterns = ZSPatterns.getPatterns();

        var mainMatchesAtStart = false;
        if (regex.match(result)) {
            var matchPos = regex.matchedPos().pos;
            if (matchPos == 0) {
                mainMatchesAtStart = true;
            }
        }

        if (mainMatchesAtStart) {
            var mainRegex = new EReg(pattern.pattern, "g");
            result = mainRegex.replace(result, pattern.replacement);
        }

        var changed = true;
        var maxIterations = 10;
        var iterations = 0;

        while (changed && iterations < maxIterations) {
            changed = false;
            iterations++;

            for (p in allPatterns) {
                var pRegex = new EReg(p.pattern, "g");
                if (pRegex.match(result)) {
                    var matchPos = pRegex.matchedPos().pos;
                    if (matchPos > 0 || !mainMatchesAtStart) {
                        var before = result;
                        result = pRegex.replace(result, p.replacement);
                        if (before != result) {
                            changed = true;
                            log.push('  NESTED MATCHED: ' + p.pattern);
                            log.push('  -> "' + result + '"');
                            break;
                        }
                    }
                }
            }
        }

        return result;
    }
}