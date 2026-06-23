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
        var blockTypeStack:Array<String> = [];
        var lastIndent = 0;
        var inBlockComment = false;
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

                var patterns = [
                    ~/[0-9] *- *[0-9]/, ~/[0-9]-[0-9]/, ~/[0-9] *-[0-9]/, ~/[0-9]- *[0-9]/,
                    ~/> *- *</, ~/>-</, ~/> *-</, ~/>- *</,
                    ~/[0-9] *- *</, ~/[0-9]-</, ~/[0-9]- *</, ~/[0-9] *-</,
                    ~/> *- *[0-9]/, ~/>-[0-9]/, ~/>- *[0-9]/, ~/> *-[0-9]/,
                    ~/[0-9] *\* *[0-9]/, ~/[0-9]\*[0-9]/, ~/[0-9] *\*[0-9]/, ~/[0-9]\* *[0-9]/,
                    ~/> *\* *</, ~/>\*</, ~/> *\*</, ~/>\* *</,
                    ~/[0-9] *\* *</, ~/[0-9]\* *</, ~/[0-9]\*</, ~/[0-9] *\*</,
                    ~/> *\* *[0-9]/, ~/>\*[0-9]/, ~/>\* *[0-9]/, ~/> *\*[0-9]/,
                    ~/[0-9] *\/ *[0-9]/, ~/[0-9]\/[0-9]/, ~/[0-9] *\/[0-9]/, ~/[0-9]\/ *[0-9]/,
                    ~/> *\/ *</, ~/>\/</, ~/> *\/</, ~/>\/ *</,
                    ~/[0-9] *\/ *</, ~/[0-9]\/ *</, ~/[0-9]\/</, ~/[0-9] *\/</,
                    ~/> *\/ *[0-9]/, ~/>\/[0-9]/, ~/>\/ *[0-9]/, ~/> *\/[0-9]/
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

            if (trimmedLine.indexOf("<") > -1 && trimmedLine.indexOf(">") > -1) {
                var hasLocal = trimmedLine.indexOf("local <") == 0;
                var hasGlobal = trimmedLine.indexOf("global <") == 0;
                var hasChange = trimmedLine.indexOf("change <") == 0;
                var hasRead = trimmedLine.indexOf("read <") == 0;

                if (!hasLocal && !hasGlobal && !hasChange && !hasRead) {
                    var hasListAccess = trimmedLine.indexOf(">[" ) > -1 || trimmedLine.indexOf("> [") > -1;
                    var hasTableAccess = trimmedLine.indexOf(">." ) > -1 || trimmedLine.indexOf("> .") > -1;

                    if (!hasListAccess && !hasTableAccess) {
                        errors.push('Error at line $currentLine: Noun "<...>" must be used with local, global, change, or read');
                        errors.push('  Found: "$trimmedLine"');
                        errors.push('  Use local <name> = value, change <name> to value, or read <name>');
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
                    else if (beforeColon == "print" || beforeColon == "print(debug)") {
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

            if (trimmedLine.indexOf("<") > -1 && trimmedLine.indexOf(">") > -1) {
                var funcCallPattern = ~/([a-zA-Z_][a-zA-Z0-9_]*)<([^>]+)(?:, *<([^>]+)>)*>/g;
                var match = funcCallPattern.match(trimmedLine);
                if (match) {
                    var funcName = funcCallPattern.matched(1);
                    var allArgs = [];
                    var pos = 0;
                    var tempLine = trimmedLine;
                    while (true) {
                        var start = tempLine.indexOf("<", pos);
                        if (start == -1) break;
                        var end = tempLine.indexOf(">", start);
                        if (end == -1) break;
                        allArgs.push(tempLine.substring(start + 1, end));
                        pos = end + 1;
                    }
                    trimmedLine = funcName + "(" + allArgs.join(", ") + ")";
                }
            }

            trimmedLine = convertQuotes(trimmedLine);
            trimmedLine = fixMinusSigns(trimmedLine);

            if (trimmedLine.indexOf("(") == -1 && trimmedLine.indexOf("<") == -1 && trimmedLine.indexOf(":") == -1) {
                var funcCallDirectPattern = ~/^([a-zA-Z_][a-zA-Z0-9_]*) (.+)$/;
                if (funcCallDirectPattern.match(trimmedLine)) {
                    var funcName = funcCallDirectPattern.matched(1);
                    var args = funcCallDirectPattern.matched(2);
                    trimmedLine = funcName + "(" + args + ")";
                }
            }

            trace('BEFORE ZSPatterns: trimmedLine="$trimmedLine"');
            var luaLine = trimmedLine;
            for (pattern in ZSPatterns.patterns) {
                var regex = new EReg(pattern.pattern, "g");
                luaLine = regex.replace(luaLine, pattern.replacement);
            }
            trace('AFTER ZSPatterns: luaLine="$luaLine"');

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

                            if (isTableLiteral || isListLiteral) {
                                args[j] = arg;
                                trace('Argument $j is literal, keeping: "${args[j]}"');
                            } else {
                                trace('Argument $j before parse: "${args[j]}"');
                                args[j] = ZSParser.parseExpression(args[j]);
                                trace('Argument $j after parse: "${args[j]}"');
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
                trace('OUTPUT: "end" at indent $blockIndent');
                luaCode.add(" ");
            }
            trace('OUTPUT: "end" at indent ' + blockIndent);
            luaCode.add("end\n");
            indentationStack.pop();
            blockTypeStack.pop();
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
        line = subNoSpace.replace(line, "$1−$2");
        var negRegex = ~/(^|[=\(\{,;+*\/÷−]) *- *([0-9<][^ ]*)/g;
        line = negRegex.replace(line, "$1 -$2");
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
                trace('    -> splitting at comma, pushing "$current"');
                args.push(current);
                current = "";
            } else {
                current += c;
            }
            i++;
        }
        if (current != "") args.push(current);
        trace('=== splitArgs OUTPUT: $args ===');
        return args;
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
        line = ~/([0-9a-zA-Z_\)\]\} ]) *- *([0-9a-zA-Z_\(\[\{ ])/g.replace(line, "$1 - $2");
        line = ~/([0-9a-zA-Z_\)\]\} ])\*([0-9a-zA-Z_\(\[\{ ])/g.replace(line, "$1 * $2");
        line = ~/([0-9a-zA-Z_\)\]\} ])\/([0-9a-zA-Z_\(\[\{ ])/g.replace(line, "$1 / $2");

        return line;
    }

    static function convertGroupingBrackets(line:String):String {
        var result = "";
        var i = 0;
        var len = line.length;

        while (i < len) {
            var c = line.charAt(i);
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

                if (isLiteral || isListAccess) {
                    result += openChar + convertGroupingBrackets(inner) + closeChar;
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
}