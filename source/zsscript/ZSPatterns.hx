package zsscript;

typedef Pattern = {
    pattern:String,
    replacement:String,
    description:String,
    category:String
}

class ZSPatterns {
    public static var patterns:Array<Pattern> = [
        // ===== TRIGGER EVENT =====
        {
            pattern: "trigger event <([^>]+)> with value “([^”]+)”, “([^”]+)”",
            replacement: 'triggerEvent("$1", $2, $3)',
            description: "Trigger event with two values",
            category: "events"
        },
        {
            pattern: "([a-zA-Z_][a-zA-Z0-9_]*)<([^>]+)(?:, *<([^>]+)>)*>",
            replacement: "$1($2)",
            description: "Function call with parameters",
            category: "functions"
        },
        {
            pattern: "([a-zA-Z_][a-zA-Z0-9_]*)<>",
            replacement: "$1()",
            description: "Function call without parameters",
            category: "functions"
        },

        // ===== PROPERTY OPERATIONS =====
        {
            pattern: "change <([^>]+)> to (.+)",
            replacement: 'setProperty("$1", $2)',
            description: "Set property",
            category: "properties"
        },
        {
            pattern: "read <([^>]+)>",
            replacement: 'getProperty("$1")',
            description: "Get property",
            category: "properties"
        },

        // ===== SHADER OPERATIONS =====
        {
            pattern: "register shader <([^>]+)>",
            replacement: 'initLuaShader("$1")',
            description: "Register shader",
            category: "shaders"
        },
        {
            pattern: "apply shader <([^>]+)> to <([^>]+)>",
            replacement: 'setSpriteShader("$2", "$1")',
            description: "Apply shader to sprite",
            category: "shaders"
        },
        {
            pattern: "change in shader\\((float|int|bool)\\) <([^>]+)> uniform <([^>]+)> to (.+)",
            replacement: "setShader$1(\"$2\", \"$3\", $4)",
            description: "Set shader uniform",
            category: "shaders"
        },
        {
            pattern: "read from shader\\((float|int|bool)\\) <([^>]+)> uniform <([^>]+)>",
            replacement: "getShader$1(\"$2\", \"$3\")",
            description: "Get shader uniform",
            category: "shaders"
        },

        // ===== VARIABLE DECLARATIONS =====
        {
            pattern: "local <([^>]+)> = (.+)",
            replacement: "local $1 = $2",
            description: "Local variable",
            category: "variables"
        },
        {
            pattern: "global <([^>]+)> = (.+)",
            replacement: "$1 = $2",
            description: "Global variable",
            category: "variables"
        },

        // ===== GROUP OPERATIONS =====
        {
            pattern: "change in group <([^>]+)> at ([^ ]+) property <([^>]+)> to (.+)",
            replacement: 'setPropertyFromGroup("$1", $2, "$3", $4)',
            description: "Set group property",
            category: "groups"
        },
        {
            pattern: "read from group <([^>]+)> at ([^ ]+) property <([^>]+)>",
            replacement: 'getPropertyFromGroup("$1", $2, "$3")',
            description: "Get group property",
            category: "groups"
        },
        {
            pattern: "add <([^>]+)> to group <([^>]+)>",
            replacement: 'addToGroup("$2", "$1")',
            description: "Add object to group",
            category: "groups"
        },
        {
            pattern: "remove <([^>]+)> from group <([^>]+)>",
            replacement: 'removeFromGroup("$2", "$1")',
            description: "Remove object from group",
            category: "groups"
        },

        // ===== CLASS OPERATIONS =====
        {
            pattern: "change in class <([^>]+)> property <([^>]+)> to (.+)",
            replacement: 'setPropertyFromClass("$1", "$2", $3)',
            description: "Set class property",
            category: "classes"
        },
        {
            pattern: "read from class <([^>]+)> property <([^>]+)>",
            replacement: 'getPropertyFromClass("$1", "$2")',
            description: "Get class property",
            category: "classes"
        },

        // ===== CONTROL STRUCTURES =====
        {
            pattern: "if (.+) then",
            replacement: "if $1 then",
            description: "If statement",
            category: "control"
        },
        {
            pattern: "else if (.+) then",
            replacement: "elseif $1 then",
            description: "Else if statement",
            category: "control"
        },

        // ===== RETURN-FREE KEYWORDS =====
        {
            pattern: "\\bproceed\\b",
            replacement: "return Function_Continue",
            description: "Continue script execution",
            category: "control"
        },
        {
            pattern: "\\bhalt\\b",
            replacement: "return Function_Stop",
            description: "Stop this script only",
            category: "control"
        },
        {
            pattern: "\\bhaltLua\\b",
            replacement: "return Function_StopLua",
            description: "Stop Lua scripts",
            category: "control"
        },
        {
            pattern: "\\bhaltScript\\b",
            replacement: "return Function_StopHScript",
            description: "Stop HScripts",
            category: "control"
        },
        {
            pattern: "\\bhaltAll\\b",
            replacement: "return Function_StopAll",
            description: "Stop all scripts",
            category: "control"
        },

        // ===== ANIMATION OPERATIONS =====
        {
            pattern: "play animation <([^>]+)> with value “([^”]+)”, “([^”]+)”, “([^”]+)”",
            replacement: 'playAnim("$1", $2, $3, $4)',
            description: "Play animation with three values",
            category: "animations"
        },
        {
            pattern: "play animation <([^>]+)> with value “([^”]+)”, “([^”]+)”",
            replacement: 'playAnim("$1", $2, $3)',
            description: "Play animation with two values",
            category: "animations"
        },
        {
            pattern: "play animation <([^>]+)> with value “([^”]+)”",
            replacement: 'playAnim("$1", $2)',
            description: "Play animation with one value",
            category: "animations"
        },
        {
            pattern: "add animation <([^>]+)> with value “([^”]+)”, “([^”]+)”, “([^”]+)” to “([^”]+)”",
            replacement: 'addAnimation("$5", "$1", $2, $3, $4)',
            description: "Add animation",
            category: "animations"
        },
        {
            pattern: "add animation by prefix <([^>]+)> with value “([^”]+)”, “([^”]+)”, “([^”]+)” to “([^”]+)”",
            replacement: 'addAnimationByPrefix("$5", "$1", $2, $3, $4)',
            description: "Add animation by prefix",
            category: "animations"
        },
        {
            pattern: "change <([^>]+)> animation to (.+)",
            replacement: 'setProperty(\"$1.animation.curAnim.name\", $2)',
            description: "Set current animation",
            category: "animations"
        },

        // ===== CAMERA OPERATIONS =====
        {
            pattern: "change camera follow <([^>]+)> with value (.+)",
            replacement: 'setCameraFollow("$1", $2)',
            description: "Set camera follow",
            category: "camera"
        },
        {
            pattern: "change camera zoom to (.+), (.+)",
            replacement: "setCameraZoom($1, $2)",
            description: "Set camera zoom",
            category: "camera"
        },
        {
            pattern: "change camera focus on <([^>]+)>",
            replacement: 'setCameraFocus("$1")',
            description: "Focus camera",
            category: "camera"
        },
        {
            pattern: "shake camera (.+), (.+)",
            replacement: "cameraShake($1, $2)",
            description: "Shake camera",
            category: "camera"
        },

        // ===== CHARACTER OPERATIONS =====
        {
            pattern: "change character <([^>]+)> to (.+)",
            replacement: 'setCharacter("$1", $2)',
            description: "Change character",
            category: "characters"
        },
        {
            pattern: "change <([^>]+)> health to (.+)",
            replacement: 'setProperty("$1.health", $2)',
            description: "Set character health",
            category: "characters"
        },
        {
            pattern: "change <([^>]+)> position to (.+) and (.+)",
            replacement: 'setProperty("$1.x", $2)\nsetProperty("$1.y", $3)',
            description: "Set character position",
            category: "characters"
        },

        // ===== SOUND OPERATIONS =====
        {
            pattern: "play sound: (.+), (.+)",
            replacement: "playSound($1, $2)",
            description: "Play a sound",
            category: "sounds"
        },
        {
            pattern: "play music: (.+), (.+)",
            replacement: "playMusic($1, $2)",
            description: "Play background music",
            category: "sounds"
        },
        {
            pattern: "stop sound: (.+)",
            replacement: "stopSound($1)",
            description: "Stop a sound",
            category: "sounds"
        },

        // ===== VISUAL OPERATIONS =====
        {
            pattern: "change <([^>]+)> color to (.+)",
            replacement: 'setProperty("$1.color", $2)',
            description: "Set object color",
            category: "visuals"
        },
        {
            pattern: "change <([^>]+)> alpha to (.+)",
            replacement: 'setProperty("$1.alpha", $2)',
            description: "Set transparency",
            category: "visuals"
        },
        {
            pattern: "change <([^>]+)> scale to (.+) and (.+)",
            replacement: 'setProperty("$1.scale.x", $2)\nsetProperty("$1.scale.y", $3)',
            description: "Set character scale",
            category: "characters"
        },
        {
            pattern: "change <([^>]+)> visible to (.+)",
            replacement: 'setProperty("$1.visible", $2)',
            description: "Set character visibility",
            category: "characters"
        },

        // ===== TWEEN OPERATIONS =====
        {
            pattern: "tween <([^>]+)> to (.+) over (.+) with (.+)",
            replacement: 'doTween("$1", "$1", $2, $3, $4)',
            description: "Tween object property",
            category: "tweens"
        },
        {
            pattern: "tween color of <([^>]+)> to (.+) over (.+)",
            replacement: 'doTweenColor("$1", "$1", $2, $3)',
            description: "Tween color",
            category: "tweens"
        },
        {
            pattern: "tween alpha of <([^>]+)> to (.+) over (.+)",
            replacement: 'doTweenAlpha("$1", "$1", $2, $3)',
            description: "Tween transparency",
            category: "tweens"
        },

        // ===== NOTE OPERATIONS =====
        {
            pattern: "change note at ([^ ]+) property <([^>]+)> to (.+)",
            replacement: 'setPropertyFromGroup("notes", $1, "$2", $3)',
            description: "Set note property",
            category: "notes"
        },
        {
            pattern: "read note at ([^ ]+) property <([^>]+)>",
            replacement: 'getPropertyFromGroup("notes", $1, "$2")',
            description: "Get note property",
            category: "notes"
        },
        {
            pattern: "change all notes of <([^>]+)> to (.+)",
            replacement: 'setProperty("notes.$1", $2)',
            description: "Set all notes property",
            category: "notes"
        },

        // ===== PRINT OPERATIONS =====
        {
            pattern: "print: (.+)",
            replacement: 'print($1)',
            description: "Print to console",
            category: "print"
        },
        {
            pattern: "print\\(debug\\): (.+)",
            replacement: 'debugPrint($1)',
            description: "Debug print to game",
            category: "print"
        },

        // ===== LIBRARY OPERATIONS =====
        {
            pattern: "([a-zA-Z_][a-zA-Z0-9_]*): ([a-zA-Z_][a-zA-Z0-9_]*)<([^>]+)(?:, *<([^>]+)>)*>",
            replacement: "$1.$2($3)",
            description: "Library function call with arguments",
            category: "library"
        },
        // Library property access
        {
            pattern: "([a-zA-Z_][a-zA-Z0-9_]*): ([a-zA-Z_][a-zA-Z0-9_]*)",
            replacement: "$1.$2",
            description: "Library property access",
            category: "library"
        },

        // ===== LOOPS =====
        {
            pattern: "for <([^>]+)> = (.+) do",
            replacement: "for $1 = $2 do",
            description: "Numeric for loop (any expression)",
            category: "control"
        },

        // ===== TABLE OPERATIONS =====
        {
            pattern: "<([^>]+)>\\[([^]]+)\\]",
            replacement: "$1[$2]",
            description: "Table access (any index)",
            category: "tables"
        },
        {
            pattern: "({.+?})",
            replacement: "$1",
            description: "Table literal (any content)",
            category: "tables"
        },
        {
            pattern: "insert (.+) to table <([^>]+)>",
            replacement: "table.insert($2, $1)",
            description: "Insert value into table",
            category: "tables"
        },

        // ===== EVENTS =====
        {
            pattern: "([a-zA-Z]+)<([^>]+)>:",
            replacement: "function $1($2)",
            description: "Event with parameters",
            category: "events"
        },

        // ===== VARIABLE REFERENCES =====
        {
            pattern: "<([^>]+)>",
            replacement: "$1",
            description: "Variable reference",
            category: "variables"
        }
    ];
}