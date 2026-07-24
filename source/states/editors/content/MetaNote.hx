package states.editors.content;

import objects.Note;
import shaders.RGBPalette;
import flixel.util.FlxDestroyUtil;

class MetaNote extends Note
{
	public static var noteTypeTexts:Map<Int, FlxText> = [];
	public var isEvent:Bool = false;
	public var songData:Array<Dynamic>;
	public var sustainSprite:FlxSprite;
	public var chartY:Float = 0;
	public var chartNoteData:Int = 0;

	public function new(time:Float, data:Int, songData:Array<Dynamic>)
	{
		trace('=== MetaNote constructor ===');
		trace('time: ' + time);
		trace('data: ' + data);
		trace('songData: ' + songData);

		super(time, data, null, false, true);

		this.songData = songData;
		this.strumTime = time;
		this.chartNoteData = data;
	}

	public function changeNoteData(v:Int)
	{
		this.chartNoteData = v; //despite being so arbitrary its sadly needed to fix a bug on moving notes
		this.songData[1] = v;
		this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
		this.mustPress = (v < ChartingState.GRID_COLUMNS_PER_PLAYER);

		if(!PlayState.isPixelStage)
			loadNoteAnims();
		else
			loadPixelNoteAnims();

		if(Note.globalRgbShaders.contains(rgbShader.parent)) //Is using a default shader
			rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

		animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
		updateHitbox();
		if(width > height)
			setGraphicSize(ChartingState.GRID_SIZE);
		else
			setGraphicSize(0, ChartingState.GRID_SIZE);

		updateHitbox();
	}

	public function setStrumTime(v:Float)
	{
		this.songData[0] = v;
		this.strumTime = v;
	}

	var _lastZoom:Float = -1;
	public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1)
	{
		_lastZoom = zoom;
		v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
		songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

		if(sustainLength > 0)
		{
			if(sustainSprite == null)
			{
				sustainSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
				sustainSprite.scrollFactor.x = 0;
			}
			sustainSprite.setGraphicSize(8, Math.max(ChartingState.GRID_SIZE/4, (Math.round((v * ChartingState.GRID_SIZE + ChartingState.GRID_SIZE) / stepCrochet) * zoom) - ChartingState.GRID_SIZE/2));
			sustainSprite.updateHitbox();
		}
	}

	public var hasSustain(get, never):Bool;
	function get_hasSustain() return (!isEvent && sustainLength > 0);

	public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1)
	{
		if(_lastZoom == zoom) return;
		setSustainLength(sustainLength, stepCrochet, zoom);
	}

	public function updateSustainToStepCrochet(stepCrochet:Float)
	{
		if(_lastZoom < 0) return;
		setSustainLength(sustainLength, stepCrochet, _lastZoom);
	}

	var _noteTypeText:FlxText;
	public function findNoteTypeText(num:Int)
	{
		var txt:FlxText = null;
		if(num != 0)
		{
			if(!noteTypeTexts.exists(num))
			{
				txt = new FlxText(0, 0, ChartingState.GRID_SIZE, (num > 0) ? Std.string(num) : '?', 16);
				txt.autoSize = false;
				txt.alignment = CENTER;
				txt.borderStyle = SHADOW;
				txt.shadowOffset.set(2, 2);
				txt.borderColor = FlxColor.BLACK;
				txt.scrollFactor.x = 0;
				noteTypeTexts.set(num, txt);
			}
			else txt = noteTypeTexts.get(num);
		}
		return (_noteTypeText = txt);
	}

	override function draw()
	{
		if(sustainSprite != null && sustainSprite.exists && sustainSprite.visible && sustainLength > 0)
		{
			sustainSprite.x = this.x + this.width/2 - sustainSprite.width/2;
			sustainSprite.y = this.y + this.height/2;
			sustainSprite.alpha = this.alpha;
			sustainSprite.draw();
		}
		super.draw();

		if(_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible)
		{
			_noteTypeText.x = this.x + this.width/2 - _noteTypeText.width/2;
			_noteTypeText.y = this.y + this.height/2 - _noteTypeText.height/2;
			_noteTypeText.alpha = this.alpha;
			_noteTypeText.draw();
		}
	}

	override function destroy()
	{
		sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
		super.destroy();
	}
}

class EventMetaNote extends MetaNote
{
	public var eventText:FlxText;
	public function new(time:Float, eventData:Dynamic)
	{
		super(time, -1, eventData);
		this.isEvent = true;
		events = [];

		trace('=== EventMetaNote constructor ===');
		trace('time: ' + time);
		trace('eventData: ' + eventData);
		trace('eventData length: ' + (eventData != null ? eventData.length : 'null'));

		try
		{
			trace('eventData[0]: ' + (eventData != null ? eventData[0] : 'null'));
			trace('eventData[1]: ' + (eventData != null ? eventData[1] : 'null'));

			var outer:Dynamic = (eventData != null) ? eventData[1] : null;
			var isOuterArray:Bool = (outer != null && Std.isOfType(outer, Array));
			trace('outer is Array? ' + isOuterArray);

			if (outer != null && Std.isOfType(outer, Array))
			{
				trace('outer is Array, length: ' + outer.length);
				var outerArr:Array<Dynamic> = cast outer;
				for (entry in outerArr)
				{
					trace('entry: ' + entry);
					if (entry != null && Std.isOfType(entry, Array))
					{
						trace('entry is Array: ' + entry);
						events.push(cast entry);
					}
					else
					{
						trace('entry is not Array, wrapping: ' + entry);
						events.push([entry]);
					}
				}
			}
			else
			{
				trace('outer is null or not an Array. Value: ' + outer);
			}
		}
		catch (e:Dynamic)
		{
			trace('Error parsing event data: ' + e);
		}

		trace('Final events: ' + events);
		trace('events.length: ' + events.length);

		loadGraphic(Paths.image('editors/eventIcon'));
		setGraphicSize(ChartingState.GRID_SIZE);
		updateHitbox();

		eventText = new FlxText(0, 0, 400, '', 12);
		eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
		eventText.scrollFactor.x = 0;
		eventText.antialiasing = ClientPrefs.data.antialiasing;
		updateEventText();
	}

	override function draw()
	{
		if(eventText != null && eventText.exists && eventText.visible)
		{
			eventText.y = this.y + this.height/2 - eventText.height/2;
			eventText.alpha = this.alpha;
			eventText.draw();
		}
		super.draw();
	}

	override function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

	public var events:Array<Array<String>>;
	public function updateEventText()
	{
		if (eventText == null) return;

		var myTime:Float = Math.floor(this.strumTime);
		if (events == null) events = [];
		if (events.length == 0)
		{
			eventText.text = 'Event at $myTime ms (no data)';
			return;
		}

		if (events.length == 1)
		{
			var event = events[0];
			var name:String = (event != null && event.length > 0 && event[0] != null) ? Std.string(event[0]) : 'Unknown';
			var v1:String = (event != null && event.length > 1 && event[1] != null) ? Std.string(event[1]) : '';
			var v2:String = (event != null && event.length > 2 && event[2] != null) ? Std.string(event[2]) : '';
			eventText.text = 'Event: ${name} ($myTime ms)\nValue 1: ${v1}\nValue 2: ${v2}';
		}
		else if (events.length > 1)
		{
			var eventNames:Array<String> = [for (event in events) (event != null && event.length > 0 && event[0] != null) ? Std.string(event[0]) : 'Unknown'];
			eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
		}
		else
		{
			eventText.text = 'ERROR FAILSAFE';
		}
	}

	public function updateSongDataFromEvents()
	{
		if(songData != null && songData.length > 1)
		{
			songData[1] = events.copy();
		}
	}

	override function destroy()
	{
		eventText = FlxDestroyUtil.destroy(eventText);
		super.destroy();
	}
}