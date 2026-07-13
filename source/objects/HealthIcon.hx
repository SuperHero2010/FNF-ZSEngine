package objects;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	private var iconType:String = 'normal';

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true)
	{
		if (this.char != char)
		{
			this.char = char;
			loadIcon(char, 'normal', allowGPU);
			iconType = 'normal';
			antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	public function setIconState(state:String):Void
	{
		if (state == 'normal' || state == 'lose' || state == 'win')
		{
			iconType = state;
			loadIcon(char, state);
		}
	}

	private function loadIcon(char:String, state:String = 'normal', ?allowGPU:Bool = true):Void
	{
		var suffix:String = '';
		switch (state)
		{
			case 'lose': suffix = '-lose';
			case 'win': suffix = '-win';
			default: suffix = '';
		}

		var path:String = 'icons/' + char + suffix;

		var xmlPath:String = path + '.xml';
		if (Paths.fileExists('images/' + xmlPath, TEXT))
		{
			var xml = Paths.xml(xmlPath);
			var image = Paths.image(path, allowGPU);

			loadGraphic(image, true, Math.floor(image.width), Math.floor(image.height));
			animation.addByPrefix(char, xml, 24, true);
			animation.play(char);
			updateHitbox();
			return;
		}

		if (!Paths.fileExists('images/' + path + '.png', IMAGE))
		{
			path = 'icons/icon-' + char + suffix;
			if (!Paths.fileExists('images/' + path + '.png', IMAGE))
			{
				path = 'icons/icon-face' + suffix;
				if (!Paths.fileExists('images/' + path + '.png', IMAGE))
				path = 'icons/icon-face';
			}
		}

		var graphic = Paths.image(path, allowGPU);
		loadGraphic(graphic, true, Math.floor(graphic.width), Math.floor(graphic.height));
		updateHitbox();
	}

	public function getCharacter():String
	{
		return char;
	}

	public function getIconState():String
	{
		return iconType;
	}
}