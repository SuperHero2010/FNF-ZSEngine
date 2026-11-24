class DebugTranspiler {
    public static function main() {
        var testScript = 
"! ZS-LUA

local <startCheck> = false

onStartCountdown:
    if <isStoryMode> then
        if not <startCheck> then
            run timer “startVid” time 0.1
            halt

onTimerCompleted<tag>:
    if <isStoryMode> then
        if <tag> == “startVid” then
            <startCheck> = true
            start video “Cutscene 1” with false";

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
                trace("  Directive found at line " + (i + 1));
                break;
            }
        }
        if (!directiveFound) trace("  Directive NOT found!");
        trace("");

        trace("Step 2: Running full transpilation...");
        var result = ZSTranspiler.transpile(testScript);

        if (result != null) {
            trace(" Transpilation successful!");
            trace("");
            trace("=== OUTPUT ===");
            trace("\n" + result);
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