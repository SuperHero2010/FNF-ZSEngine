package zsscript;

import zsscript.ZSPatternGenerator.Pattern;
import zsscript.ZSPatternGenerator.ParamDef;

class ZSPatterns {
    public static var patterns:Array<Pattern> = [];
    public static var initialized:Bool = false;
    
    public static function getPatterns():Array<Pattern> {
        if (!initialized) {
            patterns = zsscript.ZSPatternGenerator.generateAll();
            initialized = true;
        }
        return patterns;
    }
}