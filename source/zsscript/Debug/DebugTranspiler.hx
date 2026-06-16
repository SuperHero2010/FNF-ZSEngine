class DebugTranspiler {
    public static function main() {
        var testScript = 
"! ZS-LUA

onCreate:
    -/ Case 2: (47 + 4) -> SUCCESS
    change <result2> to (47 + 4)

    -/ Case 3: [34 − (58 ÷ 2)] -> SUCCESS
    change <result3> to [34 − (58 ÷ 2)]

    -/ Case 7: {473 + [(92 − 14) × (68 + 48)]} − 475 -> SUCCESS
    change <result7> to {473 + [(92 − 14) × (68 + 48)]} − 475

    -/ Valid literal (table) - should not be validated
    change <table> to {“name”: “John”, “age”: 30}

    -/ Valid literal (list) - should not be validated
    change <list> to [1, 2, 3, 4, 5]

    -/ Valid list access - should not be validated
    change <item> to <myList>[<index>]

    -/ Valid function call - should not be validated
    change <value> to myFunc<arg1>, <arg2>";

        trace("=== ZS DEBUG TRANSPILER ===");
        trace("Original Script:");
        trace(testScript);
        trace("");

        trace("Testing patterns one by one...");
        for (i in 0...ZSPatterns.patterns.length) {
            var p = ZSPatterns.patterns[i];
            trace('Pattern $i: ${p.pattern}');
            try {
                var regex = new EReg(p.pattern, "g");
                trace('  OK');
            } catch(e:Dynamic) {
                trace('  ERROR: $e');
                trace('  Problem pattern: ${p.pattern}');
                trace('  Replacement: ${p.replacement}');
                break;
            }
        }

        trace("Step 1: Checking ! ZS-LUA directive...");
        var lines = testScript.split("\n");
        var directiveFound = false;
        for (i in 0...lines.length) {
            var line = StringTools.trim(lines[i]);
            if (line == "! ZS-LUA") {
                directiveFound = true;
                trace("  Directive found at line " + (i+1));
                break;
            }
        }
        if (!directiveFound) trace("  Directive NOT found!");
        trace("");

        trace("Step 2: Testing pattern replacement...");
        var testLine = "setProperty: <hitHealth> = 0.5";
        trace('  Testing line: "$testLine"');

        var resultLine = testLine;
        for (pattern in ZSPatterns.patterns) {
            var regex = new EReg(pattern.pattern, "g");
            if (regex.match(resultLine)) {
                trace('  Pattern matched: "${pattern.pattern}"');
                trace('  → Category: ${pattern.category}');
                resultLine = regex.replace(resultLine, pattern.replacement);
            }
        }
        trace('  Result: "$resultLine"');

        trace("Step 3: Testing comment handling...");
        var commentLine = "    setProperty: <hitHealth> = 0.5 -/ Change value";
        trace('  Testing: "$commentLine"');

        if (commentLine.indexOf(" -/") > -1) {
            trace("  Inline comment detected");
            var parts = commentLine.split(" -/");
            trace('  Code part: "${StringTools.trim(parts[0])}"');
            trace('  Comment part: "${parts[1]}"');
        } else {
            trace("  Inline comment NOT detected");
        }
        trace("");

        trace("Step 4: Running full transpilation...");
        var result = ZSTranspiler.transpile(testScript);

        if (result != null) {
            trace(" Transpilation successful!");
            trace("");
            trace("=== OUTPUT ===");
            trace(result);
        } else {
            trace(" Transpilation failed!");
            trace("");
            trace("=== ERRORS ===");
            for (err in ZSTranspiler.errors) {
                trace(err);
            }
        }
    }
}