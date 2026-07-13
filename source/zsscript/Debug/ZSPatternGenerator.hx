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
                {name: "song", type: "string", required: false, defaultValue: "null"},
                {name: "difficulty", type: "any", required: false, defaultValue: "-1"}
            ],
            ['with', 'difficulty'],
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
            replacement: 'triggerEvent($1, $2, "")',
            description: "Trigger an event with one value",
            category: "playstate"
        });
        patterns.push({
            pattern: "^trigger event (.+?)$",
            replacement: 'triggerEvent($1, "", "")',
            description: "Trigger an event with no values",
            category: "playstate"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "start dialogue",
            "startDialogue",
            [
                {name: "file", type: "string", required: true},
                {name: "music", type: "string", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Start a dialogue",
            "playstate"
        ));

        patterns = patterns.concat(generateFunctionBoolPatterns(
            "start video",
            "startVideo",
            [
                {name: "file", type: "string", required: true},
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

        return patterns;
    }

    static function generateReflectionPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateBoolPatternsSpecial(
            'read from group (.+?) at (.+?) property (.+?)',
            'getPropertyFromGroup($1, $2, $3',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            "Read a property from a group",
            "reflection"
        ));

        patterns = patterns.concat(generateBoolPatternsSpecial(
            'read from class (.+?) variable (.+?)',
            'getPropertyFromClass($1, $2',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            "Read a property from a class",
            "reflection"
        ));

        patterns = patterns.concat(generateTwoBoolPatternsSpecial(
            'change in group (.+?) at (.+?) property (.+?) to (.+?)',
            'setPropertyFromGroup($1, $2, $3, $4',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            {name: "allowInstances", type: "boolean", required: false, defaultValue: "false"},
            "Change a property in a group",
            "reflection"
        ));

        patterns = patterns.concat(generateTwoBoolPatternsSpecial(
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
                {name: "function", type: "string", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Call a method",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "call method from class",
            "callMethodFromClass",
            [
                {name: "class", type: "string", required: true},
                {name: "function", type: "string", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Call a method from a class",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "create instance",
            "createInstance",
            [
                {name: "variable", type: "string", required: true},
                {name: "class", type: "string", required: true},
                {name: "args", type: "table", required: false, defaultValue: "null"}
            ],
            ['with', 'and'],
            "Create an instance",
            "reflection"
        ));

        patterns = patterns.concat(generateBoolPatternsSpecial(
            'add instance to (.+)',
            'addInstance($1',
            {name: "inFront", type: "boolean", required: false, defaultValue: "false"},
            "Add an instance",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "read order of",
            "getObjectOrder",
            [
                {name: "tag", type: "string", required: true},
                {name: "group", type: "string", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Read object order",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change in order of",
            "setObjectOrder",
            [
                {name: "tag", type: "string", required: true},
                {name: "position", type: "any", required: true},
                {name: "group", type: "string", required: false, defaultValue: "null"}
            ],
            ['with'],
            "Change object order",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "add",
            "addToGroup",
            [
                {name: "tag", type: "string", required: true},
                {name: "group", type: "string", required: true},
                {name: "index", type: "any", required: false, defaultValue: "-1"}
            ],
            ['to', 'at'],
            "Add to group",
            "reflection"
        ));

        patterns = patterns.concat(generateBoolPatternsSpecial(
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
                {name: "tag", type: "string", required: true},
                {name: "camera", type: "string", required: false, defaultValue: "game"}
            ],
            ['to'],
            "Change object camera",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change scroll factor of",
            "setScrollFactor",
            [
                {name: "tag", type: "string", required: true},
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
                {name: "tag", type: "string", required: true},
                {name: "x", type: "any", required: true},
                {name: "y", type: "any", required: true},
                {name: "updateHitbox", type: "boolean", required: false, defaultValue: "true"}
            ],
            ['with', 'and', 'with'],
            "Scale an object",
            "reflection"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            'scale by pixel',
            'setGraphicSize',
            [
                {name: "tag", type: "string", required: true},
                {name: "width", type: "any", required: true},
                {name: "height", type: "any", required: true},
                {name: "updateHitbox", type: "boolean", required: false, defaultValue: "true"}
            ],
            ['with', 'and', 'with'],
            "Scale an object by pixel",
            "reflection"
        ));

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
            pattern: '^read midpoint x of (.+?)$',
            replacement: 'getMidpointX($1)',
            description: "Read midpoint X",
            category: "reflection"
        });
        patterns.push({
            pattern: '^read midpoint y of (.+?)$',
            replacement: 'getMidpointY($1)',
            description: "Read midpoint Y",
            category: "reflection"
        });

        patterns.push({
            pattern: '^read graphic midpoint x of (.+?)$',
            replacement: 'getGraphicMidpointX($1)',
            description: "Read graphic midpoint X",
            category: "reflection"
        });
        patterns.push({
            pattern: '^read graphic midpoint y of (.+?)$',
            replacement: 'getGraphicMidpointY($1)',
            description: "Read graphic midpoint Y",
            category: "reflection"
        });

        patterns = patterns.concat(generateFunctionPatterns(
            "read position x of",
            "getScreenPositionX",
            [
                {name: "tag", type: "string", required: true},
                {name: "camera", type: "string", required: false, defaultValue: "game"}
            ],
            ['by'],
            "Read screen position X",
            "reflection"
        ));
        patterns = patterns.concat(generateFunctionPatterns(
            "read position y of",
            "getScreenPositionY",
            [
                {name: "tag", type: "string", required: true},
                {name: "camera", type: "string", required: false, defaultValue: "game"}
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

        patterns = patterns.concat(generateBoolPatternsSpecial(
            "read (.+?)",
            'getProperty($1',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            "Read a property",
            "reflection"
        ));

        patterns = patterns.concat(generateTwoBoolPatternsSpecial(
            'change (.+?) to (.+?)',
            'setProperty($1, $2',
            {name: "allowMaps", type: "boolean", required: false, defaultValue: "false"},
            {name: "allowInstances", type: "boolean", required: false, defaultValue: "false"},
            "Change a property",
            "reflection"
        ));

        return patterns;
    }

    static function generateSpritePatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "create sprite",
            "makeLuaSprite",
            [
                {name: "tag", type: "string", required: true},
                {name: "image", type: "string", required: false, defaultValue: "null"},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"}
            ],
            ['path', 'with', 'position', 'and'],
            "Create a sprite",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "create animated sprite",
            "makeAnimatedLuaSprite",
            [
                {name: "tag", type: "string", required: true},
                {name: "image", type: "string", required: false, defaultValue: "null"},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"},
                {name: "type", type: "string", required: false, defaultValue: "auto"}
            ],
            ['path', 'with', 'position', 'and', 'type'],
            "Create an animated sprite",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "create graphic",
            "makeGraphic",
            [
                {name: "tag", type: "string", required: true},
                {name: "width", type: "any", required: false, defaultValue: "256"},
                {name: "height", type: "any", required: false, defaultValue: "256"},
                {name: "color", type: "string", required: false, defaultValue: "FFFFFF"}
            ],
            ['with', 'size', 'and', 'color'],
            "Create a graphic",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load graphic",
            "loadGraphic",
            [
                {name: "tag", type: "string", required: true},
                {name: "image", type: "string", required: true},
                {name: "gridX", type: "any", required: false, defaultValue: "0"},
                {name: "gridY", type: "any", required: false, defaultValue: "0"}
            ],
            ['path', 'with', 'grid', 'and'],
            "Load a graphic",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load frame",
            "loadFrames",
            [
                {name: "tag", type: "string", required: true},
                {name: "image", type: "string", required: true},
                {name: "type", type: "string", required: false, defaultValue: "auto"}
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

        patterns = patterns.concat(generateBoolPatternsSpecial(
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
                {name: "tag", type: "string", required: true},
                {name: "group", type: "string", required: false, defaultValue: "null"},
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

        patterns = patterns.concat(generateFunctionPatterns(
            'add animation name with frames',
            'addAnimation',
            [
                {name: "tag", type: "string", required: true},
                {name: "name", type: "string", required: true},
                {name: "frames", type: "any", required: true},
                {name: "rate", type: "any", required: false, defaultValue: "24"}
            ],
            ['name', 'with', 'rate'],
            "Add animation with frames",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            'add animation name by prefix',
            'addAnimationByPrefix',
            [
                {name: "tag", type: "string", required: true},
                {name: "name", type: "string", required: true},
                {name: "prefix", type: "string", required: true},
                {name: "rate", type: "any", required: false, defaultValue: "24"}
            ],
            ['name', 'by', 'rate'],
            "Add animation by prefix",
            "sprites"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            'add animation name by indices prefix',
            'addAnimationByIndices',
            [
                {name: "tag", type: "string", required: true},
                {name: "name", type: "string", required: true},
                {name: "prefix", type: "string", required: true},
                {name: "indices", type: "any", required: true},
                {name: "rate", type: "any", required: false, defaultValue: "24"}
            ],
            ['name', 'by', 'prefix', 'rate'],
            "Add animation by indices",
            "sprites"
        ));

        return patterns;
    }

    static function generatePlayAnimationPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionBoolPatterns(
            "play animation",
            "playAnim",
            [
                {name: "tag", type: "string", required: true},
                {name: "name", type: "string", required: true},
                {name: "startFrame", type: "number", required: false, defaultValue: "0"},
                {name: "forced", type: "boolean", required: false, defaultValue: "false"},
                {name: "reverse", type: "boolean", required: false, defaultValue: "false"}
            ],
            ["name", "start", "with"],
            [3, 4],
            [],
            "Play animation",
            "sprites"
        ));

        return patterns;
    }

    static function generateTextPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateFunctionPatterns(
            "create text",
            "makeLuaText",
            [
                {name: "tag", type: "string", required: true},
                {name: "content", type: "string", required: false, defaultValue: "''"},
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
            'removeLuaText($1)',
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

        patterns = patterns.concat(generateBoolPatterns(
            'change auto size of text (.+?) to',
            'setTextAutoSize($1, true)',
            {name: "value", type: "boolean", required: false, defaultValue: "true"},
            "Change text auto size",
            "text"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change border of text",
            "setTextBorder",
            [
                {name: "tag", type: "string", required: true},
                {name: "size", type: "any", required: true},
                {name: "color", type: "string", required: true},
                {name: "style", type: "string", required: false, defaultValue: "outline"}
            ],
            ['to', 'size', 'color', 'style'],
            "Change text border",
            "text"
        ));

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

        patterns = patterns.concat(generateBoolPatterns(
            'change italic of text (.+?) to',
            'setTextItalic($1, true)',
            {name: "italic", type: "boolean", required: false, defaultValue: "true"},
            "Change text italic",
            "text"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change alignment of text",
            "setTextAlignment",
            [
                {name: "tag", type: "string", required: true},
                {name: "alignment", type: "string", required: false, defaultValue: "left"}
            ],
            ['to', 'alignment'],
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
                {name: "sound", type: "string", required: true},
                {name: "volume", type: "any", required: false, defaultValue: "1"},
                {name: "tag", type: "string", required: false, defaultValue: "null"},
                {name: "loop", type: "boolean", required: false, defaultValue: "false"}
            ],
            ['with', 'volume', 'name', 'with'],
            "Play a sound",
            "sound"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "play music",
            "playMusic",
            [
                {name: "music", type: "string", required: true},
                {name: "volume", type: "any", required: false, defaultValue: "1"},
                {name: "loop", type: "boolean", required: false, defaultValue: "false"}
            ],
            ['with', 'volume', 'with'],
            "Play music",
            "sound"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "fade in",
            "soundFadeIn",
            [
                {name: "tag", type: "string", required: true},
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
                {name: "tag", type: "string", required: true},
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
            'setSoundPitch($1, $2)',
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

        patterns = patterns.concat(generateFunctionPatterns(
            "change scroll camera",
            "setCameraScroll",
            [
                {name: "x", type: "any", required: true},
                {name: "y", type: "any", required: true}
            ],
            ['with', 'and'],
            "Change camera scroll",
            "camera"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "change camera follow to point",
            "setCameraFollowPoint",
            [
                {name: "x", type: "any", required: true},
                {name: "y", type: "any", required: true}
            ],
            ['and'],
            "Change camera follow point",
            "camera"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "add scroll camera",
            "addCameraScroll",
            [
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"}
            ],
            ['with', 'and'],
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
            ['with', 'and'],
            "Add camera follow point",
            "camera"
        ));

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
                {name: "camera", type: "string", required: true},
                {name: "intensity", type: "any", required: true},
                {name: "duration", type: "any", required: true}
            ],
            ['with', 'value', 'and'],
            "Shake camera",
            "camera"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'flash camera (.+?) with color (.+?) duration (.+?)',
            'cameraFlash($1, $2, $3)',
            {name: "forceReset", type: "boolean", required: false, defaultValue: "true"},
            "Flash camera",
            "camera"
        ));

        patterns = patterns.concat(generateTwoBoolPatterns(
            'fade camera (.+?) with color (.+?) duration (.+?)',
            'cameraFade($1, $2, $3)',
            {name: "forceReset", type: "boolean", required: false, defaultValue: "true"},
            {name: "fadeOut", type: "boolean", required: false, defaultValue: "false"},
            "Fade camera",
            "camera"
        ));

        return patterns;
    }

    static function generateInputPatterns():Array<Pattern> {
        var patterns = [];

        var mouseButtons = ["left", "right"];
        var mouseActions = ["clicked", "pressed", "released"];
        for (button in mouseButtons) {
            for (action in mouseActions) {
                patterns.push({
                    pattern: '^mouse "' + button + '" ' + action + '$',
                    replacement: 'mouse' + (action.charAt(0).toUpperCase() + action.substr(1)) + '("' + button + '")',
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
                {name: "camera", type: "string", required: false, defaultValue: "game"}
            ],
            [],
            "Read mouse X on camera",
            "input"
        ));
        patterns = patterns.concat(generateFunctionPatterns(
            "read mouse y on",
            "getMouseY",
            [
                {name: "camera", type: "string", required: false, defaultValue: "game"}
            ],
            [],
            "Read mouse Y on camera",
            "input"
        ));

        var keyTypes = ["key", "keyboard", "any gamepad"];
        var keyActions = ["pressed", "just pressed", "released"];
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
            pattern: '^gamepad id (.+?) button (.+?) pressed$',
            replacement: 'gamepadPressed($1, $2)',
            description: "Gamepad pressed",
            category: "input"
        });
        patterns.push({
            pattern: '^gamepad id (.+?) button (.+?) just pressed$',
            replacement: 'gamepadJustPressed($1, $2)',
            description: "Gamepad just pressed",
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
            'gamepadAnalogX($1)',
            {name: "leftStick", type: "boolean", required: false, defaultValue: "true"},
            "Gamepad analog X",
            "input"
        ));
        patterns = patterns.concat(generateBoolPatterns(
            'gamepad id (.+?) analog y',
            'gamepadAnalogY($1)',
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
                {name: "twnTag", type: "string", required: true},
                {name: "objTag", type: "string", required: true},
                {name: "value", type: "any", required: true},
                {name: "duration", type: "any", required: true},
                {name: "options", type: "table", required: false, defaultValue: "null"}
            ],
            ['for', 'value', 'duration', 'type'],
            "Start a tween",
            "tween"
        ));

        var tweenTypes = ["x", "y", "angle", "alpha"];
        for (type in tweenTypes) {
            patterns = patterns.concat(generateFunctionPatterns(
                "tween " + type + " tag",
                "doTween" + (type.charAt(0).toUpperCase() + type.substr(1)),
                [
                    {name: "twnTag", type: "string", required: true},
                    {name: "objTag", type: "string", required: true},
                    {name: "value", type: "any", required: true},
                    {name: "duration", type: "any", required: true},
                    {name: "ease", type: "string", required: false, defaultValue: "linear"}
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
                {name: "twnTag", type: "string", required: true},
                {name: "objTag", type: "string", required: true},
                {name: "color", type: "string", required: true},
                {name: "duration", type: "any", required: true},
                {name: "ease", type: "string", required: false, defaultValue: "linear"}
            ],
            ['for', 'color', 'duration', 'type'],
            "Tween color",
            "tween"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "tween zoom tag",
            "doTweenZoom",
            [
                {name: "twnTag", type: "string", required: true},
                {name: "camera", type: "string", required: true},
                {name: "value", type: "any", required: true},
                {name: "duration", type: "any", required: true},
                {name: "ease", type: "string", required: false, defaultValue: "linear"}
            ],
            ['camera', 'value', 'duration', 'type'],
            "Tween zoom",
            "tween"
        ));

        var noteTweenTypes = ["x", "y", "angle", "alpha", "direction"];
        for (type in noteTweenTypes) {
            patterns = patterns.concat(generateFunctionPatterns(
                "tween " + type + " tag",
                "noteTween" + (type.charAt(0).toUpperCase() + type.substr(1)),
                [
                    {name: "twnTag", type: "string", required: true},
                    {name: "note", type: "any", required: true},
                    {name: "value", type: "any", required: true},
                    {name: "duration", type: "any", required: true},
                    {name: "ease", type: "string", required: false, defaultValue: "linear"}
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
                {name: "tmrTag", type: "string", required: true},
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
            pattern: '^change rating fc to (.+?)$',
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
                {name: "save", type: "string", required: true},
                {name: "path", type: "string", required: false, defaultValue: "psychenginemods"}
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
                {name: "save", type: "string", required: true},
                {name: "property", type: "string", required: true},
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
                {name: "save", type: "string", required: true},
                {name: "property", type: "string", required: true},
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
                {name: "script", type: "string", required: true},
                {name: "function", type: "string", required: true},
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
                funcName + '($1)',
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
            var baseReplacement = funcName + '($1)';

            patterns.push({
                pattern: basePattern + '$',
                replacement: baseReplacement,
                description: "Call on " + type,
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)}$',
                replacement: baseReplacement + ', {$2}',
                description: "Call on " + type + " with args",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)}$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}',
                description: "Call on " + type + " with tables",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with (true|false)$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5',
                description: "Call on " + type + " with tables and direct boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with <([^>]+)>$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5',
                description: "Call on " + type + " with tables and noun boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with (true|false) and (true|false)$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6',
                description: "Call on " + type + " with tables and two direct booleans",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with <([^>]+)> and <([^>]+)>$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6',
                description: "Call on " + type + " with tables and two noun booleans",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with (true|false) and <([^>]+)>$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6',
                description: "Call on " + type + " with tables and mixed booleans",
                category: "script"
            });
            patterns.push({
                pattern: basePattern + ' with {([^}]*)} and {([^}]*)} and {([^}]*)} with <([^>]+)> and (true|false)$',
                replacement: baseReplacement + ', {$2}, {$3}, {$4}, $5, $6',
                description: "Call on " + type + " with tables and mixed booleans",
                category: "script"
            });
        }

        var changeTypes = ["scripts", "Luas", "HScript", "ZS"];
        for (type in changeTypes) {
            var funcName = "setOn" + (type == "scripts" ? "Scripts" : (type == "Luas" ? "Luas" : (type == "HScript" ? "HScript" : "ZSScripts")));
            var basePattern = 'change on ' + type + ' <([^>]+)> to (.+?)';
            var baseReplacement = funcName + '^($1, $2)';

            patterns.push({
                pattern: basePattern + '$',
                replacement: baseReplacement,
                description: "Change on " + type,
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with (true|false)$',
                replacement: baseReplacement + ', $3',
                description: "Change on " + type + " with direct boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with <([^>]+)>$',
                replacement: baseReplacement + ', $3',
                description: "Change on " + type + " with noun boolean",
                category: "script"
            });

            patterns.push({
                pattern: basePattern + ' with (true|false) and {([^}]*)}$',
                replacement: baseReplacement + ', $3, {$4}',
                description: "Change on " + type + " with direct boolean and table",
                category: "script"
            });
            patterns.push({
                pattern: basePattern + ' with <([^>]+)> and {([^}]*)}$',
                replacement: baseReplacement + ', $3, {$4}',
                description: "Change on " + type + " with noun boolean and table",
                category: "script"
            });
        }

        patterns = patterns.concat(generateFunctionPatterns(
            "run Haxe code",
            "runHaxeCode",
            [
                {name: "code", type: "string", required: true},
                {name: "varsToBring", type: "table", required: false, defaultValue: "null"},
                {name: "function", type: "string", required: false, defaultValue: "null"}
            ],
            ['with', 'property'],
            "Run Haxe code",
            "script"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "run Haxe code",
            "runHaxeCode",
            [
                {name: "code", type: "string", required: true},
                {name: "varsToBring", type: "table", required: false, defaultValue: "null"},
                {name: "function", type: "string", required: false, defaultValue: "null"},
                {name: "funcArgs", type: "table", required: false, defaultValue: "null"}
            ],
            ['with', 'and', 'property'],
            "Run Haxe code",
            "script"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "run Haxe property",
            "runHaxeFunction",
            [
                {name: "function", type: "string", required: true},
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
                {name: "lib", type: "string", required: true},
                {name: "package", type: "string", required: false, defaultValue: "''"}
            ],
            ['package'],
            "Add Haxe library",
            "script"
        ));

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
                    funcName + '($1)',
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
                {name: "character", type: "string", required: true},
                {name: "type", type: "string", required: true}
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
                {name: "tag", type: "string", required: true},
                {name: "x", type: "any", required: false, defaultValue: "0"},
                {name: "y", type: "any", required: false, defaultValue: "0"},
                {name: "path", type: "string", required: false, defaultValue: "null"}
            ],
            ['with', 'position', 'and', 'path'],
            "Create FlxAnimate sprite",
            "flxanimate"
        ));

        patterns = patterns.concat(generateFunctionPatterns(
            "load atlas sprite",
            "loadAnimateAtlas",
            [
                {name: "tag", type: "string", required: true},
                {name: "path", type: "string", required: true},
                {name: "spritePath", type: "string", required: false, defaultValue: "null"},
                {name: "animationPath", type: "string", required: false, defaultValue: "null"}
            ],
            ['path', 'sprite path', 'animation path'],
            "Load animate atlas",
            "flxanimate"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'add animation (.+) name (.+) by symbol (.+)',
            'addAnimationBySymbol($1, $2, $3)',
            {name: "framerate", type: "any", required: false, defaultValue: "24"},
            "Add animation by symbol",
            "flxanimate"
        ));

        patterns = patterns.concat(generateBoolPatterns(
            'add animation (.+) name (.+) by symbol (.+) and indices (.+)',
            'addAnimationBySymbolIndices($1, $2, $3, $4)',
            {name: "framerate", type: "any", required: false, defaultValue: "24"},
            "Add animation by symbol with indices",
            "flxanimate"
        ));

        return patterns;
    }

    static function generatePrintPatterns():Array<Pattern> {
        var patterns = [];

        patterns = patterns.concat(generateBoolPatterns(
            'print: (.+)',
            'print($1)',
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
            'debugPrint($1)',
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
                var prep = (i < prepositions.length) ? prepositions[i] : " ";

                if (prep == "with" && p.type == "boolean") {
                    zsPattern += " with ";
                } else if (prep == "without" && p.type == "boolean") {
                    zsPattern += " without ";
                } else if (prep != " ") {
                    zsPattern += " " + prep + " ";
                } else {
                    zsPattern += " ";
                }

                if (p.type == "string") {
                    zsPattern += "“(.+?)”";
                } else if (p.type == "number") {
                    zsPattern += "(.+)";
                } else if (p.type == "boolean") {
                    zsPattern += "(true|false)";
                } else if (p.type == "table") {
                    zsPattern += "({[^}]*})";
                } else {
                    zsPattern += "(.+)";
                }
                captureGroups.push("$" + paramIndex);
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

            // Add noun pattern for boolean parameters with "with" preposition
            for (i in 0...allParams.length) {
                var p = allParams[i];
                if (p.type == "boolean" && i < prepositions.length && prepositions[i] == "with") {
                    var nounPattern = "^" + command;
                    var nounCaptureGroups = [];
                    var nounParamIndex = 1;

                    for (j in 0...allParams.length) {
                        var param = allParams[j];
                        var prep = (j < prepositions.length) ? prepositions[j] : " ";

                        if (prep == "with" && param.type == "boolean") {
                            nounPattern += " with ";
                        } else if (prep == "without" && param.type == "boolean") {
                            nounPattern += " without ";
                        } else if (prep != " ") {
                            nounPattern += " " + prep + " ";
                        } else {
                            nounPattern += " ";
                        }

                        if (j == i && param.type == "boolean") {
                            nounPattern += "<([^>]+)>";
                        } else if (param.type == "string") {
                            nounPattern += "“(.+?)”";
                        } else if (param.type == "number") {
                            nounPattern += "(.+)";
                        } else if (param.type == "boolean") {
                            nounPattern += "(true|false)";
                        } else if (param.type == "table") {
                            nounPattern += "({[^}]*})";
                        } else {
                            nounPattern += "(.+)";
                        }
                        nounCaptureGroups.push("$" + nounParamIndex);
                        nounParamIndex++;
                    }

                    nounPattern += "$";

                    var nounReplacement = luaFunction + "(" + nounCaptureGroups.join(", ") + ")";

                    patterns.push({
                        pattern: nounPattern,
                        replacement: nounReplacement,
                        description: description + " (noun " + p.name + ")",
                        category: category
                    });
                }
            }
        }

        // Add pattern for command with no parameters (if all params are optional)
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

    static function generateBoolPatterns(
        basePattern:String,
        baseReplacement:String,
        boolParam:ParamDef,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        patterns.push({
            pattern: "^" + basePattern + "$",
            replacement: baseReplacement + "()",
            description: description + " (default)",
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false)$",
            replacement: baseReplacement + "($1)",
            description: description + " with direct " + boolParam.name,
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)>$",
            replacement: baseReplacement + "($1)",
            description: description + " with noun " + boolParam.name,
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

        patterns.push({
            pattern: "^" + basePattern + "$",
            replacement: baseReplacement + "()",
            description: description + " (default)",
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false)$",
            replacement: baseReplacement + "($1)",
            description: description + " with direct " + boolParam1.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)>$",
            replacement: baseReplacement + "($1)",
            description: description + " with noun " + boolParam1.name,
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false) and (true|false)$",
            replacement: baseReplacement + "($1, $2)",
            description: description + " with direct " + boolParam1.name + " and direct " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with (true|false) and <([^>]+)>$",
            replacement: baseReplacement + "($1, $2)",
            description: description + " with direct " + boolParam1.name + " and noun " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)> and (true|false)$",
            replacement: baseReplacement + "($1, $2)",
            description: description + " with noun " + boolParam1.name + " and direct " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)> and <([^>]+)>$",
            replacement: baseReplacement + "($1, $2)",
            description: description + " with noun " + boolParam1.name + " and noun " + boolParam2.name,
            category: category
        });

        return patterns;
    }

    static function generateBoolPatternsSpecial(
        basePattern:String,
        baseReplacement:String,
        boolParam:ParamDef,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        // Check if baseReplacement already has parameters (contains $1, $2, etc.)
        var hasParams = baseReplacement.indexOf('$') != -1;
        var separator = hasParams ? ", " : "";

        patterns.push({
            pattern: "^" + basePattern + "$",
            replacement: baseReplacement + ")",
            description: description + " (default)",
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false)$",
            replacement: baseReplacement + separator + "$1)",
            description: description + " with direct " + boolParam.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)>$",
            replacement: baseReplacement + separator + "$1)",
            description: description + " with noun " + boolParam.name,
            category: category
        });

        return patterns;
    }

    static function generateTwoBoolPatternsSpecial(
        basePattern:String,
        baseReplacement:String,
        boolParam1:ParamDef,
        boolParam2:ParamDef,
        description:String,
        category:String
    ):Array<Pattern> {
        var patterns = [];

        // Check if baseReplacement already has parameters (contains $1, $2, etc.)
        var hasParams = baseReplacement.indexOf('$') != -1;
        var separator = hasParams ? ", " : "";

        patterns.push({
            pattern: "^" + basePattern + "$",
            replacement: baseReplacement + ")",
            description: description + " (default)",
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false)$",
            replacement: baseReplacement + separator + "$1)",
            description: description + " with direct " + boolParam1.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)>$",
            replacement: baseReplacement + separator + "$1)",
            description: description + " with noun " + boolParam1.name,
            category: category
        });

        patterns.push({
            pattern: "^" + basePattern + " with (true|false) and (true|false)$",
            replacement: baseReplacement + separator + "$1, $2)",
            description: description + " with direct " + boolParam1.name + " and direct " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with (true|false) and <([^>]+)>$",
            replacement: baseReplacement + separator + "$1, $2)",
            description: description + " with direct " + boolParam1.name + " and noun " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)> and (true|false)$",
            replacement: baseReplacement + separator + "$1, $2)",
            description: description + " with noun " + boolParam1.name + " and direct " + boolParam2.name,
            category: category
        });
        patterns.push({
            pattern: "^" + basePattern + " with <([^>]+)> and <([^>]+)>$",
            replacement: baseReplacement + separator + "$1, $2)",
            description: description + " with noun " + boolParam1.name + " and noun " + boolParam2.name,
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
                var prep = (i < prepositions.length) ? prepositions[i] : " ";
                var useComma = commaPositions.contains(i);

                if (useComma) {
                    zsPattern += ", ";
                } else if (prep == "with" && p.type == "boolean") {
                    zsPattern += " with ";
                } else if (prep == "without" && p.type == "boolean") {
                    zsPattern += " without ";
                } else if (prep != " ") {
                    zsPattern += " " + prep + " ";
                } else {
                    zsPattern += " ";
                }

                if (p.type == "string") {
                    zsPattern += "“(.+?)”";
                } else if (p.type == "number") {
                    zsPattern += "(.+)";
                } else if (p.type == "boolean") {
                    zsPattern += "(true|false)";
                } else if (p.type == "table") {
                    zsPattern += "({[^}]*})";
                } else {
                    zsPattern += "(.+)";
                }
                captureGroups.push("$" + paramIndex);
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

            // Add noun pattern for boolean parameters with "with" preposition
            for (i in 0...allParams.length) {
                var p = allParams[i];
                if (p.type == "boolean" && i < prepositions.length && prepositions[i] == "with") {
                    var nounPattern = "^" + command;
                    var nounCaptureGroups = [];
                    var nounParamIndex = 1;

                    for (j in 0...allParams.length) {
                        var param = allParams[j];
                        var prep = (j < prepositions.length) ? prepositions[j] : " ";
                        var useComma = commaPositions.contains(j);

                        if (useComma) {
                            nounPattern += ", ";
                        } else if (prep == "with" && param.type == "boolean") {
                            nounPattern += " with ";
                        } else if (prep == "without" && param.type == "boolean") {
                            nounPattern += " without ";
                        } else if (prep != " ") {
                            nounPattern += " " + prep + " ";
                        } else {
                            nounPattern += " ";
                        }

                        if (j == i && param.type == "boolean") {
                            nounPattern += "<([^>]+)>";
                        } else if (param.type == "string") {
                            nounPattern += "“(.+?)”";
                        } else if (param.type == "number") {
                            nounPattern += "(.+)";
                        } else if (param.type == "boolean") {
                            nounPattern += "(true|false)";
                        } else if (param.type == "table") {
                            nounPattern += "({[^}]*})";
                        } else {
                            nounPattern += "(.+)";
                        }
                        nounCaptureGroups.push("$" + nounParamIndex);
                        nounParamIndex++;
                    }

                    nounPattern += "$";

                    var nounReplacement = luaFunction + "(" + nounCaptureGroups.join(", ") + ")";

                    patterns.push({
                        pattern: nounPattern,
                        replacement: nounReplacement,
                        description: description + " (noun " + p.name + ")",
                        category: category
                    });
                }
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
        return combos;
    }
}