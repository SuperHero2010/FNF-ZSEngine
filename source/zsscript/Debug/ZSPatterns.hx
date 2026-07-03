package;

import ZSPatternGenerator.Pattern;
import ZSPatternGenerator.ParamDef;

class ZSPatterns {
    public static var patterns:Array<Pattern> = [];
    public static var initialized:Bool = false;
    
    public static function getPatterns():Array<Pattern> {
        if (!initialized) {
            patterns = ZSPatternGenerator.generateAll();
            initialized = true;
        }
        return patterns;
    }
}