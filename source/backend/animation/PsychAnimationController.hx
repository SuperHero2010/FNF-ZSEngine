package backend.animation;

import flixel.animation.FlxAnimationController;

class PsychAnimationController extends FlxAnimationController {
    public var followGlobalSpeed:Bool = true;

    public function getLuaFrameName():String
    {
        if (_sprite != null && _sprite.frame != null)
        {
            final frameName:String = _sprite.frame.name;
            if (frameName != null && frameName != '')
                return frameName;
        }

        if (_sprite != null && _sprite.frames != null && frameIndex >= 0 && frameIndex < _sprite.frames.frames.length)
        {
            final atlasFrame = _sprite.frames.frames[frameIndex];
            if (atlasFrame != null && atlasFrame.name != null && atlasFrame.name != '')
                return atlasFrame.name;
        }

        final animName:String = name;
        if (animName != null && animName != '')
            return animName;

        return '';
    }

    public override function update(elapsed:Float):Void {
		if (_curAnim != null) {
            var speed:Float = timeScale;
            if (followGlobalSpeed) speed *= FlxG.animationTimeScale;
			_curAnim.update(elapsed * speed);
		}
		else if (_prerotated != null) {
			_prerotated.angle = _sprite.angle;
		}
	}
}