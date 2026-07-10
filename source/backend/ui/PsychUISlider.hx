package backend.ui;

import flixel.addons.ui.FlxSlider;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PsychUISlider extends FlxSlider
{
	public var label(get, set):String;
	public var labelText:FlxText;

	public function new(x:Float = 0, y:Float = 0, callback:Float->Void, def:Float = 0, min:Float = -999, max:Float = 999, wid:Float = 200, mainColor:FlxColor = FlxColor.WHITE, handleColor:FlxColor = 0xFFAAAAAA)
	{
		super(null, "", x, y, min, max, Std.int(wid), 15, 3, mainColor, handleColor);

		this.callback = callback;

		this.value = def;
		this.minValue = min;
		this.maxValue = max;

		body.color = mainColor;
		handle.color = handleColor;

		if (nameLabel != null) {
			nameLabel.visible = false;
		}

		labelText = new FlxText(x, y, wid, "");
		labelText.alignment = CENTER;
		labelText.color = mainColor;
		labelText.scrollFactor.set();
		add(labelText);

		if (minLabel != null) {
			minLabel.text = Std.string(min);
		}
		if (maxLabel != null) {
			maxLabel.text = Std.string(max);
		}

		updatePositions();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (valueLabel != null) {
			valueLabel.color = handle.color;
		}
	}

	function updatePositions():Void
	{
		if (labelText != null) {
			labelText.x = x;
			labelText.y = y;

			if (body != null) {
				body.y = labelText.y + labelText.height + 4;
			}
			if (handle != null) {
				handle.y = body.y + body.height/2 - handle.height/2;
			}
		}
	}

	function set_label(v:String):String
	{
		if (labelText != null) {
			labelText.text = v;
			updatePositions();
		}
		return v;
	}

	function get_label():String
	{
		if (labelText != null) {
			return labelText.text;
		}
		return "";
	}

	override function set_x(value:Float):Float
	{
		super.set_x(value);
		updatePositions();
		return x = value;
	}

	override function set_y(value:Float):Float
	{
		super.set_y(value);
		updatePositions();
		return y = value;
	}

	override function set_min(v:Float):Float
	{
		minValue = v;
		if (minLabel != null) {
			minLabel.text = Std.string(v);
		}
		return minValue = v;
	}

	override function set_max(v:Float):Float
	{
		maxValue = v;
		if (maxLabel != null) {
			maxLabel.text = Std.string(v);
		}
		return maxValue = v;
	}

	override function set_decimals(v:Int):Int
	{
		decimals = v;
		if (minLabel != null) {
			minLabel.text = Std.string(FlxMath.roundDecimal(minValue, decimals));
		}
		if (maxLabel != null) {
			maxLabel.text = Std.string(FlxMath.roundDecimal(maxValue, decimals));
		}
		if (valueLabel != null) {
			valueLabel.text = Std.string(FlxMath.roundDecimal(value, decimals));
		}
		return decimals = v;
	}
}