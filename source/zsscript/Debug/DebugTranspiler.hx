class DebugTranspiler {
    public static function main() {
        var testScript = 
"! ZS-LUA

import math
import string as str
import myCustomLib

local <playerName> = “John”
local <score> = 100
local <health> = 75.5

onCreate:
    change <message> to “Welcome ” + <playerName>
    print: “Player: ” + <playerName>
    print: “Score: ” + <score> + “ points”
    print: <playerName> + “ has ” + <health> + “ health”

    math: max <score>, 50
    str: upper <playerName>
    myCustomLib: process <score>, <health>

    */- This is a block comment
    spanning multiple lines
    and it should be preserved /-*

    print: “Debug: ” + (5 + 3) × 2
    print: “Mixed: ” + (<score> + 10) + “ total”

onUpdate<elapsed>:
    if <health> > 0 then
        change <health> to <health> − 0.1
        print: “Health decreasing: ” + <health>
    else if <health> ≤ 0 then
        print: “Game Over”
    else
        print: “Unknown state”

    for <i> = 0, 3 do
        print: “Loop iteration: ” + <i>

    while <score> > 0 do
        change <score> to <score> − 10
        print: “Score: ” + <score>";

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