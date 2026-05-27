class DebugTranspiler {
    public static function main() {
        var testScript = 
"! ZS-LUA

onCreate:
    print: “Hello World”
    print: “Health: ” + read <health>
    print(debug): “Debug message”
    print: “Score: ” + read <score> + “ points”
    print: read <playerName> + “ joined the game”

onUpdate<elapsed>:
    if read <health> ≤ 0 then
        print: “Game Over”
        print(debug): “Player died at beat ” + read <curBeat>";
        
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
                trace('  ✓ OK');
            } catch(e:Dynamic) {
                trace('  ✗ ERROR: $e');
                trace('  Problem pattern: ${p.pattern}');
                trace('  Replacement: ${p.replacement}');
                break;
            }
        }
        
        // Step 1: Check directive
        trace("Step 1: Checking ! ZS-LUA directive...");
        var lines = testScript.split("\n");
        var directiveFound = false;
        for (i in 0...lines.length) {
            var line = StringTools.trim(lines[i]);
            if (line == "! ZS-LUA") {
                directiveFound = true;
                trace("  ✓ Directive found at line " + (i+1));
                break;
            }
        }
        if (!directiveFound) trace("  ✗ Directive NOT found!");
        trace("");
        
        // Step 2: Test pattern matching
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
        trace('  → Result: "$resultLine"');
        
        // Step 3: Test comment handling
        trace("Step 3: Testing comment handling...");
        var commentLine = "    setProperty: <hitHealth> = 0.5 -/ Change value";
        trace('  Testing: "$commentLine"');
        
        if (commentLine.indexOf(" -/") > -1) {
            trace("  ✓ Inline comment detected");
            var parts = commentLine.split(" -/");
            trace('  → Code part: "${StringTools.trim(parts[0])}"');
            trace('  → Comment part: "${parts[1]}"');
        } else {
            trace("  ✗ Inline comment NOT detected");
        }
        trace("");
        
        // Step 4: Full transpilation test
        trace("Step 4: Running full transpilation...");
        var result = ZSTranspiler.transpile(testScript);
        
        if (result != null) {
            trace("✓ Transpilation successful!");
            trace("");
            trace("=== OUTPUT ===");
            trace(result);
        } else {
            trace("✗ Transpilation failed!");
            trace("");
            trace("=== ERRORS ===");
            for (err in ZSTranspiler.errors) {
                trace(err);
            }
        }
    }
}