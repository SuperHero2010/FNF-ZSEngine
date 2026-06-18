package zsscript;

class ZSParenthesisValidator {
    private static var diagnosticCollection:Any;

    public static function validateLine(line:String, lineNum:Int):Array<String> {
        var diagnostics:Array<String> = [];

        var trimmed = trimStr(line);
        if (startsWith(trimmed, "-/")) {
            return diagnostics;
        }

        if (startsWith(trimmed, "*/-") && endsWith(trimmed, "/-*")) {
            return diagnostics;
        }

        var inCollection = false;
        var inBlockComment = false;
        var collectionStart = -1;
        var blockCommentStart = -1;
        var maskedLine = line.split("");

        var i = 0;
        while (i < line.length) {
            if (!inBlockComment && i + 2 < line.length && line.charAt(i) == '*' && line.charAt(i + 1) == '/' && line.charAt(i + 2) == '-') {
                inBlockComment = true;
                blockCommentStart = i;
                i += 2;
                continue;
            }
            if (inBlockComment && i + 2 < line.length && line.charAt(i) == '/' && line.charAt(i + 1) == '-' && line.charAt(i + 2) == '*') {
                inBlockComment = false;
                var k = blockCommentStart;
                while (k <= i + 2) {
                    maskedLine[k] = ' ';
                    k++;
                }
                i += 2;
                continue;
            }
            if (inBlockComment) {
                maskedLine[i] = ' ';
            }
            i++;
        }

        var commentIndex = line.indexOf("-/");
        if (commentIndex != -1) {
            var j = commentIndex;
            while (j < line.length) {
                maskedLine[j] = ' ';
                j++;
            }
        }

        i = 0;
        while (i < line.length) {
            var char = line.charAt(i);

            if (!inCollection && (char == '[' || char == '{')) {
                var closeBracket = (char == '[') ? ']' : '}';
                var depth = 0;
                var endIndex = -1;
                var j = i + 1;
                while (j < line.length) {
                    if (line.charAt(j) == char) depth++;
                    if (line.charAt(j) == closeBracket) {
                        if (depth == 0) {
                            endIndex = j;
                            break;
                        } else {
                            depth--;
                        }
                    }
                    j++;
                }

                if (endIndex != -1) {
                    var content = line.substring(i + 1, endIndex);
                    var hasComma = content.indexOf(",") != -1;
                    var hasColon = content.indexOf(":") != -1;
                    var hasQuote = content.indexOf('"') != -1 || content.indexOf("'") != -1 || content.indexOf("‘") != -1 || content.indexOf("’") != -1 || content.indexOf("“") != -1 || content.indexOf("”") != -1;

                    if (hasComma || hasColon || hasQuote) {
                        inCollection = true;
                        collectionStart = i;
                        var k = i + 1;
                        while (k < endIndex) {
                            maskedLine[k] = ' ';
                            k++;
                        }
                        i = endIndex;
                        inCollection = false;
                        continue;
                    }
                }
            }
            i++;
        }

        var maskedLineStr = maskedLine.join("");

        var stack:Array<{char:String, pos:Int}> = [];
        var pairs:Array<{open:String, close:String, openPos:Int, closePos:Int, type:String}> = [];

        var inString = false;
        var stringChar = "";

        i = 0;
        while (i < line.length) {
            var char = line.charAt(i);
            var maskedChar = maskedLineStr.charAt(i);

            if (maskedChar == ' ') {
                i++;
                continue;
            }

            if (!inString && (char == '"' || char == "'" || char == "‘" || char == "’" || char == "“" || char == "”")) {
                inString = true;
                stringChar = char;
                i++;
                continue;
            }
            if (inString && char == stringChar) {
                inString = false;
                i++;
                continue;
            }
            if (inString) {
                i++;
                continue;
            }

            if (char == '(' || char == '[' || char == '{') {
                stack.push({char: char, pos: i});
            }
            else if (char == ')' || char == ']' || char == '}') {
                if (stack.length == 0) {
                    diagnostics.push('Error at line $lineNum: Unmatched closing ${char}');
                    return diagnostics;
                }
                var open = stack.pop();
                var expectedClose = "";
                if (open.char == '(') expectedClose = ')';
                else if (open.char == '[') expectedClose = ']';
                else if (open.char == '{') expectedClose = '}';

                if (char == expectedClose) {
                    var pairType = "";
                    if (open.char == '(') pairType = "paren";
                    else if (open.char == '[') pairType = "bracket";
                    else if (open.char == '{') pairType = "brace";
                    pairs.push({
                        open: open.char,
                        close: char,
                        openPos: open.pos,
                        closePos: i,
                        type: pairType
                    });
                } else {
                    diagnostics.push('Error at line $lineNum: Expected ${expectedClose} but found ${char}');
                    return diagnostics;
                }
            }
            i++;
        }

        if (stack.length > 0) {
            for (open in stack) {
                diagnostics.push('Error at line $lineNum: Unclosed bracket: ${open.char}');
                return diagnostics;
            }
        }

        for (pair in pairs) {
            var content = line.substring(pair.openPos + 1, pair.closePos);
            content = trimStr(content);
            var hasMathOp = content.indexOf("+") != -1 || content.indexOf("−") != -1 || content.indexOf("×") != -1 || content.indexOf("÷") != -1;

            if (pair.type == "brace") {
                if (content != "") {
                    if (hasMathOp) {
                        var hasBracket = content.indexOf("[") != -1 || content.indexOf("]") != -1;

                        if (!hasBracket) {
                            diagnostics.push('Error at line $lineNum: { } must contain [ ] for math grouping');
                            return diagnostics;
                        } else {
                            var firstBracketPos = -1;
                            var firstParenPos = -1;
                            var idx = pair.openPos + 1;
                            while (idx < pair.closePos) {
                                var ch = line.charAt(idx);
                                if (ch == '[' && firstBracketPos == -1) firstBracketPos = idx;
                                if (ch == '(' && firstParenPos == -1) firstParenPos = idx;
                                idx++;
                            }

                            if (firstBracketPos != -1 && firstParenPos != -1 && firstParenPos < firstBracketPos) {
                                diagnostics.push('Error at line $lineNum: [ ] must come before ( ) inside { }');
                                return diagnostics;
                            }
                        }
                    }
                }
            }
            else if (pair.type == "bracket") {
                if (content != "") {
                    if (hasMathOp) {
                        var hasParen = content.indexOf("(") != -1 || content.indexOf(")") != -1;
                        if (!hasParen) {
                            diagnostics.push('Error at line $lineNum: [ ] must contain ( ) for math expressions');
                            return diagnostics;
                        }
                    }
                }
            }
            else if (pair.type == "paren") {
                if (content == "") {
                    diagnostics.push('Error at line $lineNum: ( ) must contain content (numbers, variables, or expressions)');
                    return diagnostics;
                }
            }
        }

        pairs.sort(function(a, b) {
            return a.openPos - b.openPos;
        });

        var n = pairs.length;
        for (p in 0...n) {
            var outer = pairs[p];
            for (q in p + 1...n) {
                var inner = pairs[q];
                if (outer.openPos < inner.openPos && outer.closePos > inner.closePos) {
                    if (outer.type == inner.type) {
                        diagnostics.push('Error at line $lineNum: Cannot nest same bracket type: ${inner.open}');
                        return diagnostics;
                    }
                    var order:Map<String,Int> = new Map<String,Int>();
                    order.set("paren", 1);
                    order.set("bracket", 2);
                    order.set("brace", 3);
                    if (order.get(inner.type) > order.get(outer.type)) {
                        diagnostics.push('Error at line $lineNum: Cannot put ${inner.open} inside ${outer.open}');
                        return diagnostics;
                    }
                }
            }
        }

        return diagnostics;
    }

    private static function trimStr(s:String):String {
        var start = 0;
        var end = s.length - 1;
        while (start <= end && (s.charAt(start) == ' ' || s.charAt(start) == '\t' || s.charAt(start) == '\r' || s.charAt(start) == '\n')) start++;
        while (end >= start && (s.charAt(end) == ' ' || s.charAt(end) == '\t' || s.charAt(end) == '\r' || s.charAt(end) == '\n')) end--;
        return s.substring(start, end + 1);
    }

    private static function startsWith(s:String, prefix:String):Bool {
        if (s.length < prefix.length) return false;
        var i = 0;
        while (i < prefix.length) {
            if (s.charAt(i) != prefix.charAt(i)) return false;
            i++;
        }
        return true;
    }

    private static function endsWith(s:String, suffix:String):Bool {
        if (s.length < suffix.length) return false;
        var start = s.length - suffix.length;
        var i = 0;
        while (i < suffix.length) {
            if (s.charAt(start + i) != suffix.charAt(i)) return false;
            i++;
        }
        return true;
    }
}