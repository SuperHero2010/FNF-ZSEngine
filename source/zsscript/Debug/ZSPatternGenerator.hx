package;

typedef Pattern = {
    pattern:String,
    replacement:String,
    description:String,
    category:String
}

typedef ParamDef = {
    name:String,
    type:String,
    required:Bool,
    ?defaultValue:Null<String>
}

class ZSPatternGenerator {
    public static function generateAll():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateSpecificPatterns());
        patterns = patterns.concat(generatePlayStatePatterns());
        patterns = patterns.concat(generateSpritePatterns());
        patterns = patterns.concat(generateTextPatterns());
        patterns = patterns.concat(generateSoundPatterns());
        patterns = patterns.concat(generateShaderPatterns());
        patterns = patterns.concat(generateCameraPatterns());
        patterns = patterns.concat(generateInputPatterns());
        patterns = patterns.concat(generateTweenPatterns());
        patterns = patterns.concat(generateTimerPatterns());
        patterns = patterns.concat(generateScorePatterns());
        patterns = patterns.concat(generateSaveDataPatterns());
        patterns = patterns.concat(generateScriptPatterns());
        patterns = patterns.concat(generatePrecachePatterns());
        patterns = patterns.concat(generateFlxAnimatePatterns());
        patterns = patterns.concat(generatePrintPatterns());
        patterns = patterns.concat(generateIfExceptionPatterns());
        patterns = patterns.concat(generateReflectionPatterns());
        patterns = patterns.concat(generateNestedPatterns());
        patterns = patterns.concat(generateFallbackPatterns());

        return patterns;
    }

    static function generatePlayStatePatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "restart song",
            "restartSong",
            [
                {name: "skipTransition", type: "boolean", required: false, defaultValue: "false"}
            ],
            ['with'],
            "Restart the song",
            "playstate"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "exit song",
            "exitSong",
            [
                {name: "skipTransition", type: "boolean", required: false, defaultValue: "false"}
            ],
            ['with'],
            "Exit the song",
            "playstate"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load song",
            "loadSong",
            [
                {name: "song", type: "any", required: false, defaultValue: "null"},
                {name: "difficulty", type: "any", required: false, defaultValue: "-1"}
            ],
            ['with difficulty'],
            "Load a song",
            "playstate"
        ));

        patterns.push({
            pattern: "^trigger event (.+?) with value (.+?) and (.+?)$",
            replacement: 'triggerEvent($1, $2, $3)',
            description: "Trigger an event with two values",
            category: "playstate"
        });
        patterns.push({
            pattern: "^trigger event (.+?) with value (.+?)$",
            replacement: 'triggerEvent($1, $2)',
            description: "Trigger an event with one value",
            category: "playstate"
        });
        patterns.push({
            pattern: "^trigger event (.+?)$",
            replacement: 'triggerEvent($1)',
            description: "Trigger an event with no values",
            category: "playstate"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "start dialogue",
            "startDialogue",
            [
                {name: "file", type: "any", required: true},
                {name: "music", type: "any", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Start a dialogue",
            "playstate"
        ));

        patterns = patterns.concat(generateFunctionBoolPatterns(
            "start video",
            "startVideo",
            [
                {name: "file", type: "any", required: true},
                {name: "canSkip", type: "boolean", required: false, defaultValue: "true"},
                {name: "forMidSong", type: "boolean", required: false, defaultValue: "false"},
                {name: "shouldLoop", type: "boolean", required: false, defaultValue: "false"},
                {name: "playOnLoad", type: "boolean", required: false, defaultValue: "true"}
            ],
            ['with', ',', ',', ','],
            [1, 2, 3, 4],
            [2, 3, 4],
            "Start a video",
            "playstate"
        ));

        patterns.push({
            pattern: "^change <healthBar> color to (.+?) and (.+?)$",
            replacement: "setHealthBarColors($1, $2)",
            description: "Change Health Bar Color",
            category: "playstate"
        });

        patterns.push({
            pattern: "^change <timeBar> color to (.+?) and (.+?)$",
            replacement: "setTimeBarColors($1, $2)",
            description: "Change Time Bar Color",
            category: "playstate"
        });

        return patterns;
    }

    static function generateReflectionPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "read order of",
            "getObjectOrder",
            [
                {name: "tag", type: "any", required: true},
                {name: "group", type: "any", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Read object order",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change in order of",
            "setObjectOrder",
            [
                {name: "tag", type: "any", required: true},
                {name: "position", type: "any", required: true},
                {name: "group", type: "any", required: false, defaultValue: "null"}
            ],
            ['to', 'with'],
            "Change object order",
            "reflection"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'read from group (.+?) at (.+?) property (.+?)',
            'getPropertyFromGroup($1, $2, $3',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            "Read a property from a group",
            "reflection"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'read from class (.+?) variable (.+?)',
            'getPropertyFromClass($1, $2',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            "Read a property from a class",
            "reflection"
        ));

        patterns = patterns.concat(generateTwoBoolPatterns(
            'change in group (.+?) at (.+?) property (.+?) to (.+?)',
            'setPropertyFromGroup($1, $2, $3, $4',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            {name: "allowInstances", type: "boolean", required: false, defaultValue: "false"},
            "Change a property in a group",
            "reflection"
        ));

        patterns = patterns.concat(generateTwoBoolPatterns(
            'change in class (.+?) variable (.+?) to (.+?)',
            'setPropertyFromClass($1, $2, $3',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            {name: "allowInstances", type: "boolean", required: false, defaultValue: "false"},
            "Change a property in a class",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "call method",
            "callMethod",
            [
                {name: "function", type: "anyBeforeKeyNongreedy", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Call a method",
            "reflection"
        ));

        patterns.push({
            pattern: '^call method (.+?) from class (.+?) with (.+)$',
            replacement: 'callMethodFromClass($2, $1, $3)',
            description: "Call a method from a class with args",
            category: "reflection"
        });

        patterns.push({
            pattern: '^call method (.+?) from class (.+?)$',
            replacement: 'callMethodFromClass($2, $1)',
            description: "Call a method from a class",
            category: "reflection"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "create instance",
            "createInstance",
            [
                {name: "variable", type: "any", required: true},
                {name: "class", type: "any", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['with', 'and'],
            "Create an instance",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "instance argument",
            "instanceArg",
            [
                {name: "instanceName", type: "any", required: true},
                {name: "classVar", type: "any", required: false, defaultValue: ""}
            ],
            ['with'],
            "Instance argument",
            "reflection"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'add instance to (.+)',
            'addInstance($1',
            {name: "inFront", type: "boolean", required: false, defaultValue: "false"},
            "Add an instance",
            "reflection"
        ));

        patterns.push({
            pattern: '^add (.+?) to (.+) at (.+)$',
            replacement: 'addToGroup($2, $1, $3)',
            description: "Add to group at index",
            category: "reflection"
        });

        patterns.push({
            pattern: '^add (.+?) to (.+)$',
            replacement: 'addToGroup($2, $1)',
            description: "Add to group",
            category: "reflection"
        });

        patterns.push({
            pattern: '^remove at ([^ ]+) with (.+?) from (.+) with (true|false)$',
            replacement: 'removeFromGroup($3, $1, $2, $4)',
            description: "Remove from group by index with tag and destroy",
            category: "reflection"
        });

        patterns.push({
            pattern: '^remove at ([^ ]+) with (.+?) from (.+) with <([^>]+)>$',
            replacement: 'removeFromGroup($3, $1, $2, $4)',
            description: "Remove from group by index with tag and destroy noun",
            category: "reflection"
        });

        patterns.push({
            pattern: '^remove at ([^ ]+) from (.+)$',
            replacement: 'removeFromGroup($2, $1)',
            description: "Remove from group by index",
            category: "reflection"
        });

        patterns.push({
            pattern: '^remove at ([^ ]+) with (.+?) from (.+)$',
            replacement: 'removeFromGroup($3, $1, $2)',
            description: "Remove from group by index with tag",
            category: "reflection"
        });

        patterns = patterns.concat(generateBoolPatterns(
            'remove from (.+)',
            'removeFromGroup($1',
            {name: "destroy", type: "boolean", required: false, defaultValue: "true"},
            "Remove from group",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change object camera",
            "setObjectCamera",
            [
                {name: "tag", type: "any", required: true},
                {name: "camera", type: "any", required: false, defaultValue: "game"}
            ],
            ['to'],
            "Change object camera",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change scroll factor of",
            "setScrollFactor",
            [
                {name: "tag", type: "any", required: true},
                {name: "x", type: "any", required: true},
                {name: "y", type: "any", required: true}
            ],
            ['to', 'and'],
            "Change scroll factor",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            'scale',
            'scaleObject',
            [
                {name: "tag", type: "any", required: true},
                {name: "x", type: "any", required: true},
                {name: "y", type: "any", required: true},
                {name: "updateHitbox", type: "boolean", required: false, defaultValue: "true"}
            ],
            ['with', 'and', 'with'],
            "Scale an object",
            "reflection"
        ));

        patterns.push({
            pattern: '^scale (.+?) by pixel with ([^ ]+)$',
            replacement: 'setGraphicSize($1, $2)',
            description: "Scale an object by pixel (width only)",
            category: "reflection"
        });
        patterns.push({
            pattern: '^scale (.+?) by pixel with ([^ ]+) and ([^ ]+)$',
            replacement: 'setGraphicSize($1, $2, $3)',
            description: "Scale an object by pixel",
            category: "reflection"
        });
        patterns.push({
            pattern: '^scale (.+?) by pixel with ([^ ]+) and ([^ ]+) with (true|false)$',
            replacement: 'setGraphicSize($1, $2, $3, $4)',
            description: "Scale an object by pixel with updateHitbox",
            category: "reflection"
        });
        patterns.push({
            pattern: '^scale (.+?) by pixel with ([^ ]+) and ([^ ]+) with <([^>]+)>$',
            replacement: 'setGraphicSize($1, $2, $3, $4)',
            description: "Scale an object by pixel with updateHitbox noun",
            category: "reflection"
        });

        patterns.push({
            pattern: '^update hitbox of (.+?)$',
            replacement: 'updateHitbox($1)',
            description: "Update hitbox",
            category: "reflection"
        });

        patterns.push({
            pattern: '^change (.+?) to blend (.+?)$',
            replacement: 'setBlendMode($1, $2)',
            description: "Change blend mode",
            category: "reflection"
        });

        patterns.push({
            pattern: '^read midPoint x of (.+?)$',
            replacement: 'getMidpointX($1)',
            description: "Read midpoint X",
            category: "reflection"
        });
        patterns.push({
            pattern: '^read midPoint y of (.+?)$',
            replacement: 'getMidpointY($1)',
            description: "Read midpoint Y",
            category: "reflection"
        });

        patterns.push({
            pattern: '^read graphic midPoint x of (.+?)$',
            replacement: 'getGraphicMidpointX($1)',
            description: "Read graphic midpoint X",
            category: "reflection"
        });
        patterns.push({
            pattern: '^read graphic midPoint y of (.+?)$',
            replacement: 'getGraphicMidpointY($1)',
            description: "Read graphic midpoint Y",
            category: "reflection"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "read position x of",
            "getScreenPositionX",
            [
                {name: "tag", type: "any", required: true},
                {name: "camera", type: "any", required: false, defaultValue: "game"}
            ],
            ['by'],
            "Read screen position X",
            "reflection"
        ));
        patterns = patterns.concat(generateFunctionPatterns(
            "read position y of",
            "getScreenPositionY",
            [
                {name: "tag", type: "any", required: true},
                {name: "camera", type: "any", required: false, defaultValue: "game"}
            ],
            ['by'],
            "Read screen position Y",
            "reflection"
        ));

        patterns.push({
            pattern: '^read pixel of (.+?) with (.+?) and (.+?)$',
            replacement: 'getPixelColor($1, $2, $3)',
            description: "Read pixel color",
            category: "reflection"
        });

        patterns.push({
            pattern: '^overlap (.+?) and (.+?)$',
            replacement: 'objectsOverlap($1, $2)',
            description: "Check overlap",
            category: "reflection"
        });

        patterns = patterns.concat(generateBoolPatterns(
            "read (.+?)",
            'getProperty($1',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            "Read a property",
            "reflection"
        ));

        patterns = patterns.concat(generateTwoBoolPatterns(
            'change (.+?) to (.+)',
            'setProperty($1, $2',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            {name: "allowInstances", type: "boolean", required: false, defaultValue: "false"},
            "Change a property",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            'center',
            'screenCenter',
            [
                {name: "tag", type: "any", required: true},
                {name: "axis", type: "any", required: false}
            ],
            ['on'],
            'Centers an Object to the Screen on the specified axis',
            'reflection'
        ));

        return patterns;
    }

    static function generateSpritePatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "create sprite",
            "makeLuaSprite",
            [
                {name: "tag", type: "any", required: true},
                {name: "image", type: "any", required: false, defaultValue: "null"},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"}
            ],
            ['path', 'with position', 'and'],
            "Create a sprite",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "create animated sprite",
            "makeAnimatedLuaSprite",
            [
                {name: "tag", type: "any", required: true},
                {name: "image", type: "any", required: false, defaultValue: "null"},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"},
                {name: "type", type: "any", required: false, defaultValue: "auto"}
            ],
            ['path', 'with position', 'and', 'type'],
            "Create an animated sprite",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "create graphic",
            "makeGraphic",
            [
                {name: "tag", type: "any", required: true},
                {name: "width", type: "any", required: false, defaultValue: "256"},
                {name: "height", type: "any", required: false, defaultValue: "256"},
                {name: "color", type: "any", required: false, defaultValue: "FFFFFF"}
            ],
            ['with size', 'and', 'color'],
            "Create a graphic",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load graphic",
            "loadGraphic",
            [
                {name: "tag", type: "any", required: true},
                {name: "image", type: "any", required: true},
                {name: "gridX", type: "any", required: false, defaultValue: "0"},
                {name: "gridY", type: "any", required: false, defaultValue: "0"}
            ],
            ['path', 'with grid', 'and'],
            "Load a graphic",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load frame",
            "loadFrames",
            [
                {name: "tag", type: "any", required: true},
                {name: "image", type: "any", required: true},
                {name: "type", type: "any", required: false, defaultValue: "auto"}
            ],
            ['path', 'type'],
            "Load frames",
            "sprites"
        ));

        patterns.push({
            pattern: '^load frame (.+?) with ({[^}]*})$',
            replacement: 'loadMultipleFrames($1, $2)',
            description: "Load multiple frames",
            category: "sprites"
        });

        var animPatterns = generateAnimationPatterns();
        patterns = patterns.concat(animPatterns);

        patterns.push({
            pattern: '^add offset to sprite (.+?) name (.+?) with (.+?) and (.+?)$',
            replacement: 'addOffset($1, $2, $3, $4)',
            description: "Add animation offset",
            category: "sprites"
        });

        patterns = patterns.concat(generatePlayAnimationPatterns());

        patterns = patterns.concat(generateBoolPatterns(
            'add sprite (.+?)',
            'addLuaSprite($1',
            {name: "inFront", type: "boolean", required: false, defaultValue: "false"},
            "Add a sprite",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "remove sprite",
            "removeLuaSprite",
            [
                {name: "tag", type: "any", required: true},
                {name: "group", type: "any", required: false, defaultValue: "null"},
                {name: "destroy", type: "boolean", required: false, defaultValue: "true"}
            ],
            ['from', 'with'],
            "Remove a sprite from a group",
            "sprites"
        ));

        return patterns;
    }

    static function generateAnimationPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: 'add animation (.+?) name (.+?) with frames ([^ ]+) rate ([^ ]+) with (true|false)',
            replacement: 'addAnimation($1, $2, $3, $4, $5)',
            description: "Add animation with boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: 'add animation (.+?) name (.+?) with frames ([^ ]+) rate ([^ ]+) with <([^>]+)>',
            replacement: 'addAnimation($1, $2, $3, $4, $5)',
            description: "Add animation with noun as boolean",
            category: "sprites"
        });

        patterns.push({
            pattern: 'add animation (.+?) name (.+?) by prefix “([^”]*)” rate ([^ ]+) with (true|false)',
            replacement: 'addAnimationByPrefix($1, $2, "$3", $4, $5)',
            description: "Add animation by prefix with boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: 'add animation (.+?) name (.+?) by prefix “([^”]*)” rate ([^ ]+) with <([^>]+)>',
            replacement: 'addAnimationByPrefix($1, $2, "$3", $4, $5)',
            description: "Add animation by prefix with noun as boolean",
            category: "sprites"
        });

        patterns.push({
            pattern: 'add animation (.+?) name (.+?) by indices (.+?) prefix “([^”]*)” rate ([^ ]+) with (true|false)',
            replacement: 'addAnimationByIndices($1, $2, "$4", $3, $5, $6)',
            description: "Add animation by indices with boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: 'add animation (.+?) name (.+?) by indices (.+?) prefix “([^”]*)” rate ([^ ]+) with <([^>]+)>',
            replacement: 'addAnimationByIndices($1, $2, "$4", $3, $5, $6)',
            description: "Add animation by indices with noun as boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: 'add animation (.+?) name (.+?) by indices (.+?) prefix “([^”]*)” rate ([^ ]+)',
            replacement: 'addAnimationByIndices($1, $2, "$4", $3, $5)',
            description: "Add animation by indices with framerate",
            category: "sprites"
        });
        patterns.push({
            pattern: 'add animation (.+?) name (.+?) by indices (.+?) prefix “([^”]*)”',
            replacement: 'addAnimationByIndices($1, $2, "$4", $3)',
            description: "Add animation by indices",
            category: "sprites"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            'add animation',
            'addAnimation',
            [
                {name: "tag", type: "any", required: true},
                {name: "name", type: "any", required: true},
                {name: "frames", type: "any", required: true},
                {name: "rate", type: "any", required: false, defaultValue: "24"}
            ],
            ['name', 'with frames', 'rate'],
            "Add animation with frames",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            'add animation',
            'addAnimationByPrefix',
            [
                {name: "tag", type: "any", required: true},
                {name: "name", type: "any", required: true},
                {name: "prefix", type: "any", required: true},
                {name: "rate", type: "any", required: false, defaultValue: "24"}
            ],
            ['name', 'by prefix', 'rate'],
            "Add animation by prefix",
            "sprites"
        ));

        return patterns;
    }

    static function generatePlayAnimationPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+) with <([^>]+)> and (true|false)$",
            replacement: "playAnim($1, $2, $4, $5, $3)",
            description: "Play animation with boolean and noun boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+) with (true|false) and <([^>]+)>$",
            replacement: "playAnim($1, $2, $4, $5, $3)",
            description: "Play animation with noun as boolean and boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+) with (true|false) and (true|false)$",
            replacement: "playAnim($1, $2, $4, $5, $3)",
            description: "Play animation with boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+) with <([^>]+)> and <([^>]+)>$",
            replacement: "playAnim($1, $2, $4, $5, $3)",
            description: "Play animation with noun as boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+) with (true|false)$",
            replacement: "playAnim($1, $2, $4, $3)",
            description: "Play animation with one boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+) with <([^>]+)>$",
            replacement: "playAnim($1, $2, $4, $3)",
            description: "Play animation with one noun as boolean",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?) start ([^ ]+)$",
            replacement: "playAnim($1, $2, false, false, $3)",
            description: "Play animation start at specific frame",
            category: "sprites"
        });
        patterns.push({
            pattern: "^play animation (.+?) name (.+?)$",
            replacement: "playAnim($1, $2)",
            description: "Play animation",
            category: "sprites"
        });

        return patterns;
    }

    static function generateTextPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "create text",
            "makeLuaText",
            [
                {name: "tag", type: "any", required: true},
                {name: "content", type: "any", required: false, defaultValue: "''"},
                {name: "width", type: "any", required: false, defaultValue: "0"},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"}
            ],
            ['content', 'width', 'position', 'and'],
            "Create text",
            "text"
        ));

        patterns.push({
            pattern: '^add text (.+?)$',
            replacement: 'addLuaText($1)',
            description: "Add text",
            category: "text"
        });

        patterns = patterns.concat(generateBoolPatterns(
            'remove text (.+?)',
            'removeLuaText($1',
            {name: "destroy", type: "boolean", required: false, defaultValue: "true"},
            "Remove text",
            "text"
        ));

        patterns.push({
            pattern: '^change text (.+?) to content (.+?)$',
            replacement: 'setTextString($1, $2)',
            description: "Change text content",
            category: "text"
        });

        patterns.push({
            pattern: '^change size of text (.+?) to size (.+?)$',
            replacement: 'setTextSize($1, $2)',
            description: "Change text size",
            category: "text"
        });

        patterns.push({
            pattern: '^change width of text (.+?) to width (.+?)$',
            replacement: 'setTextWidth($1, $2)',
            description: "Change text width",
            category: "text"
        });
        patterns.push({
            pattern: '^change height of text (.+?) to height (.+?)$',
            replacement: 'setTextHeight($1, $2)',
            description: "Change text height",
            category: "text"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            'change border of text',
            'setTextBorder',
            [
                {name: "tag", type: "any", required: true},
                {name: "size", type: "any", required: true},
                {name: "color", type: "any", required: true},
                {name: "style", type: "any", required: false, defaultValue: "outline"}
            ],
            ['to size', 'color', 'style'],
            "Change border of text",
            "text"
        ));

        patterns.push({
            pattern: '^change auto size of text (.+?) to (true|false)$',
            replacement: 'setTextAutoSize($1, $2)',
            description: "Change Auto Size of text with boolean",
            category: "text"
        });
        patterns.push({
            pattern: '^change auto size of text (.+?) to <([^>]+)>$',
            replacement: 'setTextAutoSize($1, $2)',
            description: "Change Auto Size of text with noun as boolean",
            category: "text"
        });

        patterns.push({
            pattern: '^change color of text (.+?) to color (.+?)$',
            replacement: 'setTextColor($1, $2)',
            description: "Change text color",
            category: "text"
        });

        patterns.push({
            pattern: '^change font of text (.+?) to font (.+?)$',
            replacement: 'setTextFont($1, $2)',
            description: "Change text font",
            category: "text"
        });

        patterns.push({
            pattern: '^change italic of text (.+?) to (true|false)$',
            replacement: 'setTextItalic($1, $2)',
            description: "Change italic of text with boolean",
            category: "text"
        });
        patterns.push({
            pattern: '^change italic of text (.+?) to <([^>]+)>$',
            replacement: 'setTextItalic($1, $2)',
            description: "Change italic of text with noun as boolean",
            category: "text"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "change alignment of text",
            "setTextAlignment",
            [
                {name: "tag", type: "any", required: true},
                {name: "alignment", type: "any", required: false, defaultValue: "left"}
            ],
            ['to alignment'],
            "Change text alignment",
            "text"
        ));

        patterns.push({
            pattern: '^read content of text (.+?)$',
            replacement: 'getTextString($1)',
            description: "Read text content",
            category: "text"
        });
        patterns.push({
            pattern: '^read size of text (.+?)$',
            replacement: 'getTextSize($1)',
            description: "Read text size",
            category: "text"
        });
        patterns.push({
            pattern: '^read font of text (.+?)$',
            replacement: 'getTextFont($1)',
            description: "Read text font",
            category: "text"
        });
        patterns.push({
            pattern: '^read width of text (.+?)$',
            replacement: 'getTextWidth($1)',
            description: "Read text width",
            category: "text"
        });

        return patterns;
    }

    static function generateSoundPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "play sound",
            "playSound",
            [
                {name: "sound", type: "any", required: true},
                {name: "volume", type: "any", required: false, defaultValue: "1"},
                {name: "tag", type: "any", required: false, defaultValue: "null"},
                {name: "loop", type: "boolean", required: false, defaultValue: "false"}
            ],
            ['with volume', 'name', 'with'],
            "Play a sound",
            "sound"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "play music",
            "playMusic",
            [
                {name: "music", type: "any", required: true},
                {name: "volume", type: "any", required: false, defaultValue: "1"},
                {name: "loop", type: "boolean", required: false, defaultValue: "false"}
            ],
            ['with volume', 'with'],
            "Play music",
            "sound"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "fade in",
            "soundFadeIn",
            [
                {name: "tag", type: "any", required: true},
                {name: "duration", type: "any", required: true},
                {name: "fromValue", type: "any", required: false, defaultValue: "0"},
                {name: "toValue", type: "any", required: false, defaultValue: "1"}
            ],
            ['duration', 'from', 'to'],
            "Fade in sound",
            "sound"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "fade out",
            "soundFadeOut",
            [
                {name: "tag", type: "any", required: true},
                {name: "duration", type: "any", required: true},
                {name: "toValue", type: "any", required: false, defaultValue: "0"}
            ],
            ['duration', 'to'],
            "Fade out sound",
            "sound"
        ));

        patterns.push({
            pattern: '^cancel fade (.+?)$',
            replacement: 'soundFadeCancel($1)',
            description: "Cancel sound fade",
            category: "sound"
        });

        patterns.push({
            pattern: '^stop sound (.+?)$',
            replacement: 'stopSound($1)',
            description: "Stop sound",
            category: "sound"
        });
        patterns.push({
            pattern: '^pause sound (.+?)$',
            replacement: 'pauseSound($1)',
            description: "Pause sound",
            category: "sound"
        });
        patterns.push({
            pattern: '^resume sound (.+?)$',
            replacement: 'resumeSound($1)',
            description: "Resume sound",
            category: "sound"
        });

        patterns.push({
            pattern: '^read volume of sound (.+?)$',
            replacement: 'getSoundVolume($1)',
            description: "Read sound volume",
            category: "sound"
        });
        patterns.push({
            pattern: '^read time of sound (.+?)$',
            replacement: 'getSoundTime($1)',
            description: "Read sound time",
            category: "sound"
        });
        patterns.push({
            pattern: '^read pitch of sound (.+?)$',
            replacement: 'getSoundPitch($1)',
            description: "Read sound pitch",
            category: "sound"
        });

        patterns.push({
            pattern: '^change volume of sound (.+?) to (.+?)$',
            replacement: 'setSoundVolume($1, $2)',
            description: "Change sound volume",
            category: "sound"
        });
        patterns.push({
            pattern: '^change time of sound (.+?) to (.+?)$',
            replacement: 'setSoundTime($1, $2)',
            description: "Change sound time",
            category: "sound"
        });
        patterns = patterns.concat(generateBoolPatterns(
            'change pitch of sound (.+?) to (.+?)',
            'setSoundPitch($1, $2',
            {name: "doPause", type: "boolean", required: false, defaultValue: "false"},
            "Change sound pitch",
            "sound"
        ));

        return patterns;
    }

    static function generateShaderPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: '^register shader (.+?)$',
            replacement: 'initLuaShader($1)',
            description: "Initialize a shader",
            category: "shaders"
        });

        patterns.push({
            pattern: '^apply shader (.+?) to (.+?)$',
            replacement: 'setSpriteShader($2, $1)',
            description: "Apply shader to sprite",
            category: "shaders"
        });

        patterns.push({
            pattern: '^remove shader from (.+?)$',
            replacement: 'removeSpriteShader($1)',
            description: "Remove shader from sprite",
            category: "shaders"
        });

        var shaderTypes = ["float", "floatArray", "int", "intArray", "bool", "boolArray"];
        for (type in shaderTypes) {
            patterns.push({
                pattern: '^read shader\\($type\\) (.+?) uniform (.+?)$',
                replacement: 'getShader' + (type.charAt(0).toUpperCase() + type.substr(1)) + '($1, $2)',
                description: 'Read shader ' + type,
                category: "shaders"
            });
        }

        for (type in shaderTypes) {
            patterns.push({
                pattern: '^change shader\\($type\\) (.+?) uniform (.+?) to (.+?)$',
                replacement: 'setShader' + (type.charAt(0).toUpperCase() + type.substr(1)) + '($1, $2, $3)',
                description: 'Change shader ' + type,
                category: "shaders"
            });
        }

        patterns.push({
            pattern: '^change shader\\(sampler2D\\) (.+?) uniform (.+?) path (.+?)$',
            replacement: 'setShaderSampler2D($1, $2, $3)',
            description: "Change shader sampler2D",
            category: "shaders"
        });

        return patterns;
    }

    static function generateCameraPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: 'change scroll camera with (.+?) and (.+?)',
            replacement: 'setCameraScroll($1, $2)',
            description: "Change camera scroll",
            category: "camera"
        });
        patterns.push({
            pattern: 'change camera follow to point (.+?) and (.+?)',
            replacement: 'setCameraFollowPoint($1, $2)',
            description: "Change camera follow point",
            category: "camera"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "add scroll camera with",
            "addCameraScroll",
            [
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"}
            ],
            ['and'],
            "Add camera scroll",
            "camera"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "add camera follow point",
            "addCameraFollowPoint",
            [
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"}
            ],
            ['and'],
            "Add camera follow point",
            "camera"
        ));

        patterns.push({
            pattern: 'add scroll camera',
            replacement: 'addCameraScroll()',
            description: "Add camera scroll without value",
            category: "camera"
        });
        patterns.push({
            pattern: 'add camera follow point',
            replacement: 'addCameraScroll()',
            description: "Add camera follow point without value",
            category: "camera"
        });

        patterns.push({
            pattern: '^read camera scroll x$',
            replacement: 'getCameraScrollX()',
            description: "Read camera scroll X",
            category: "camera"
        });
        patterns.push({
            pattern: '^read camera scroll y$',
            replacement: 'getCameraScrollY()',
            description: "Read camera scroll Y",
            category: "camera"
        });
        patterns.push({
            pattern: '^read camera follow x$',
            replacement: 'getCameraFollowX()',
            description: "Read camera follow X",
            category: "camera"
        });
        patterns.push({
            pattern: '^read camera follow y$',
            replacement: 'getCameraFollowY()',
            description: "Read camera follow Y",
            category: "camera"
        });

        patterns.push({
            pattern: '^change camera to (.+?)$',
            replacement: 'cameraSetTarget($1)',
            description: "Change camera target",
            category: "camera"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "shake camera",
            "cameraShake",
            [
                {name: "camera", type: "any", required: true},
                {name: "intensity", type: "any", required: true},
                {name: "duration", type: "any", required: true}
            ],
            ['with value', 'and'],
            "Shake camera",
            "camera"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'flash camera (.+?) with color (.+?) duration (.+?)',
            'cameraFlash($1, $2, $3',
            {name: "forceReset", type: "boolean", required: false, defaultValue: "true"},
            "Flash camera",
            "camera"
        ));

        patterns = patterns.concat(generateTwoBoolPatterns(
            'fade camera (.+?) with color (.+?) duration (.+?)',
            'cameraFade($1, $2, $3',
            {name: "forceReset", type: "boolean", required: false, defaultValue: "true"},
            {name: "fadeOut", type: "boolean", required: false, defaultValue: "false"},
            "Fade camera",
            "camera"
        ));

        return patterns;
    }

    static function generateInputPatterns():Array<Pattern> {
        var patterns = [];

        var mouseButtons = ["“left”", "“right”"];
        var mouseActions = ["clicked", "pressed", "released"];
        for (button in mouseButtons) {
            for (action in mouseActions) {
                patterns.push({
                    pattern: '^mouse ' + button + ' ' + action + '$',
                    replacement: 'mouse' + (action.charAt(0).toUpperCase() + action.substr(1)) + '(' + button + ')',
                    description: 'Mouse ' + button + ' ' + action,
                    category: "input"
                });
            }
        }

        patterns.push({
            pattern: '^read mouse x$',
            replacement: 'getMouseX()',
            description: "Read mouse X",
            category: "input"
        });
        patterns.push({
            pattern: '^read mouse y$',
            replacement: 'getMouseY()',
            description: "Read mouse Y",
            category: "input"
        });
        patterns = patterns.concat(generateFunctionPatterns(
            "read mouse x on",
            "getMouseX",
            [
                {name: "camera", type: "any", required: false, defaultValue: "game"}
            ],
            [],
            "Read mouse X on camera",
            "input"
        ));
        patterns = patterns.concat(generateFunctionPatterns(
            "read mouse y on",
            "getMouseY",
            [
                {name: "camera", type: "any", required: false, defaultValue: "game"}
            ],
            [],
            "Read mouse Y on camera",
            "input"
        ));

        var keyTypes = ["key", "keyboard", "any gamepad"];
        var keyActions = [ "just pressed", "pressed", "released"];
        for (type in keyTypes) {
            for (action in keyActions) {
                var funcName = "";
                if (type == "key") funcName = "key" + (action == "just pressed" ? "JustPressed" : (action == "pressed" ? "Pressed" : "Released"));
                else if (type == "keyboard") funcName = "keyboard" + (action == "just pressed" ? "JustPressed" : (action == "pressed" ? "Pressed" : "Released"));
                else funcName = "anyGamepad" + (action == "just pressed" ? "JustPressed" : (action == "pressed" ? "Pressed" : "Released"));
                patterns.push({
                    pattern: '^' + type + ' (.+) ' + action + '$',
                    replacement: funcName + '($1)',
                    description: type + ' ' + action,
                    category: "input"
                });
            }
        }

        patterns.push({
            pattern: '^gamepad id (.+?) button (.+?) just pressed$',
            replacement: 'gamepadJustPressed($1, $2)',
            description: "Gamepad just pressed",
            category: "input"
        });
        patterns.push({
            pattern: '^gamepad id (.+?) button (.+?) pressed$',
            replacement: 'gamepadPressed($1, $2)',
            description: "Gamepad pressed",
            category: "input"
        });
        patterns.push({
            pattern: '^gamepad id (.+?) button (.+?) released$',
            replacement: 'gamepadReleased($1, $2)',
            description: "Gamepad released",
            category: "input"
        });

        patterns = patterns.concat(generateBoolPatterns(
            'gamepad id (.+?) analog x',
            'gamepadAnalogX($1',
            {name: "leftStick", type: "boolean", required: false, defaultValue: "true"},
            "Gamepad analog X",
            "input"
        ));
        patterns = patterns.concat(generateBoolPatterns(
            'gamepad id (.+?) analog y',
            'gamepadAnalogY($1',
            {name: "leftStick", type: "boolean", required: false, defaultValue: "true"},
            "Gamepad analog Y",
            "input"
        ));

        return patterns;
    }

    static function generateTweenPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "start tween tag",
            "startTween",
            [
                {name: "twnTag", type: "anyBeforeKeyNongreedy", required: true},
                {name: "objTag", type: "anyBeforeKeyNongreedy", required: true},
                {name: "value", type: "anyBeforeKeyNongreedy", required: true},
                {name: "duration", type: "anyBeforeKeyNongreedy", required: true},
                {name: "options", type: "table", required: false, defaultValue: "null"}
            ],
            ['for', 'value', 'duration', 'options'],
            "Start a tween",
            "tween"
        ));

        var tweenTypes = ["x", "y", "angle", "alpha"];
        for (type in tweenTypes) {
            patterns = patterns.concat(generateFunctionPatterns(
                "tween " + type + " tag",
                "doTween" + (type.charAt(0).toUpperCase() + type.substr(1)),
                [
                    {name: "twnTag", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "objTag", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "value", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "duration", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "ease", type: "any", required: false, defaultValue: "linear"}
                ],
                ['for', 'value', 'duration', 'type'],
                "Tween " + type,
                "tween"
            ));
        }

        patterns = patterns.concat(generateFunctionPatterns(
            "tween color tag",
            "doTweenColor",
            [
                {name: "twnTag", type: "anyBeforeKeyNongreedy", required: true},
                {name: "objTag", type: "anyBeforeKeyNongreedy", required: true},
                {name: "color", type: "anyBeforeKeyNongreedy", required: true},
                {name: "duration", type: "anyBeforeKeyNongreedy", required: true},
                {name: "ease", type: "any", required: false, defaultValue: "linear"}
            ],
            ['for', 'color', 'duration', 'type'],
            "Tween color",
            "tween"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "tween zoom tag",
            "doTweenZoom",
            [
                {name: "twnTag", type: "anyBeforeKeyNongreedy", required: true},
                {name: "camera", type: "anyBeforeKeyNongreedy", required: true},
                {name: "value", type: "anyBeforeKeyNongreedy", required: true},
                {name: "duration", type: "anyBeforeKeyNongreedy", required: true},
                {name: "ease", type: "any", required: false, defaultValue: "linear"}
            ],
            ['for', 'value', 'duration', 'type'],
            "Tween zoom",
            "tween"
        ));

        var noteTweenTypes = ["x", "y", "angle", "alpha", "direction"];
        for (type in noteTweenTypes) {
            patterns = patterns.concat(generateFunctionPatterns(
                "tween " + type + " tag",
                "noteTween" + (type.charAt(0).toUpperCase() + type.substr(1)),
                [
                    {name: "twnTag", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "note", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "value", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "duration", type: "anyBeforeKeyNongreedy", required: true},
                    {name: "ease", type: "any", required: false, defaultValue: "linear"}
                ],
                ['note', 'value', 'duration', 'type'],
                "Tween note " + type,
                "tween"
            ));
        }

        patterns.push({
            pattern: '^cancel tween tag (.+)$',
            replacement: 'cancelTween($1)',
            description: "Cancel tween",
            category: "tween"
        });

        return patterns;
    }

    static function generateTimerPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "run timer",
            "runTimer",
            [
                {name: "tmrTag", type: "any", required: true},
                {name: "time", type: "any", required: false, defaultValue: "1.0"},
                {name: "loops", type: "any", required: false, defaultValue: "1"}
            ],
            ['time', 'loops'],
            "Run a timer",
            "timer"
        ));

        patterns.push({
            pattern: '^cancel timer (.+)$',
            replacement: 'cancelTimer($1)',
            description: "Cancel timer",
            category: "timer"
        });

        return patterns;
    }

    static function generateScorePatterns():Array<Pattern> {
        var patterns = [];
        var scoreTypes = ["score", "miss", "hit", "health"];

        for (type in scoreTypes) {
            patterns.push({
                pattern: '^add (.+?) to ' + type + '$',
                replacement: 'add' + (type.charAt(0).toUpperCase() + type.substr(1)) + '($1)',
                description: 'Add to ' + type,
                category: "score"
            });
            patterns.push({
                pattern: '^change ' + type + ' to (.+?)$',
                replacement: 'set' + (type.charAt(0).toUpperCase() + type.substr(1)) + '($1)',
                description: 'Set ' + type,
                category: "score"
            });
        }

        patterns.push({
            pattern: '^change rating percent to (.+?)$',
            replacement: 'setRatingPercent($1)',
            description: "Change rating percent",
            category: "score"
        });
        patterns.push({
            pattern: '^change rating name to (.+?)$',
            replacement: 'setRatingName($1)',
            description: "Change rating name",
            category: "score"
        });
        patterns.push({
            pattern: '^change rating FC to (.+?)$',
            replacement: 'setRatingFC($1)',
            description: "Change rating FC",
            category: "score"
        });

        return patterns;
    }

    static function generateSaveDataPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "register save data",
            "initSaveData",
            [
                {name: "save", type: "any", required: true},
                {name: "path", type: "any", required: false, defaultValue: "psychenginemods"}
            ],
            ['path'],
            "Register save data",
            "savedata"
        ));

        patterns.push({
            pattern: '^flush save data (.+)$',
            replacement: 'flushSaveData($1)',
            description: "Flush save data",
            category: "savedata"
        });
        patterns.push({
            pattern: '^erase save data (.+)$',
            replacement: 'eraseSaveData($1)',
            description: "Erase save data",
            category: "savedata"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "read save data",
            "getDataFromSave",
            [
                {name: "save", type: "any", required: true},
                {name: "property", type: "any", required: true},
                {name: "value", type: "any", required: false, defaultValue: "null"}
            ],
            ['property', 'value'],
            "Read save data",
            "savedata"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change save data",
            "setDataFromSave",
            [
                {name: "save", type: "any", required: true},
                {name: "property", type: "any", required: true},
                {name: "value", type: "any", required: true}
            ],
            ['property', 'value'],
            "Change save data",
            "savedata"
        ));

        return patterns;
    }

    static function generateScriptPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: '^read running scripts$',
            replacement: 'getRunningScripts()',
            description: "Read running scripts",
            category: "script"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "call script",
            "callScript",
            [
                {name: "script", type: "any", required: true},
                {name: "function", type: "any", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['property', 'with'],
            "Call script",
            "script"
        ));

        var scriptTypes = ["Lua", "HX", "ZS"];
        for (type in scriptTypes) {
            var funcName = "add" + (type == "HX" ? "HScript" : (type == "ZS" ? "ZSScript" : "LuaScript"));
            patterns = patterns.concat(generateBoolPatterns(
                'add ' + type + ' script “(.+?)”',
                funcName + '($1',
                {name: "ignoreAlreadyRunning", type: "boolean", required: false, defaultValue: "false"},
                "Add " + type + " script",
                "script"
            ));
        }

        for (type in scriptTypes) {
            var funcName = "remove" + (type == "HX" ? "HScript" : (type == "ZS" ? "ZSScript" : "LuaScript"));
            patterns.push({
                pattern: '^remove ' + type + ' script “(.+?)”$',
                replacement: funcName + '($1)',
                description: "Remove " + type + " script",
                category: "script"
            });
        }

        var callTypes = ["scripts", "Luas", "HScript", "ZS"];
        for (type in callTypes) {
            var funcName = "callOn" + (type == "scripts" ? "Scripts" : (type == "Luas" ? "Luas" : (type == "HScript" ? "HScript" : "ZSScripts")));
            var basePattern = '^call on ' + type + ' property “(.+?)”';
            var baseReplacement = funcName + '($1';

            patterns.push({
                pattern: basePattern + '$',
                replacement: baseReplacement + ')',
                description: "Call on " + type,
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)}$',
                replacement: baseReplacement + ', {$2})',
                description: "Call on " + type + " with args",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)}$',
                replacement: baseReplacement + ', {$2}, {$3})',
                description: "Call on " + type + " with args",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)}$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4})',
                description: "Call on " + type + " with tables",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with (true|false)$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5)',
                description: "Call on " + type + " with tables and direct boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with <([^>]+)>$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5)',
                description: "Call on " + type + " with tables and noun boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with (true|false) and (true|false)$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6)',
                description: "Call on " + type + " with tables and two direct booleans",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with <([^>]+)> and <([^>]+)>$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6)',
                description: "Call on " + type + " with tables and two noun booleans",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with (true|false) and <([^>]+)>$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6)',
                description: "Call on " + type + " with tables and mixed booleans",
                category: "script"
            });
            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with <([^>]+)> and (true|false)$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6)',
                description: "Call on " + type + " with tables and mixed booleans",
                category: "script"
            });
        }

        var changeTypes = ["scripts", "Luas", "HScript", "ZS"];
        for (type in changeTypes) {
            var funcName = "setOn" + (type == "scripts" ? "Scripts" : (type == "Luas" ? "Luas" : (type == "HScript" ? "HScript" : "ZSScripts")));
            var basePattern = '^change on ' + type + ' <([^>]+)> to ([^ ]+)';
            var baseReplacement = funcName + '($1, $2';

            patterns.push({
                pattern: basePattern + '$',
                replacement: baseReplacement + ')',
                description: "Change on " + type,
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with (true|false)$',
                replacement: baseReplacement + ', $3)',
                description: "Change on " + type + " with direct boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with <([^>]+)>$',
                replacement: baseReplacement + ', $3)',
                description: "Change on " + type + " with noun boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with (true|false) and {([^}]*)}$',
                replacement: baseReplacement + ', $3, {$4})',
                description: "Change on " + type + " with direct boolean and table",
                category: "script"
            });
            patterns.push({
                pattern: basePattern + ' with <([^>]+)> and {([^}]*)}$',
                replacement: baseReplacement + ', $3, {$4})',
                description: "Change on " + type + " with noun boolean and table",
                category: "script"
            });
        }

        patterns = patterns.concat(generateFunctionPatterns(
            "run Haxe code",
            "runHaxeCode",
            [
                {name: "code", type: "any", required: true},
                {name: "varsToBring", type: "table", required: false, defaultValue: "null"},
                {name: "function", type: "any", required: false, defaultValue: "null"}
            ],
            ['with', 'property'],
            "Run Haxe code",
            "script"
        ));

        patterns.push({
            pattern: '^run Haxe code “([^”]*)”$',
            replacement: 'runHaxeCode("$1")',
            description: "run Haxe code",
            category: 'script'
        });
        patterns.push({
            pattern: '^run Haxe code “([^”]*)” with {([^}]*)}$',
            replacement: 'runHaxeCode("$1", {$2})',
            description: "run Haxe code with single table",
            category: 'script'
        });
        patterns.push({
            pattern: '^run Haxe code “([^”]*)” with {([^}]*)} property (.+?)$',
            replacement: 'runHaxeCode("$1", {$2}, $3)',
            description: "run Haxe code with table and function",
            category: 'script'
        });
        patterns.push({
            pattern: '^run Haxe code “([^”]*)” with {([^}]*)} and {([^}]*)} property (.+?)$',
            replacement: 'runHaxeCode("$1", {$2}, $4, {$3})',
            description: "run Haxe code with 2 tables and function",
            category: 'script'
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "run Haxe property",
            "runHaxeFunction",
            [
                {name: "function", type: "any", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Run Haxe property",
            "script"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "add Haxe library",
            "addHaxeLibrary",
            [
                {name: "lib", type: "any", required: true},
                {name: "package", type: "any", required: false, defaultValue: "''"}
            ],
            ['package'],
            "Add Haxe library",
            "script"
        ));

        patterns.push({
            pattern: '^read <([^>]+)>$',
            replacement: 'getVar("$1")',
            description: "Returns the named stored variable",
            category: "script"
        });
        patterns.push({
            pattern: '^change <([^>]+)> to (.+?)$',
            replacement: 'setVar("$1", $2)',
            description: "Returns the value that was inserted",
            category: "script"
        });

        return patterns;
    }

    static function generatePrecachePatterns():Array<Pattern> {
        var patterns = [];

        var precacheTypes = ["image", "sound", "music"];
        for (type in precacheTypes) {
            var funcName = "precache" + (type.charAt(0).toUpperCase() + type.substr(1));
            if (type == "image") {
                patterns = patterns.concat(generateBoolPatterns(
                    'precache ' + type + ' (.+)',
                    funcName + '($1',
                    {name: "allowGPU", type: "boolean", required: false, defaultValue: "true"},
                    "Precache " + type,
                    "precache"
                ));
            } else {
                patterns.push({
                    pattern: '^precache ' + type + ' (.+)$',
                    replacement: funcName + '($1)',
                    description: "Precache " + type,
                    category: "precache"
                });
            }
        }

        patterns = patterns.concat(generateFunctionPatterns(
            "add character",
            "addCharacterToList",
            [
                {name: "character", type: "any", required: true},
                {name: "type", type: "any", required: true}
            ],
            ['type'],
            "Add character to list",
            "precache"
        ));

        return patterns;
    }

    static function generateFlxAnimatePatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "create Flixel animate sprite",
            "makeFlxAnimateSprite",
            [
                {name: "tag", type: "any", required: true},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"},
                {name: "path", type: "any", required: false, defaultValue: "null"}
            ],
            ['with position', 'and', 'path'],
            "Create FlxAnimate sprite",
            "flxanimate"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load atlas sprite",
            "loadAnimateAtlas",
            [
                {name: "tag", type: "any", required: true},
                {name: "path", type: "any", required: true},
                {name: "spritePath", type: "any", required: false, defaultValue: "null"},
                {name: "animationPath", type: "any", required: false, defaultValue: "null"}
            ],
            ['path', 'sprite path', 'animation path'],
            "Load animate atlas",
            "flxanimate"
        ));

        patterns = patterns.concat(generateFunctionBoolPatterns(
            'add animation',
            'addAnimationBySymbol',
            [
                {name: "tag", type: "any", required: true},
                {name: "name", type: "any", required: true},
                {name: "symbol", type: "any", required: false, defaultValue: "24"},
                {name: "rate", type: "any", required: false, defaultValue: "24"},
                {name: "loop", type: "boolean", required: false, defaultValue: "false"},
                {name: "matX", type: "any", required: false, defaultValue: "0"},
                {name: "matY", type: "any", required: false, defaultValue: "0"}
            ],
            ['name', 'by symbol', 'rate', 'with', 'matrix', 'and'],
            [5],
            [],
            "Add animation by symbol",
            "flxanimate"
        ));

        patterns = patterns.concat(generateFunctionBoolPatterns(
            'add animation',
            'addAnimationBySymbolIndices',
            [
                {name: "tag", type: "any", required: true},
                {name: "name", type: "any", required: true},
                {name: "symbol", type: "any", required: false, defaultValue: "24"},
                {name: "indices", type: "any", required: false},
                {name: "rate", type: "any", required: false, defaultValue: "24"},
                {name: "loop", type: "boolean", required: false, defaultValue: "false"},
                {name: "matX", type: "any", required: false, defaultValue: "0"},
                {name: "matY", type: "any", required: false, defaultValue: "0"}
            ],
            ['name', 'by symbol', 'and indicies', 'rate', 'with', 'matrix', 'and'],
            [6],
            [],
            "Add animation by symbol with indices",
            "flxanimate"
        ));

        return patterns;
    }

    static function generatePrintPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateBoolPatterns(
            'print: (.+)',
            'print($1',
            {name: "value", type: "boolean", required: false, defaultValue: "false"},
            "Print string",
            "print"
        ));
        patterns.push({
            pattern: '^print: (.+)$',
            replacement: 'print($1)',
            description: "Print expression",
            category: "print"
        });

        patterns = patterns.concat(generateBoolPatterns(
            'print\\(debug\\): (.+)',
            'debugPrint($1',
            {name: "value", type: "boolean", required: false, defaultValue: "false"},
            "Debug print string",
            "print"
        ));
        patterns.push({
            pattern: '^print\\(debug\\): (.+)$',
            replacement: 'debugPrint($1)',
            description: "Debug print expression",
            category: "print"
        });

        return patterns;
    }

    static function generateIfExceptionPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: '^sprite <([^>]+)> exists$',
            replacement: 'luaSpriteExists($1)',
            description: "Check if sprite exists",
            category: "control"
        });
        patterns.push({
            pattern: '^text <([^>]+)> exists$',
            replacement: 'luaTextExists($1)',
            description: "Check if text exists",
            category: "control"
        });
        patterns.push({
            pattern: '^sound (.+) exists$',
            replacement: 'luaSoundExists($1)',
            description: "Check if sound exists",
            category: "control"
        });
        patterns.push({
            pattern: '^script (.+) is running$',
            replacement: 'isRunning($1)',
            description: "If script is running",
            category: "control"
        });

        return patterns;
    }

    static function generateSpecificPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: "^read songPosition$",
            replacement: "getSongPosition()",
            description: "Read song position",
            category: "playstate"
        });
        patterns.push({
            pattern: "^start countdown$",
            replacement: "startCountdown()",
            description: "Start countdown",
            category: "playstate"
        });
        patterns.push({
            pattern: "^close song$",
            replacement: "endSong()",
            description: "End song",
            category: "playstate"
        });
        patterns.push({
            pattern: "^read health$",
            replacement: "getHealth()",
            description: "Read health",
            category: "score"
        });
        patterns.push({
            pattern: "^update score text$",
            replacement: "updateScoreText()",
            description: "Update score text",
            category: "score"
        });
        patterns.push({
            pattern: "^close script$",
            replacement: "close()",
            description: "Close script",
            category: "script"
        });

        patterns.push({
            pattern: "\\bgive nothing\\b",
            replacement: "return nil",
            description: "Return nothing",
            category: "control"
        });
        patterns.push({
            pattern: "\\bgive back\\b",
            replacement: "return",
            description: "Return nothing (same as 'give')",
            category: "control"
        });
        patterns.push({
            pattern: "\\bgive\\b",
            replacement: "return",
            description: "Return nothing",
            category: "control"
        });
        patterns.push({
            pattern: "give (.+?)",
            replacement: "return $1",
            description: "Return a value from a function",
            category: "control"
        });
        patterns.push({
            pattern: "give back (.+?)",
            replacement: "return $1",
            description: "Return a value from a function (same as 'give')",
            category: "control"
        });
        patterns.push({
            pattern: "\\bproceed\\b",
            replacement: "return Function_Continue",
            description: "Continue script execution",
            category: "control"
        });
        patterns.push({
            pattern: "\\bhalt\\b",
            replacement: "return Function_Stop",
            description: "Stop this script only",
            category: "control"
        });
        patterns.push({
            pattern: "\\bhaltLua\\b",
            replacement: "return Function_StopLua",
            description: "Stop Lua scripts",
            category: "control"
        });
        patterns.push({
            pattern: "\\bhaltScript\\b",
            replacement: "return Function_StopHScript",
            description: "Stop HScripts",
            category: "control"
        });
        patterns.push({
            pattern: "\\bhaltAll\\b",
            replacement: "return Function_StopAll",
            description: "Stop all scripts",
            category: "control"
        });

        return patterns;
    }

    static function generateFallbackPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: "^read “(.+?)”$",
            replacement: 'getProperty("$1")',
            description: "Read any property",
            category: "reflection"
        });

        patterns.push({
            pattern: "^change “(.+?)” to (.+?)$",
            replacement: 'setProperty("$1", $2)',
            description: "Change any property",
            category: "reflection"
        });

        return patterns;
    }

    static function generateNestedPatterns():Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: "read ([^ ,]+)",
            replacement: 'getProperty($1)',
            description: "Read a property (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read from group ([^ ,]+) at ([^ ,]+) property ([^ ,]+)",
            replacement: 'getPropertyFromGroup($1, $2, $3)',
            description: "Read from group (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read from class ([^ ,]+) variable ([^ ,]+)",
            replacement: 'getPropertyFromClass($1, $2)',
            description: "Read from class (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "instance argument ([^ ,]+)",
            replacement: 'instanceArg($1)',
            description: "Instance argument (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read order of ([^ ,]+)",
            replacement: 'getObjectOrder($1)',
            description: "Read object order (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read midPoint x of ([^ ,]+)",
            replacement: 'getMidpointX($1)',
            description: "Read midpoint X (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read midPoint y of ([^ ,]+)",
            replacement: 'getMidpointY($1)',
            description: "Read midpoint Y (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read graphic midPoint x of ([^ ,]+)",
            replacement: 'getGraphicMidpointX($1)',
            description: "Read graphic midpoint X (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read graphic midPoint y of ([^ ,]+)",
            replacement: 'getGraphicMidpointY($1)',
            description: "Read graphic midpoint Y (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read position x of ([^ ,]+)",
            replacement: 'getScreenPositionX($1)',
            description: "Read screen position X (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read position y of ([^ ,]+)",
            replacement: 'getScreenPositionY($1)',
            description: "Read screen position Y (nested)",
            category: "reflection"
        });
        patterns.push({
            pattern: "read pixel of ([^ ,]+) with ([^ ,]+) and ([^ ,]+)",
            replacement: 'getPixelColor($1, $2, $3)',
            description: "Read pixel color (nested)",
            category: "reflection"
        });

        patterns.push({
            pattern: "read content of text ([^ ,]+)",
            replacement: 'getTextString($1)',
            description: "Read text content (nested)",
            category: "text"
        });
        patterns.push({
            pattern: "read size of text ([^ ,]+)",
            replacement: 'getTextSize($1)',
            description: "Read text size (nested)",
            category: "text"
        });
        patterns.push({
            pattern: "read font of text ([^ ,]+)",
            replacement: 'getTextFont($1)',
            description: "Read text font (nested)",
            category: "text"
        });
        patterns.push({
            pattern: "read width of text ([^ ,]+)",
            replacement: 'getTextWidth($1)',
            description: "Read text width (nested)",
            category: "text"
        });

        patterns.push({
            pattern: "read volume of sound ([^ ,]+)",
            replacement: 'getSoundVolume($1)',
            description: "Read sound volume (nested)",
            category: "sound"
        });
        patterns.push({
            pattern: "read time of sound ([^ ,]+)",
            replacement: 'getSoundTime($1)',
            description: "Read sound time (nested)",
            category: "sound"
        });
        patterns.push({
            pattern: "read pitch of sound ([^ ,]+)",
            replacement: 'getSoundPitch($1)',
            description: "Read sound pitch (nested)",
            category: "sound"
        });

        patterns.push({
            pattern: "read camera scroll x",
            replacement: 'getCameraScrollX()',
            description: "Read camera scroll X (nested)",
            category: "camera"
        });
        patterns.push({
            pattern: "read camera scroll y",
            replacement: 'getCameraScrollY()',
            description: "Read camera scroll Y (nested)",
            category: "camera"
        });
        patterns.push({
            pattern: "read camera follow x",
            replacement: 'getCameraFollowX()',
            description: "Read camera follow X (nested)",
            category: "camera"
        });
        patterns.push({
            pattern: "read camera follow y",
            replacement: 'getCameraFollowY()',
            description: "Read camera follow Y (nested)",
            category: "camera"
        });

        patterns.push({
            pattern: "read mouse x",
            replacement: 'getMouseX()',
            description: "Read mouse X (nested)",
            category: "input"
        });
        patterns.push({
            pattern: "read mouse y",
            replacement: 'getMouseY()',
            description: "Read mouse Y (nested)",
            category: "input"
        });
        patterns.push({
            pattern: "read mouse x on ([^ ,]+)",
            replacement: 'getMouseX($1)',
            description: "Read mouse X on camera (nested)",
            category: "input"
        });
        patterns.push({
            pattern: "read mouse y on ([^ ,]+)",
            replacement: 'getMouseY($1)',
            description: "Read mouse Y on camera (nested)",
            category: "input"
        });

        patterns.push({
            pattern: "read running scripts",
            replacement: 'getRunningScripts()',
            description: "Read running scripts (nested)",
            category: "script"
        });

        patterns.push({
            pattern: "read songPosition",
            replacement: 'getSongPosition()',
            description: "Read song position (nested)",
            category: "playstate"
        });
        patterns.push({
            pattern: "read health",
            replacement: 'getHealth()',
            description: "Read health (nested)",
            category: "score"
        });

        return patterns;
    }

    static function generateFunctionPatterns(
        command:String,
        luaFunction:String,
        params:Array<ParamDef>,
        prepositions:Array<String>,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        var required = [];
        var optional = [];
        for (p in params) {
            if (p.required) required.push(p);
            else optional.push(p);
        }

        var combos = generateCombinations(optional);

        for (combo in combos) {
            var allParams = required.concat(combo);

            var zsPattern = "^" + command;
            var captureGroups = [];
            var paramIndex = 1;

            for (i in 0...allParams.length) {
                var p = allParams[i];
                var originalIndex = -1;
                for (j in 0...params.length) {
                    if (params[j].name == p.name) {
                        originalIndex = j;
                        break;
                    }
                }
                var prepIndex = (params.length == 1) ? originalIndex : originalIndex - 1;
                var prep = (prepIndex >= 0 && prepIndex < prepositions.length) ? prepositions[prepIndex] : " ";

                if (prep == "with") {
                    zsPattern += " with ";
                } else if (prep == "without") {
                    zsPattern += " without ";
                } else if (prep != " ") {
                    zsPattern += " " + prep + " ";
                } else {
                    zsPattern += " ";
                }

                if (p.type == "string") {
                    zsPattern += "“([^”]*)”";
                    captureGroups.push(" \"$" + paramIndex + "\" ");
                } else if (p.type == "number") {
                    zsPattern += "(.+)";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "boolean") {
                    zsPattern += "(true|false)";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "table") {
                    zsPattern += "({[^}]*})";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "anyBeforeKeyword") {
                    zsPattern += "(.+)";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "anyBeforeKeyNongreedy") {
                    zsPattern += "(.+?)";
                    captureGroups.push("$" + paramIndex);
                } else {
                    zsPattern += "([^ ]+)";
                    captureGroups.push("$" + paramIndex);
                }
                paramIndex++;
            }

            zsPattern += "$";

            var luaReplacement = luaFunction + "(" + captureGroups.join(", ") + ")";

            patterns.push({
                pattern: zsPattern,
                replacement: luaReplacement,
                description: description + " (" + allParams.length + " params)",
                category: category
            });

            var booleanIndices = [];
            for (i in 0...allParams.length) {
                if (allParams[i].type == "boolean") {
                    booleanIndices.push(i);
                }
            }

            var nounCombos = generateIntCombinations([for (i in 0...booleanIndices.length) i]);
            for (combo in nounCombos) {
                if (combo.length == 0) continue;

                var nounIndices = [for (idx in combo) booleanIndices[idx]];
                var hasWithPrep = false;
                for (idx in nounIndices) {
                    var originalIndex = idx;
                    var outerPrepIndex = (params.length == 1) ? originalIndex : originalIndex - 1;
                    if (outerPrepIndex >= 0 && outerPrepIndex < prepositions.length && prepositions[outerPrepIndex] == "with") {
                        hasWithPrep = true;
                        break;
                    }
                }
                if (!hasWithPrep) continue;

                var nounPattern = "^" + command;
                var nounCaptureGroups = [];
                var nounParamIndex = 1;

                for (j in 0...allParams.length) {
                    var param = allParams[j];
                    var originalIndex = -1;
                    for (k in 0...params.length) {
                        if (params[k].name == param.name) {
                            originalIndex = k;
                            break;
                        }
                    }
                    var innerPrepIndex = (params.length == 1) ? originalIndex : originalIndex - 1;
                    var prep = (innerPrepIndex >= 0 && innerPrepIndex < prepositions.length) ? prepositions[innerPrepIndex] : " ";

                    if (prep == "with") {
                        nounPattern += " with ";
                    } else if (prep == "without") {
                        nounPattern += " without ";
                    } else if (prep != " ") {
                        nounPattern += " " + prep + " ";
                    } else {
                        nounPattern += " ";
                    }

                    var isNoun = nounIndices.contains(j);
                    if (isNoun && param.type == "boolean") {
                        nounPattern += "<([^>]+)>";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "string") {
                        nounPattern += "“([^”]*)”";
                        nounCaptureGroups.push(" \"$" + nounParamIndex + "\" ");
                    } else if (param.type == "number") {
                        nounPattern += "(.+)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "boolean") {
                        nounPattern += "(true|false)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "table") {
                        nounPattern += "({[^}]*})";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "anyBeforeKeyword") {
                        nounPattern += "(.+)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "anyBeforeKeyNongreedy") {
                        nounPattern += "(.+?)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else {
                        nounPattern += "([^ ]+)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    }
                    nounParamIndex++;
                }

                nounPattern += "$";

                var nounReplacement = luaFunction + "(";
                var replacementParts = [];
                for (k in 0...nounCaptureGroups.length) {
                    var group = nounCaptureGroups[k];
                    if (nounIndices.contains(k)) {
                        replacementParts.push('$' + (k + 1));
                    } else {
                        replacementParts.push(group);
                    }
                }
                nounReplacement += replacementParts.join(", ") + ")";

                var nounNames = [for (idx in nounIndices) allParams[idx].name];
                patterns.push({
                    pattern: nounPattern,
                    replacement: nounReplacement,
                    description: description + " (noun " + nounNames.join(",") + ")",
                    category: category
                });
            }
        }

        if (optional.length == params.length && params.length > 0) {
            patterns.push({
                pattern: "^" + command + "$",
                replacement: luaFunction + "()",
                description: description + " (no params)",
                category: category
            });
        }

        return patterns;
    }

    static function countCaptureGroups(pattern:String):Int {
        var count = 0;
        var i = 0;
        while (i < pattern.length) {
            if (pattern.charAt(i) == '(') {
                if (i + 1 < pattern.length && pattern.charAt(i + 1) != '?' && pattern.charAt(i + 1) != '=') {
                    count++;
                }
            }
            i++;
        }
        return count;
    }

    static function generateBoolPatterns(
        basePattern:String,
        baseReplacement:String,
        boolParam:ParamDef,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        var hasParams = baseReplacement.indexOf('$') != -1 && baseReplacement.indexOf('(') != -1;
        var separator = hasParams ? ", " : "";
        var captureOffset = countCaptureGroups(basePattern) + 1;

        patterns.push({
            pattern: "^" + basePattern + " with (true|false)$",
            replacement: baseReplacement + separator + "$" + captureOffset + ")",
            description: description + " with direct " + boolParam.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)>$",
            replacement: baseReplacement + separator + "$" + captureOffset + ")",
            description: description + " with noun " + boolParam.name,
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + "$",
            replacement: baseReplacement + ")",
            description: description + " (default)",
            category: category
        });

        return patterns;
    }

    static function generateTwoBoolPatterns(
        basePattern:String,
        baseReplacement:String,
        boolParam1:ParamDef,
        boolParam2:ParamDef,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        var hasParams = baseReplacement.indexOf('$') != -1 && baseReplacement.indexOf('(') != -1;
        var separator = hasParams ? ", " : "";
        var captureOffset = countCaptureGroups(basePattern) + 1;

        patterns.push({
            pattern: "^" + basePattern + " with (true|false) and (true|false)$",
            replacement: baseReplacement + separator + "$" + captureOffset + ", $" + (captureOffset + 1) + ")",
            description: description + " with direct " + boolParam1.name + " and direct " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with (true|false) and <([^>]+)>$",
            replacement: baseReplacement + separator + "$" + captureOffset + ", $" + (captureOffset + 1) + ")",
            description: description + " with direct " + boolParam1.name + " and noun " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)> and (true|false)$",
            replacement: baseReplacement + separator + "$" + captureOffset + ", $" + (captureOffset + 1) + ")",
            description: description + " with noun " + boolParam1.name + " and direct " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)> and <([^>]+)>$",
            replacement: baseReplacement + separator + "$" + captureOffset + ", $" + (captureOffset + 1) + ")",
            description: description + " with noun " + boolParam1.name + " and noun " + boolParam2.name,
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false)$",
            replacement: baseReplacement + separator + "$" + captureOffset + ")",
            description: description + " with direct " + boolParam1.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)>$",
            replacement: baseReplacement + separator + "$" + captureOffset + ")",
            description: description + " with noun " + boolParam1.name,
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + "$",
            replacement: baseReplacement + ")",
            description: description + " (default)",
            category: category
        });

        return patterns;
    }

    static function generateFunctionBoolPatterns(
        command:String,
        luaFunction:String,
        params:Array<ParamDef>,
        prepositions:Array<String>,
        boolPositions:Array<Int>,
        commaPositions:Array<Int>,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        var required = [];
        var optional = [];
        for (p in params) {
            if (p.required) required.push(p);
            else optional.push(p);
        }

        var combos = generateCombinations(optional);

        for (combo in combos) {
            var allParams = required.concat(combo);

            var zsPattern = "^" + command;
            var captureGroups = [];
            var paramIndex = 1;

            for (i in 0...allParams.length) {
                var p = allParams[i];
                var originalIndex = -1;
                for (j in 0...params.length) {
                    if (params[j].name == p.name) {
                        originalIndex = j;
                        break;
                    }
                }
                var prepIndex = (params.length == 1) ? originalIndex : originalIndex - 1;
                var prep = (prepIndex >= 0 && prepIndex < prepositions.length) ? prepositions[prepIndex] : " ";

                var useComma = commaPositions.contains(i);

                if (useComma) {
                    zsPattern += ", ";
                } else if (prep == "with") {
                    zsPattern += " with ";
                } else if (prep == "without") {
                    zsPattern += " without ";
                } else if (prep != " ") {
                    zsPattern += " " + prep + " ";
                } else {
                    zsPattern += " ";
                }

                if (p.type == "string") {
                    zsPattern += "“([^”]*)”";
                    captureGroups.push(" \"$" + paramIndex + "\" ");
                } else if (p.type == "number") {
                    zsPattern += "(.+)";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "boolean") {
                    zsPattern += "(true|false)";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "table") {
                    zsPattern += "({[^}]*})";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "anyBeforeKeyword") {
                    zsPattern += "(.+)";
                    captureGroups.push("$" + paramIndex);
                } else if (p.type == "anyBeforeKeyNongreedy") {
                    zsPattern += "(.+?)";
                    captureGroups.push("$" + paramIndex);
                } else {
                    zsPattern += "([^ ]+)";
                    captureGroups.push("$" + paramIndex);
                }
                paramIndex++;
            }

            zsPattern += "$";

            var luaReplacement = luaFunction + "(" + captureGroups.join(", ") + ")";

            patterns.push({
                pattern: zsPattern,
                replacement: luaReplacement,
                description: description + " (" + allParams.length + " params)",
                category: category
            });

            var booleanIndices = [];
            for (i in 0...allParams.length) {
                if (allParams[i].type == "boolean") {
                    booleanIndices.push(i);
                }
            }

            var nounCombos = generateIntCombinations([for (i in 0...booleanIndices.length) i]);
            for (combo in nounCombos) {
                if (combo.length == 0) continue;

                var nounIndices = [for (idx in combo) booleanIndices[idx]];
                var hasWithPrep = false;
                for (idx in nounIndices) {
                    var originalIndex = idx;
                    var outerPrepIndex = (params.length == 1) ? originalIndex : originalIndex - 1;
                    if (outerPrepIndex >= 0 && outerPrepIndex < prepositions.length && prepositions[outerPrepIndex] == "with") {
                        hasWithPrep = true;
                        break;
                    }
                }
                if (!hasWithPrep) continue;

                var nounPattern = "^" + command;
                var nounCaptureGroups = [];
                var nounParamIndex = 1;

                for (j in 0...allParams.length) {
                    var param = allParams[j];
                    var originalIndex = -1;
                    for (k in 0...params.length) {
                        if (params[k].name == param.name) {
                            originalIndex = k;
                            break;
                        }
                    }
                    var innerPrepIndex = (params.length == 1) ? originalIndex : originalIndex - 1;
                    var prep = (innerPrepIndex >= 0 && innerPrepIndex < prepositions.length) ? prepositions[innerPrepIndex] : " ";
                    var useComma = commaPositions.contains(j);

                    if (useComma) {
                        nounPattern += ", ";
                    } else if (prep == "with") {
                        nounPattern += " with ";
                    } else if (prep == "without") {
                        nounPattern += " without ";
                    } else if (prep != " ") {
                        nounPattern += " " + prep + " ";
                    } else {
                        nounPattern += " ";
                    }

                    var isNoun = nounIndices.contains(j);
                    if (isNoun && param.type == "boolean") {
                        nounPattern += "<([^>]+)>";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "string") {
                        nounPattern += "“([^”]*)”";
                        nounCaptureGroups.push(" \"$" + nounParamIndex + "\" ");
                    } else if (param.type == "number") {
                        nounPattern += "(.+)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "boolean") {
                        nounPattern += "(true|false)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "table") {
                        nounPattern += "({[^}]*})";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "anyBeforeKeyword") {
                        nounPattern += "(.+)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else if (param.type == "anyBeforeKeyNongreedy") {
                        nounPattern += "(.+?)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    } else {
                        nounPattern += "([^ ]+)";
                        nounCaptureGroups.push("$" + nounParamIndex);
                    }
                    nounParamIndex++;
                }

                nounPattern += "$";

                var nounReplacement = luaFunction + "(";
                var replacementParts = [];
                for (k in 0...nounCaptureGroups.length) {
                    var group = nounCaptureGroups[k];
                    if (nounIndices.contains(k)) {
                        replacementParts.push('$' + (k + 1));
                    } else {
                        replacementParts.push(group);
                    }
                }
                nounReplacement += replacementParts.join(", ") + ")";

                var nounNames = [for (idx in nounIndices) allParams[idx].name];
                patterns.push({
                    pattern: nounPattern,
                    replacement: nounReplacement,
                    description: description + " (noun " + nounNames.join(",") + ")",
                    category: category
                });
            }
        }

        return patterns;
    }

    static function generateCombinations(params:Array<ParamDef>):Array<Array<ParamDef>> {
        var combos = [[]];
        for (p in params) {
            var newCombos = [];
            for (combo in combos) {
                newCombos.push(combo);
                newCombos.push(combo.concat([p]));
            }
            combos = newCombos;
        }
        combos.reverse();
        return combos;
    }

    static function generateIntCombinations(params:Array<Int>):Array<Array<Int>> {
        var combos = [[]];
        for (p in params) {
            var newCombos = [];
            for (combo in combos) {
                newCombos.push(combo);
                newCombos.push(combo.concat([p]));
            }
            combos = newCombos;
        }
        return combos;
    }
}