class DebugTranspiler {
    public static function main() {
        var testScript = 
"! ZS-LUA

onCreate:
    start countdown
    close song
    read songPosition

    restart song with false
    exit song with false

    local <skipTransition> = false

    restart song with <skipTransition>
    exit song with <skipTransition>

    load song
    load song “song”
    load song “song” with difficulty 1

    trigger event “event” with value “value1” and “value2”

    start dialogue “file” with “music”

    start dialogue “file”

    start video “file”

    start video “file” with true
    start video “file” with true, false
    start video “file” with true, false, false
    start video “file” with true, false, false, true

    local <canSkip> = true
    local <forMidSong> = false
    local <shouldLoop> = false
    local <playOnLoad> = true

    start video “file” with <canSkip>
    start video “file” with <canSkip>, <forMidSong>
    start video “file” with <canSkip>, <forMidSong>, <shouldLoop>
    start video “file” with <canSkip>, <forMidSong>, <shouldLoop>, <playOnLoad>

    read “variable”
    read from group “variable” at 1 property “property”
    read from class “class” variable “variable”
    change “variable” to 0.5
    change in group “variable” at 1 property “property” to 0.5
    change in class “class” variable “variable” to 0.5

    read “property” with false
    read from group “variable” at 1 property “property” with false
    read from class “class” variable “variable” with false
    change “variable” to 0.5 with false
    change “variable” to 0.5 with false and false
    change in group “variable” at 1 property “property” to 0.5 with false
    change in group “variable” at 1 property “property” to 0.5 with false and false
    change in class “class” variable “variable” to 0.5 with false
    change in class “class” variable “variable” to 0.5 with false and false

    local <allowMaps> = false
    local <allowInstances> = false

    read “property” with <allowMaps>
    read from group “variable” at 1 property “property” with <allowMaps>
    read from class “class” variable “variable” with <allowMaps>
    change “variable” to 0.5 with <allowMaps>
    change “variable” to 0.5 with <allowMaps> and <allowInstances>
    change in group “variable” at 1 property “property” to 0.5 with <allowMaps>
    change in group “variable” at 1 property “property” to 0.5 with <allowMaps> and <allowInstances>
    change in class “class” variable “variable” to 0.5 with <allowMaps>
    change in class “class” variable “variable” to 0.5 with <allowMaps> and <allowInstances>

    call method “function”
    call method “function” from class “class”

    call method “function” with {}
    call method “function” from class “class” with {}

    instance argument “instanceName”
    instance argument “instanceName” with “classvar”

    create instance “variable” with “classvar”
    create instance “variable” with “classvar” and {}

    add instance to “object”

    add instance to “object” with false

    local <inFront> = false

    add instance to “object” with <inFront>

    read order of “tag”
    read order of “tag” with “group”

    change in order of “tag” to 1
    change in order of “tag” to 1 with “group”

    add “tag” to “group”
    add “tag” to “group” at 1

    remove from “group”
    remove at 1 from “group”
    remove at 1 with “tag” from “group”
    remove at 1 with “tag” from “group” with true

    local <destroy> = true
    remove at 1 with “tag” from “group” with <destroy>

    change object camera “tag”
    change object camera “tag” to “camera”

    change scroll factor of “tag” to 1 and 3

    scale “tag” with 1 and 3

    scale “tag” by pixel with 1
    scale “tag” by pixel with 1 and 3

    scale “tag” with 1 and 3 with true
    scale “tag” by pixel with 1 and 3 with true

    local <updateHitbox> = true
    scale “tag” with 1 and 3 with <updateHitbox>
    scale “tag” by pixel with 1 and 3 with <updateHitbox>

    update hitbox of “tag”

    change “tag” to blend “blend”

    read midPoint x of “tag”
    read midPoint y of “tag”

    read graphic midPoint x of “tag”
    read graphic midPoint y of “tag”

    read position x of “tag” by “camera”
    read position y of “tag” by “camera”

    read pixel of “tag” with 1 and 3

    overlap “object1” and “object2”

    play sound “sound”
    play sound “sound” with volume 1
    play sound “sound” with volume 1 name “tag”
    play sound “sound” with volume 1 name “tag” with false
    play music “music”
    play music “music” with volume 1
    play music “music” with volume 1 with false

    local <loop> = false
    play sound “sound” with volume 1 name “tag” with <loop>
    play music “music” with volume 1 with <loop>

    fade in “tag” duration 1
    fade in “tag” duration 1 from 0
    fade in “tag” duration 1 from 0 to 1

    fade out “tag” duration 1
    fade out “tag” duration 1 to 0

    cancel fade “tag”

    stop sound “tag”
    pause sound “tag”
    resume sound “tag”

    read volume of sound “tag”
    read time of sound “tag”
    read pitch of sound “tag”

    change volume of sound “tag” to 1
    change time of sound “tag” to 1
    change pitch of sound “tag” to 1

    change pitch of sound “tag” to 1 with false

    local <doPause> = false
    change pitch of sound “tag” to 1 with <doPause>

    register shader <shader>

    apply shader <shader> to “sprite”

    remove shader from “sprite”

    read shader(float) “sprite” uniform “prop”
    read shader(floatArray) “sprite” uniform “prop”
    read shader(int) “sprite” uniform “prop”
    read shader(intArray) “sprite” uniform “prop”
    read shader(bool) “sprite” uniform “prop”
    read shader(boolArray) “sprite” uniform “prop”

    change shader(float) “sprite” uniform “prop” to 2
    change shader(floatArray) “sprite” uniform “prop” to 2
    change shader(int) “sprite” uniform “prop” to 2
    change shader(intArray) “sprite” uniform “prop” to 2
    change shader(bool) “sprite” uniform “prop” to 2
    change shader(boolArray) “sprite” uniform “prop” to 2

    change shader(sampler2D) “sprite” uniform “prop” path “image”

    change <healthBar> color to “left” and “right”
    change <timeBar> color to “left” and “right”

    center “tag”
    center “tag” on <axis>

    create sprite <tag>
    create sprite <tag> path “image”
    create sprite <tag> path “image” with position 1
    create sprite <tag> path “image” with position 1 and 3

    create animated sprite <tag>
    create animated sprite <tag> path “image”
    create animated sprite <tag> path “image” with position 1
    create animated sprite <tag> path “image” with position 1 and 3
    create animated sprite <tag> path “image” with position 1 and 3 type “type”

    create graphic <tag>
    create graphic <tag> with size 1
    create graphic <tag> with size 1 and 3
    create graphic <tag> with size 1 and 3 color “color”

    load graphic <tag> path “image”
    load graphic <tag> path “image” with grid 1
    load graphic <tag> path “image” with grid 1 and 3

    load frame <tag> path “image” type “type”

    load frame <tag> with {}

    add animation <tag> name “name” with frames 16
    add animation <tag> name “name” with frames 16 rate 60
    add animation <tag> name “name” with frames 16 rate 60 with false
    add animation <tag> name “name” by prefix “prefix”
    add animation <tag> name “name” by prefix “prefix” rate 60
    add animation <tag> name “name” by prefix “prefix” rate 60 with false
    add animation <tag> name “name” by indices 1 prefix “prefix”
    add animation <tag> name “name” by indices 1 prefix “prefix” rate 60
    add animation <tag> name “name” by indices 1 prefix “prefix” rate 60 with false

    local <loop> = false
    add animation <tag> name “name” with frames 16 rate 60 with <loop>
    add animation <tag> name “name” by prefix “prefix” rate 60 with <loop>
    add animation <tag> name “name” by indices 1 prefix “prefix” rate 60 with <loop>

    add offset to sprite <tag> name “name” with 1 and 3

    play animation <tag> name “name”
    play animation <tag> name “name” start 1

    play animation <tag> name “name” start 1 with false
    play animation <tag> name “name” start 1 with false and false

    local <forced> = false
    local <reverse> = false

    play animation <tag> name “name” start 1 with <forced>
    play animation <tag> name “name” start 1 with <forced> and <reverse>

    add sprite <tag>
    remove sprite <tag>
    remove sprite <tag> from “group”

    add sprite <tag> with false
    remove sprite <tag> from “group” with true

    local <inFront> = false
    local <destroy> = true

    add sprite <tag> with <inFront>
    remove sprite <tag> from “group” with <destroy>

    create text <tag>
    create text <tag> content “text”
    create text <tag> content “text” width 32
    create text <tag> content “text” width 32 position 0
    create text <tag> content “text” width 32 position 0 and 0

    add text <tag>

    remove text <tag>

    remove text <tag> with true

    local <destroy> = true
    remove text <tag> with <destroy>

    change text <tag> to content “text”

    change size of text <tag> to size 16

    change width of text <tag> to width 36
    change height of text <tag> to height 36

    change auto size of text <tag> to true

    local <value> = true
    change auto size of text <tag> to <value>

    change border of text <tag> to size 16 color “color”
    change border of text <tag> to size 16 color “color” style “style”

    change color of text <tag> to color “color”

    change font of text <tag> to font “font”

    change italic of text <tag> to true

    local <italic> = true
    change italic of text <tag> to <italic>

    change alignment of text <tag>
    change alignment of text <tag> to alignment “alignment”

    read content of text <tag>
    read size of text <tag>
    read font of text <tag>
    read width of text <tag>

    sprite <tag> exists
    text <tag> exists
    sound “tag” exists

    change scroll camera with 1 and 3

    change camera follow to point 1 and 3

    add scroll camera
    add scroll camera with 1
    add scroll camera with 1 and 3

    add camera follow point
    add camera follow point 1
    add camera follow point 3 and 1

    read camera scroll x
    read camera scroll y
    read camera follow x
    read camera follow y

    change camera to “character”

    shake camera “camera” with value 0.1 and 0.1

    flash camera “camera” with color “color” duration 1 with true
    fade camera “camera” with color “color” duration 1 with true
    fade camera “camera” with color “color” duration 1 with true and false

    local <forceReset> = true
    local <fadeOut> = false

    flash camera “camera” with color “color” duration 1 with <forceReset>
    fade camera “camera” with color “color” duration 1 with <forceReset>
    fade camera “camera” with color “color” duration 1 with <forceReset> and <fadeOut>

    mouse “left” clicked
    mouse “right” clicked
    mouse “left” pressed
    mouse “right” pressed
    mouse “left” released
    mouse “right” released

    read mouse x on “camera”
    read mouse y on “camera”

    key “button” pressed
    key “button” just pressed
    key “button” released
    keyboard “button” pressed
    keyboard “button” just pressed
    keyboard “button” released
    any gamepad “button” pressed
    any gamepad “button” just pressed
    any gamepad “button” released

    gamepad id “id” button “button” pressed
    gamepad id “id” button “button” just pressed
    gamepad id “id” button “button” released

    gamepad id “id” analog x
    gamepad id “id” analog x with true
    gamepad id “id” analog y
    gamepad id “id” analog y with true

    local <leftStick> = true
    gamepad id “id” analog x with <leftStick>
    gamepad id “id” analog y with <leftStick>

    start tween tag “twnTag” for “objTag” value {} duration 1
    start tween tag “twnTag” for “objTag” value {} duration 1 options {}

    tween x tag “twnTag” for “objTag” value {} duration 1
    tween x tag “twnTag” for “objTag” value {} duration 1 type “ease”
    tween y tag “twnTag” for “objTag” value {} duration 1
    tween y tag “twnTag” for “objTag” value {} duration 1 type “ease”
    tween angle tag “twnTag” for “objTag” value {} duration 1
    tween angle tag “twnTag” for “objTag” value {} duration 1 type “ease”
    tween alpha tag “twnTag” for “objTag” value {} duration 1
    tween alpha tag “twnTag” for “objTag” value {} duration 1 type “ease”

    tween color tag “twnTag” for “objTag” color “color” duration 1
    tween color tag “twnTag” for “objTag” color “color” duration 1 type “ease”

    tween zoom tag “twnTag” for “objTag” value {} duration 1
    tween zoom tag “twnTag” for “objTag” value {} duration 1 type “ease”

    tween x tag “twnTag” note 1 value {} duration 1
    tween x tag “twnTag” note 1 value {} duration 1 type “ease”
    tween y tag “twnTag” note 1 value {} duration 1
    tween y tag “twnTag” note 1 value {} duration 1 type “ease”
    tween angle tag “twnTag” note 1 value {} duration 1
    tween angle tag “twnTag” note 1 value {} duration 1 type “ease”
    tween alpha tag “twnTag” note 1 value {} duration 1
    tween alpha tag “twnTag” note 1 value {} duration 1 type “ease”
    tween direction tag “twnTag” note 1 value {} duration 1
    tween direction tag “twnTag” note 1 value {} duration 1 type “ease”

    cancel tween tag “twnTag”

    run timer “tmrTag”
    run timer “tmrTag” time 60
    run timer “tmrTag” time 60 loops 1

    cancel timer “tmrTag”

    add 500 to score
    add 1 to miss
    add 1 to hit
    add 0.02 to health

    change score to 100000
    change miss to 10
    change hit to 100
    change health to 1

    read health

    change rating percent to 1
    change rating name to “name”
    change rating FC to “name”

    update score text

    register save data “save”
    register save data “save” path “path”

    flush save data “save”
    erase save data “save”

    read save data “save” property “property”
    read save data “save” property “property” value 1

    change save data “save” property “property” value 1

    read running scripts

    call script “script” property “function”
    call script “script” property “function” with {}

    add Lua script “script”
    add HX script “script”

    add Lua script “script” with false
    add HX script “script” with false

    local <ignoreAlreadyRunning> = false
    add Lua script “script” with <ignoreAlreadyRunning>
    add HX script “script” with <ignoreAlreadyRunning>

    remove Lua script “script”
    remove HX script “script”

    call on scripts property “function”
    call on scripts property “function” with {}
    call on scripts property “function” with {} and {}
    call on scripts property “function” with {} and {} and {}
    call on Luas property “function”
    call on Luas property “function” with {}
    call on Luas property “function” with {} and {}
    call on Luas property “function” with {} and {} and {}
    call on HScript property “function”
    call on HScript property “function” with {}
    call on HScript property “function” with {} and {}
    call on HScript property “function” with {} and {} and {}

    call on scripts property “function” with {} and {} and {} with true
    call on scripts property “function” with {} and {} and {} with true and false
    call on Luas property “function” with {} and {} and {} with true
    call on Luas property “function” with {} and {} and {} with true and false
    call on HScript property “function” with {} and {} and {} with true
    call on HScript property “function” with {} and {} and {} with true and false

    local <ignoreSelf> = true
    local <ignoreStops> = false
    call on scripts property “function” with {} and {} and {} with <ignoreStops>
    call on scripts property “function” with {} and {} and {} with <ignoreStops> and <ignoreSelf>
    call on Luas property “function” with {} and {} and {} with <ignoreStops>
    call on Luas property “function” with {} and {} and {} with <ignoreStops> and <ignoreSelf>
    call on HScript property “function” with {} and {} and {} with <ignoreStops>
    call on HScript property “function” with {} and {} and {} with <ignoreStops> and <ignoreSelf>

    run Haxe code “code”
    run Haxe code “code” with {}
    run Haxe code “code” with {} property “function”
    run Haxe code “code” with {} and {} property “function”

    run Haxe property “function”
    run Haxe property “function” with {}

    add Haxe library “lib”
    add Haxe library “lib” package “package”

    precache image “path”
    precache sound “path”
    precache music “path”
    precache image “path” with true

    local <allowGPU> = true
    precache image “path” with <allowGPU>

    add character “character” type “type”

    change <noun> to 1

    read <noun>

    change on scripts <noun> to 1
    change on Luas <noun> to 1
    change on HScript <noun> to 1

    change on scripts <noun> to 1 with true
    change on scripts <noun> to 1 with true and {}
    change on Luas <noun> to 1 with true
    change on Luas <noun> to 1 with true and {}
    change on HScript <noun> to 1 with true
    change on HScript <noun> to 1 with true and {}

    local <ignoreSelf> = false
    local <ignoreStops> = false
    change on scripts <noun> to 1 with <ignoreSelf>
    change on scripts <noun> to 1 with <ignoreSelf> and {}
    change on Luas <noun> to 1 with <ignoreSelf>
    change on Luas <noun> to 1 with <ignoreSelf> and {}
    change on HScript <noun> to 1 with <ignoreSelf>
    change on HScript <noun> to 1 with <ignoreSelf> and {}

    close script

    create Flixel animate sprite <tag>
    create Flixel animate sprite <tag> with position 1
    create Flixel animate sprite <tag> with position 1 and 3
    create Flixel animate sprite <tag> with position 1 and 3 path “path”

    load atlas sprite <tag> path “path”
    load atlas sprite <tag> path “path” sprite path “jsonPath”
    load atlas sprite <tag> path “path” sprite path “jsonPath” animation path “jsonPath”

    add animation <tag> name “name” by symbol “symbol”
    add animation <tag> name “name” by symbol “symbol” rate 60

    add animation <tag> name “name” by symbol “symbol” rate 60 with false
    add animation <tag> name “name” by symbol “symbol” rate 60 with false matrix 1
    add animation <tag> name “name” by symbol “symbol” rate 60 with false matrix 1 and 3
    add animation <tag> name “name” by symbol “symbol” and indicies 1 rate 60 with false
    add animation <tag> name “name” by symbol “symbol” and indicies 1 rate 60 with false matrix 1
    add animation <tag> name “name” by symbol “symbol” and indicies 1 rate 60 with false matrix 1 and 3

    local <loop> = false
    add animation <tag> name “name” by symbol “symbol” rate 60 with <loop>
    add animation <tag> name “name” by symbol “symbol” rate 60 with <loop> matrix 1
    add animation <tag> name “name” by symbol “symbol” rate 60 with <loop> matrix 1 and 3
    add animation <tag> name “name” by symbol “symbol” and indicies 1 rate 60 with <loop>
    add animation <tag> name “name” by symbol “symbol” and indicies 1 rate 60 with <loop> matrix 1
    add animation <tag> name “name” by symbol “symbol” and indicies 1 rate 60 with <loop> matrix 1 and 3";

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