package states.editors;

import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;

import openfl.net.FileFilter;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import backend.ui.*;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.Json;

class NoteRGBExporterState extends MusicBeatState
{
	var strums:FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup();
	var notes:FlxTypedSpriteGroup<Note> = new FlxTypedSpriteGroup();
	var splashes:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup();
	var sustains:FlxTypedSpriteGroup<Note> = new FlxTypedSpriteGroup();

	var backButton:PsychUIButton;
	var exportButton:PsychUIButton;
	var exportSplashButton:PsychUIButton;
	var importButton:PsychUIButton;
	var disableRGBCheckbox:PsychUICheckBox;

	var _file:FileReference;
	var disableNoteRGB:Bool = false;

	override function create()
	{
		FlxG.mouse.visible = true;
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Note RGB Exporter');
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF353535;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		for (i in 0...4)
		{
			var strum:StrumNote = new StrumNote(100, FlxG.height / 3 - 50 + (i * 120), i, 0);
			strum.ID = i;
			strums.add(strum);
		}

		for (i in 0...4)
		{
			var note:Note = new Note(0, i);
			Note.initializeGlobalRGBShader(i);
			note.defaultRGB();
			note.x = FlxG.width - 200;
			note.y = FlxG.height / 3 - 50 + (i * 120);
			note.scrollFactor.set();
			notes.add(note);
		}

		for (i in 0...4)
		{
			var strum:StrumNote = strums.members[i];
			var splash:NoteSplash = new NoteSplash();
			splash.inEditor = true;
			splash.babyArrow = strum;
			splash.spawnSplashNote(FlxG.width / 2 - 150 + (i * 100), 100, i, null);
			if (splash.animation.curAnim != null)
			{
				splash.animation.curAnim.looped = true;
			}
			splashes.add(splash);
		}

		for (i in 0...4)
		{
			var sustain:Note = new Note(0, i);
			Note.initializeGlobalRGBShader(i);
			sustain.defaultRGB();
			sustain.isSustainNote = true;
			sustain.sustainLength = 100;
			sustain.x = FlxG.width / 2 - 150 + (i * 100);
			sustain.y = FlxG.height - 200;
			sustain.scrollFactor.set();
			sustains.add(sustain);
		}

		add(strums);
		add(notes);
		add(splashes);
		add(sustains);

		backButton = new PsychUIButton(20, FlxG.height - 50, "Back", function()
		{
			MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		});
		backButton.resize(100, 40);
		add(backButton);

		exportButton = new PsychUIButton(FlxG.width - 200, FlxG.height - 50, "Export Spritesheet", function()
		{
			exportSpritesheet();
		});
		exportButton.resize(150, 40);
		add(exportButton);

		exportSplashButton = new PsychUIButton(180, 70, "Export Splash", function()
		{
			exportSplashTexture();
		});
		exportSplashButton.resize(150, 40);
		add(exportSplashButton);

		importButton = new PsychUIButton(20, 20, "Import Spritesheet", function()
		{
			importSpritesheet();
		});
		importButton.resize(150, 40);
		add(importButton);

		disableRGBCheckbox = new PsychUICheckBox(FlxG.width - 200, 20, "Disable note RGB", 100, function()
		{
			disableNoteRGB = disableRGBCheckbox.checked;
			updateRGB();
		});
		disableRGBCheckbox.checked = disableNoteRGB;
		add(disableRGBCheckbox);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.LEFT)
		{
			playStrumAnim(0);
		}
		else if (FlxG.keys.justPressed.DOWN)
		{
			playStrumAnim(1);
		}
		else if (FlxG.keys.justPressed.UP)
		{
			playStrumAnim(2);
		}
		else if (FlxG.keys.justPressed.RIGHT)
		{
			playStrumAnim(3);
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new states.editors.MasterEditorMenu());
		}
	}

	function playStrumAnim(id:Int)
	{
		var strum = strums.members[id];
		if (strum != null)
		{
			strum.playAnim('static', true);
			strum.playAnim('pressed', true);
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				strum.playAnim('static', true);
			});
		}
	}

	function updateRGB()
	{
		for (note in notes)
		{
			if (note.rgbShader != null)
			{
				note.rgbShader.enabled = !disableNoteRGB;
			}
		}

		for (sustain in sustains)
		{
			if (sustain.rgbShader != null)
			{
				sustain.rgbShader.enabled = !disableNoteRGB;
			}
		}

		for (splash in splashes)
		{
			if (splash.rgbShader != null)
			{
				splash.rgbShader.enabled = !disableNoteRGB;
			}
		}
	}

	var _xmlData:String = null;

	function exportSplashTexture()
	{
		var splashTexture = splashes.members[0].texture;
		if (splashTexture == null) return;

		var splashGraphic = Paths.image(splashTexture);
		if (splashGraphic == null) return;

		var originalBitmap = splashGraphic.bitmap;
		var splashWidth = originalBitmap.width;
		var splashHeight = originalBitmap.height;
		var totalWidth = splashWidth * 4;
		var totalHeight = splashHeight;

		var bitmapData = new openfl.display.BitmapData(totalWidth, totalHeight, true, 0x00000000);

		for (i in 0...4)
		{
			var splash = splashes.members[i];
			if (splash != null)
			{
				var tempBitmap = originalBitmap.clone();
				if (splash.config != null && splash.config.rgb != null && splash.config.rgb[splash.noteData] != null)
				{
					var rgb = splash.config.rgb[splash.noteData];
					var mult = 1.0;
					if (splash.rgbShader != null)
					{
						if (Reflect.hasField(splash.rgbShader, 'mult'))
						{
							mult = Reflect.field(splash.rgbShader, 'mult');
						}
						else if (Reflect.hasField(splash.rgbShader, 'parent'))
						{
							var parent = Reflect.field(splash.rgbShader, 'parent');
							if (parent != null && Reflect.hasField(parent, 'mult'))
							{
								mult = Reflect.field(parent, 'mult');
							}
						}
					}
					applyRGBBlend(tempBitmap, rgb.r, rgb.g, rgb.b, mult);
				}
				bitmapData.draw(tempBitmap, new openfl.geom.Matrix(1, 0, 0, 1, i * splashWidth, 0));
			}
		}

		var pngData = bitmapData.encode(bitmapData.rect, new openfl.display.PNGEncoderOptions());

		var pngFile = new FileReference();
		pngFile.save(pngData, "splashRGB.png");
	}

	function applyRGBBlend(bitmap:openfl.display.BitmapData, r:FlxColor, g:FlxColor, b:FlxColor, mult:Float = 1.0)
	{
		var rVec = [r.redFloat, r.greenFloat, r.blueFloat];
		var gVec = [g.redFloat, g.greenFloat, g.blueFloat];
		var bVec = [b.redFloat, b.greenFloat, b.blueFloat];

		for (x in 0...bitmap.width)
		{
			for (y in 0...bitmap.height)
			{
				var pixel = bitmap.getPixel32(x, y);
				var alpha = (pixel >> 24) & 0xFF;
				if (alpha > 0)
				{
					var origR = ((pixel >> 16) & 0xFF) / 255.0;
					var origG = ((pixel >> 8) & 0xFF) / 255.0;
					var origB = (pixel & 0xFF) / 255.0;

					var newR = Math.min(origR * rVec[0] + origG * rVec[1] + origB * rVec[2], 1.0);
					var newG = Math.min(origR * gVec[0] + origG * gVec[1] + origB * gVec[2], 1.0);
					var newB = Math.min(origR * bVec[0] + origG * bVec[1] + origB * bVec[2], 1.0);

					var finalR = origR * (1.0 - mult) + newR * mult;
					var finalG = origG * (1.0 - mult) + newG * mult;
					var finalB = origB * (1.0 - mult) + newB * mult;

					var red = Std.int(finalR * 255);
					var green = Std.int(finalG * 255);
					var blue = Std.int(finalB * 255);

					bitmap.setPixel32(x, y, (alpha << 24) | (red << 16) | (green << 8) | blue);
				}
			}
		}
	}

	function exportSpritesheet()
	{
		var spritesheetData = generateSpritesheetData();
		_xmlData = generateXML(spritesheetData);

		var noteSkinPath = Note.defaultNoteSkin;
		var originalGraphic = Paths.image(noteSkinPath);
		var originalBitmap = originalGraphic.bitmap;

		var noteWidth = originalBitmap.width;
		var noteHeight = originalBitmap.height;
		var totalWidth = noteWidth * 4;
		var totalHeight = noteHeight * 2;

		var bitmapData = new openfl.display.BitmapData(totalWidth, totalHeight, true, 0x00000000);

		for (note in notes)
		{
			if (note != null)
			{
				var tempBitmap = originalBitmap.clone();
				if (note.rgbShader != null)
				{
					applyRGBBlend(tempBitmap, note.rgbShader.r, note.rgbShader.g, note.rgbShader.b, note.rgbShader.mult);
				}
				bitmapData.draw(tempBitmap, new openfl.geom.Matrix(1, 0, 0, 1, note.noteData * noteWidth, 0));
			}
		}

		for (sustain in sustains)
		{
			if (sustain != null)
			{
				var tempBitmap = originalBitmap.clone();
				if (sustain.rgbShader != null)
				{
					applyRGBBlend(tempBitmap, sustain.rgbShader.r, sustain.rgbShader.g, sustain.rgbShader.b, sustain.rgbShader.mult);
				}
				bitmapData.draw(tempBitmap, new openfl.geom.Matrix(1, 0, 0, 1, sustain.noteData * noteWidth, noteHeight * 2));
			}
		}

		var pngData = bitmapData.encode(bitmapData.rect, new openfl.display.PNGEncoderOptions());

		var pngFile = new FileReference();
		pngFile.addEventListener(Event.COMPLETE, onPNGSaveComplete);
		pngFile.addEventListener(Event.CANCEL, onPNGSaveCancel);
		pngFile.addEventListener(IOErrorEvent.IO_ERROR, onPNGSaveError);
		pngFile.save(pngData, "noteRGB.png");
	}

	function onPNGSaveComplete(_):Void
	{
		var pngFile = cast(_.target, FileReference);
		pngFile.removeEventListener(Event.COMPLETE, onPNGSaveComplete);
		pngFile.removeEventListener(Event.CANCEL, onPNGSaveCancel);
		pngFile.removeEventListener(IOErrorEvent.IO_ERROR, onPNGSaveError);

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			saveXML();
		});
	}

	function onPNGSaveCancel(_):Void
	{
		var pngFile = cast(_.target, FileReference);
		pngFile.removeEventListener(Event.COMPLETE, onPNGSaveComplete);
		pngFile.removeEventListener(Event.CANCEL, onPNGSaveCancel);
		pngFile.removeEventListener(IOErrorEvent.IO_ERROR, onPNGSaveError);

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			saveXML();
		});
	}

	function onPNGSaveError(_):Void
	{
		var pngFile = cast(_.target, FileReference);
		pngFile.removeEventListener(Event.COMPLETE, onPNGSaveComplete);
		pngFile.removeEventListener(Event.CANCEL, onPNGSaveCancel);
		pngFile.removeEventListener(IOErrorEvent.IO_ERROR, onPNGSaveError);

		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			saveXML();
		});
	}

	function saveXML()
	{
		if (_xmlData != null)
		{
			var xmlFile = new FileReference();
			xmlFile.addEventListener(Event.COMPLETE, onXMLSaveComplete);
			xmlFile.addEventListener(Event.CANCEL, onXMLSaveCancel);
			xmlFile.addEventListener(IOErrorEvent.IO_ERROR, onXMLSaveError);
			xmlFile.save(_xmlData, "noteRGB.xml");
		}
	}

	function onXMLSaveComplete(_):Void
	{
		var xmlFile = cast(_.target, FileReference);
		xmlFile.removeEventListener(Event.COMPLETE, onXMLSaveComplete);
		xmlFile.removeEventListener(Event.CANCEL, onXMLSaveCancel);
		xmlFile.removeEventListener(IOErrorEvent.IO_ERROR, onXMLSaveError);
		_xmlData = null;
	}

	function onXMLSaveCancel(_):Void
	{
		var xmlFile = cast(_.target, FileReference);
		xmlFile.removeEventListener(Event.COMPLETE, onXMLSaveComplete);
		xmlFile.removeEventListener(Event.CANCEL, onXMLSaveCancel);
		xmlFile.removeEventListener(IOErrorEvent.IO_ERROR, onXMLSaveError);
		_xmlData = null;
	}

	function onXMLSaveError(_):Void
	{
		var xmlFile = cast(_.target, FileReference);
		xmlFile.removeEventListener(Event.COMPLETE, onXMLSaveComplete);
		xmlFile.removeEventListener(Event.CANCEL, onXMLSaveCancel);
		xmlFile.removeEventListener(IOErrorEvent.IO_ERROR, onXMLSaveError);
		_xmlData = null;
	}

	function importSpritesheet()
	{
		var xmlFilter:FileFilter = new FileFilter('XML Files', '*.xml');
		var pngFilter:FileFilter = new FileFilter('PNG Files', '*.png');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([xmlFilter, pngFilter]);
	}

	function generateSpritesheetData():Dynamic
	{
		var data = {
			notes: [],
			splashes: [],
			sustains: []
		};

		for (note in notes)
		{
			data.notes.push({
				id: note.noteData,
				r: note.rgbShader != null ? note.rgbShader.r : 0xFFFF0000,
				g: note.rgbShader != null ? note.rgbShader.g : 0xFF00FF00,
				b: note.rgbShader != null ? note.rgbShader.b : 0xFF0000FF
			});
		}

		for (splash in splashes)
		{
			var rgb = (splash.config != null && splash.config.rgb != null && splash.config.rgb[splash.noteData] != null) ? splash.config.rgb[splash.noteData] : null;
			data.splashes.push({
				id: splash.ID,
				r: rgb != null && rgb.r != null ? rgb.r : 0xFFFF0000,
				g: rgb != null && rgb.g != null ? rgb.g : 0xFF00FF00,
				b: rgb != null && rgb.b != null ? rgb.b : 0xFF0000FF
			});
		}

		for (sustain in sustains)
		{
			data.sustains.push({
				id: sustain.noteData,
				r: sustain.rgbShader != null ? sustain.rgbShader.r : 0xFFFF0000,
				g: sustain.rgbShader != null ? sustain.rgbShader.g : 0xFF00FF00,
				b: sustain.rgbShader != null ? sustain.rgbShader.b : 0xFF0000FF
			});
		}

		return data;
	}

	function generateXML(data:Dynamic):String
	{
		var xml:String = '<?xml version="1.0" encoding="UTF-8"?>\n';
		xml += '<TextureAtlas imagePath="noteRGB.png">\n';

		for (note in cast(data.notes, Array<Dynamic>))
		{
			xml += '  <SubTexture name="note${note.id}" x="${note.id * 100}" y="0" width="100" height="100" r="${note.r}" g="${note.g}" b="${note.b}"/>\n';
		}

		for (splash in cast(data.splashes, Array<Dynamic>))
		{
			xml += '  <SubTexture name="splash${splash.id}" x="${splash.id * 100}" y="100" width="100" height="100" r="${splash.r}" g="${splash.g}" b="${splash.b}"/>\n';
		}

		for (sustain in cast(data.sustains, Array<Dynamic>))
		{
			xml += '  <SubTexture name="sustain${sustain.id}" x="${sustain.id * 100}" y="200" width="100" height="100" r="${sustain.r}" g="${sustain.g}" b="${sustain.b}"/>\n';
		}

		xml += '</TextureAtlas>';
		return xml;
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file.addEventListener(Event.COMPLETE, onFileLoadComplete);
		_file.load();
	}

	function onFileLoadComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onFileLoadComplete);

		try
		{
			var fileName:String = _file.name.toLowerCase();
			var fileContent:Dynamic = _file.data;

			if (fileContent != null)
			{
				if (fileName.endsWith('.xml'))
				{
					parseXML(fileContent);
				}
				else if (fileName.endsWith('.png'))
				{
					loadPNG(fileContent);
				}
			}
		}
		catch (e)
		{
			trace(e.stack);
		}
	}

	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
	}

	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
	}

	function parseXML(xmlContent:String)
	{
		var xml:Xml = Xml.parse(xmlContent);
		var atlas = xml.firstElement();

		for (subTexture in atlas.elements())
		{
			var name:String = subTexture.get("name");
			var r:Int = Std.parseInt(subTexture.get("r"));
			var g:Int = Std.parseInt(subTexture.get("g"));
			var b:Int = Std.parseInt(subTexture.get("b"));

			if (name.startsWith("note"))
			{
				var id = Std.parseInt(name.substr(4));
				var note = notes.members[id];
				if (note != null && note.rgbShader != null)
				{
					note.rgbShader.r = r;
					note.rgbShader.g = g;
					note.rgbShader.b = b;
				}
			}
			else if (name.startsWith("splash"))
			{
				var id = Std.parseInt(name.substr(6));
				var splash = splashes.members[id];
				if (splash != null && splash.config != null)
				{
					if (splash.config.rgb == null) splash.config.rgb = [];
					if (splash.config.rgb[splash.noteData] == null) splash.config.rgb[splash.noteData] = {r: null, g: null, b: null};
					splash.config.rgb[splash.noteData].r = r;
					splash.config.rgb[splash.noteData].g = g;
					splash.config.rgb[splash.noteData].b = b;
				}
			}
			else if (name.startsWith("sustain"))
			{
				var id = Std.parseInt(name.substr(6));
				var sustain = sustains.members[id];
				if (sustain != null && sustain.rgbShader != null)
				{
					sustain.rgbShader.r = r;
					sustain.rgbShader.g = g;
					sustain.rgbShader.b = b;
				}
			}
		}
	}

	function loadPNG(pngBytes:haxe.io.Bytes)
	{
		openfl.display.BitmapData.loadFromBytes(pngBytes).onComplete(function(bitmapData:openfl.display.BitmapData)
		{
			for (note in notes)
			{
				var noteBitmap = new openfl.display.BitmapData(100, 100, true);
				noteBitmap.copyPixels(bitmapData, new openfl.geom.Rectangle(note.noteData * 100, 0, 100, 100), new openfl.geom.Point(0, 0));
				note.loadGraphic(noteBitmap);
			}

			for (splash in splashes)
			{
				var splashBitmap = new openfl.display.BitmapData(100, 100, true);
				splashBitmap.copyPixels(bitmapData, new openfl.geom.Rectangle(splash.ID * 100, 100, 100, 100), new openfl.geom.Point(0, 0));
				splash.loadGraphic(splashBitmap);
			}

			for (sustain in sustains)
			{
				var sustainBitmap = new openfl.display.BitmapData(100, 100, true);
				sustainBitmap.copyPixels(bitmapData, new openfl.geom.Rectangle(sustain.noteData * 100, 200, 100, 100), new openfl.geom.Point(0, 0));
				sustain.loadGraphic(sustainBitmap);
			}
		});
	}

	override function destroy()
	{
		if (_file != null)
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.removeEventListener(Event.SELECT, onLoadComplete);
			_file = null;
		}

		FlxG.sound.music.volume = 1;
		FlxG.sound.muteKeys = [FlxKey.ZERO];
		FlxG.sound.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
		FlxG.sound.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

		super.destroy();
	}
}