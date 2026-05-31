package zsscript;

enum Token {
    StringLiteral(value:String);
    NumberLiteral(value:String);
    Variable(value:String);
    PropertyRef(value:String);
    Operator(op:String);
    OpenParen;
    CloseParen;
}

class ZSParser {

    public static function parseExpression(expr:String):String {
        var tokens = tokenize(expr);
        return parseTokens(tokens);
    }

    static function tokenize(expr:String):Array<Token> {
        var tokens = [];
        var i = 0;
        while (i < expr.length) {
            var c = expr.charAt(i);

            if (c == " ") {
                i++;
                continue;
            }

            if (c == "+") {
                tokens.push(Operator("+"));
                i++;
                continue;
            }

            if (c == "(") {
                tokens.push(OpenParen);
                i++;
                continue;
            }

            if (c == ")") {
                tokens.push(CloseParen);
                i++;
                continue;
            }

            if (c == '"' || c == "'" || c == "“" || c == "”") {
                var start = i;
                var quote = c;
                i++;
                while (i < expr.length && expr.charAt(i) != quote) {
                    i++;
                }
                tokens.push(StringLiteral(expr.substring(start, i + 1)));
                i++;
                continue;
            }

            if ((c >= '0' && c <= '9') || (c == '-' && i + 1 < expr.length && expr.charAt(i + 1) >= '0')) {
                var start = i;
                i++;
                while (i < expr.length && ((expr.charAt(i) >= '0' && expr.charAt(i) <= '9') || expr.charAt(i) == '.')) {
                    i++;
                }
                tokens.push(NumberLiteral(expr.substring(start, i)));
                continue;
            }

            if (c == '<') {
                var start = i;
                i++;
                while (i < expr.length && expr.charAt(i) != '>') {
                    i++;
                }
                tokens.push(PropertyRef(expr.substring(start, i + 1)));
                i++;
                continue;
            }

            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_') {
                var start = i;
                i++;
                while (i < expr.length && ((expr.charAt(i) >= 'a' && expr.charAt(i) <= 'z') || (expr.charAt(i) >= 'A' && expr.charAt(i) <= 'Z') || (expr.charAt(i) >= '0' && expr.charAt(i) <= '9') || expr.charAt(i) == '_')) {
                    i++;
                }
                var name = expr.substring(start, i);

                while (i < expr.length && expr.charAt(i) == ' ') i++;
                if (i < expr.length && expr.charAt(i) == '(') {
                    var parenCount = 1;
                    i++;
                    while (i < expr.length && parenCount > 0) {
                        var ch = expr.charAt(i);
                        if (ch == '(') parenCount++;
                        else if (ch == ')') parenCount--;
                        i++;
                    }
                    tokens.push(Variable(expr.substring(start, i)));
                    continue;
                } else {
                    tokens.push(Variable(name));
                    continue;
                }
            }

            var start = i;
            i++;
            tokens.push(Variable(expr.substring(start, i)));
        }
        return tokens;
    }

    static function parseTokens(tokens:Array<Token>):String {
        var globalHasStringLiteral = false;
        for (token in tokens) {
            switch (token) {
                case StringLiteral(_): globalHasStringLiteral = true;
                default:
            }
        }

        var result = "";
        var i = 0;
        var depth = 0;

        function parseSubExpression(startIndex:Int, untilClose:Bool):{newResult:String, newIndex:Int} {
            var subResult = "";
            var j = startIndex;
            var localDepth = depth;

            while (j < tokens.length) {
                switch (tokens[j]) {
                    case OpenParen:
                        depth++;
                        var nested = parseSubExpression(j + 1, true);
                        subResult += "(" + nested.newResult + ")";
                        j = nested.newIndex;
                        depth--;
                    case CloseParen:
                        if (untilClose) {
                            return {newResult: subResult, newIndex: j + 1};
                        } else {
                            subResult += ")";
                            j++;
                        }
                    case StringLiteral(s):
                        subResult += s;
                        j++;
                    case NumberLiteral(n):
                        subResult += n;
                        j++;
                    case Variable(v):
                        subResult += v;
                        j++;
                    case PropertyRef(p):
                        subResult += p;
                        j++;
                    case Operator(op):
                        if (op == "+") {
                            if (depth > 0) {
                                subResult += " + ";
                            } else if (globalHasStringLiteral) {
                                subResult += " .. ";
                            } else {
                                subResult += " + ";
                            }
                        }
                        j++;
                    default:
                        j++;
                }
            }
            return {newResult: subResult, newIndex: j};
        }

        var parsed = parseSubExpression(0, false);
        return parsed.newResult;
    }
}