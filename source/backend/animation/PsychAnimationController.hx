package backend.animation;

import flixel.animation.FlxAnimationController;

class PsychAnimationController extends FlxAnimationController {
    public var followGlobalSpeed:Bool = true;

    override function get_frameName():String
    {
        if (_sprite != null && _sprite.frame != null)
        {
            final frameName:String = _sprite.frame.name;
            if (frameName != null && frameName != '')
                return frameName;
        }

        if (_curAnim != null && _curAnim.numFrames > 0)
        {
            final index:Int = _curAnim.curFrame;
            if (index >= 0 && index < _curAnim.frames.length)
            {
                final animFrame = _curAnim.frames[index];
                if (animFrame != null && animFrame.name != null && animFrame.name != '')
                    return animFrame.name;
            }

            if (_curAnim.name != null && _curAnim.name != '')
                return _curAnim.name;
        }

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