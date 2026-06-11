package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;

import backend.Song;
import backend.SongJson;
import backend.ui.*;
import states.editors.content.FileDialogHandler;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class MergeChartState extends MusicBeatState
{
	private var chartBoxes:Array<ChartBox> = [];
	private var selectedCharts:Array<String> = [];
	private var mergeButton:PsychUIButton;
	private var fileDialog:FileDialogHandler;
	private var progressText:FlxText;
	private var progressBg:FlxSprite;
	private var syncTime:Float = 0;
	private var progressUpdateTime:Float = 0.1;
	var indentation:Bool = false;
	var mergeChartSave:FlxSave = new FlxSave();
	var indentationCheckbox:PsychUICheckBox;

	override function create()
	{
		mergeChartSave.bind("MergeChartState", CoolUtil.getSavePath());
		super.create();

		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFF353535;
		add(bg);

		var titleText:FlxText = new FlxText(0, 20, FlxG.width, "Chart Merger", 40);
		titleText.alignment = CENTER;
		add(titleText);

		var boxWidth:Float = 200;
		var boxHeight:Float = 150;
		var spacing:Float = 20;
		var startX:Float = (FlxG.width - (5 * boxWidth + 4 * spacing)) / 2;
		var startY:Float = 100;

		for (i in 0...5)
		{
			var box:ChartBox = new ChartBox(startX + i * (boxWidth + spacing), startY, boxWidth, boxHeight, i);
			box.setUnlocked(true);
			chartBoxes.push(box);
			add(box);
		}
		for (i in 0...5)
		{
			var box:ChartBox = new ChartBox(startX + i * (boxWidth + spacing), startY * 2.5, boxWidth, boxHeight, i);
			box.setUnlocked(true);
			chartBoxes.push(box);
			add(box);
		}
		for (i in 0...5)
		{
			var box:ChartBox = new ChartBox(startX + i * (boxWidth + spacing), startY * 4, boxWidth, boxHeight, i);
			box.setUnlocked(true);
			chartBoxes.push(box);
			add(box);
		}

		mergeButton = new PsychUIButton(FlxG.width / 2 - 75, startY + boxHeight + 350, "Merge Charts", onMergeButton);
		mergeButton.resize(150, 40);
		mergeButton.normalStyle.bgColor = FlxColor.GREEN;
		mergeButton.normalStyle.textColor = FlxColor.BLACK;
		add(mergeButton);

		var backButton:PsychUIButton = new PsychUIButton(20, FlxG.height - 60, "Back", onBackButton);
		backButton.resize(100, 40);
		add(backButton);

		indentationCheckbox = new PsychUICheckBox(20, backButton.y - 30, "Use Indentation", 140, function() {
			mergeChartSave.data.indentation = indentationCheckbox.checked;
			mergeChartSave.flush();
			indentation = indentationCheckbox.checked;
		});
		indentationCheckbox.checked = (mergeChartSave.data.indentation == true);
		indentation = indentationCheckbox.checked;
		add(indentationCheckbox);

		progressBg = new FlxSprite(FlxG.width / 2 - 200, FlxG.height / 2 - 50).makeGraphic(400, 100, FlxColor.GRAY);
		progressBg.alpha = 0.8;
		progressBg.visible = false;
		add(progressBg);

		progressText = new FlxText(FlxG.width / 2 - 180, FlxG.height / 2 - 30, 360, "", 20);
		progressText.alignment = CENTER;
		progressText.visible = false;
		add(progressText);

		fileDialog = new FileDialogHandler();
		add(fileDialog);
		fileDialog.onComplete = onFileSelected;

		if (mergeChartSave.data.indentation == null) mergeChartSave.data.indentation = false;
		indentation = mergeChartSave.data.indentation;
	}

	private function onFileSelected()
	{
		if (fileDialog.path != null && fileDialog.path.length > 0)
		{
			for (box in chartBoxes)
			{
				if (box.isWaitingForPath)
				{
					box.setChartPath(fileDialog.path);
					box.isWaitingForPath = false;

					if (!selectedCharts.contains(fileDialog.path))
					{
						selectedCharts.push(fileDialog.path);
					}
					break;
				}
			}
		}
	}

	private function onMergeButton()
	{
		var chartPaths:Array<String> = [];
		for (box in chartBoxes)
		{
			if (box.hasChart && box.chartPath != null)
			{
				chartPaths.push(box.chartPath);
			}
		}

		if (chartPaths.length < 2)
		{
			trace("Need at least 2 charts to merge");
			return;
		}

		mergeCharts(chartPaths);
	}

	private function mergeCharts(chartPaths:Array<String>)
	{
		trace('mergeCharts() called with ' + chartPaths.length + ' charts');

		if (chartPaths.length < 2) {
			trace('mergeCharts: Less than 2 charts, returning');
			return;
		}

		#if cpp
		cpp.vm.Gc.enable(false);
		#end

		SongJson.log = true;
		showMergingProgress(true, 'Loading base chart...\n');
		trace('Main.isConsoleAvailable: ${Main.isConsoleAvailable}');
		trace('SongJson.log: ${SongJson.log}');
		var baseData = loadChartFromFileWithProgress(chartPaths[0]);
		var baseObj = SongJson.parse(baseData);

		var baseChart:Dynamic;
		if (baseObj.song != null && Std.isOfType(baseObj.song, Dynamic))
			baseChart = baseObj.song;
		else
			baseChart = baseObj;
		SongJson.log = false;

		var tempPath = "temp_merged.json";
		saveChartStreaming(baseChart, tempPath, false);

		var totalCharts:Int = chartPaths.length;

		for (i in 1...totalCharts)
		{
			showMergingProgress(true, 'Merging chart ${i+1}/${totalCharts}...');

			SongJson.log = true;
			var baseJson = File.getContent(tempPath);
			var baseObj2 = SongJson.parse(baseJson);

			var baseChart2:Dynamic;
			if (baseObj2.song != null && Std.isOfType(baseObj2.song, Dynamic))
				baseChart2 = baseObj2.song;
			else
				baseChart2 = baseObj2;

			var nextData = loadChartFromFileWithProgress(chartPaths[i]);
			var nextObj = SongJson.parse(nextData);

			var nextChart:Dynamic;
			if (nextObj.song != null && Std.isOfType(nextObj.song, Dynamic))
				nextChart = nextObj.song;
			else
				nextChart = nextObj;

			SongJson.log = false;

			mergeInto(baseChart2, nextChart);

			saveChartStreaming(baseChart2, tempPath, false);

			baseChart2 = null;
			nextObj = null;
			nextChart = null;

			#if cpp
			cpp.vm.Gc.run(true);
			#end
		}

		var finalJson = File.getContent(tempPath);
		var finalObj = SongJson.parse(finalJson);

		var finalChart:Dynamic;
		if (finalObj.song != null && Std.isOfType(finalObj.song, Dynamic))
			finalChart = finalObj.song;
		else
			finalChart = finalObj;

		saveMergedChart(finalChart);

		#if cpp
		cpp.vm.Gc.enable(true);
		cpp.vm.Gc.run(true);
		#end

		if (FileSystem.exists(tempPath))
			FileSystem.deleteFile(tempPath);
	}

	private function mergeInto(baseSong:Dynamic, nextSong:Dynamic):Void
	{
		trace('mergeInto() called');

		// Ensure base has notes and events arrays
		if (baseSong.notes == null)
		{
			trace('baseSong.notes was null, creating empty array');
			baseSong.notes = [];
		}
		if (baseSong.events == null)
		{
			trace('baseSong.events was null, creating empty array');
			baseSong.events = [];
		}

		// Merge notes
		if (nextSong.notes != null)
		{
			var nextNotes:Array<Dynamic> = cast nextSong.notes;
			var baseNotes:Array<Dynamic> = cast baseSong.notes;

			for (sectionIndex in 0...nextNotes.length)
			{
				var nextSection = nextNotes[sectionIndex];
				if (sectionIndex < baseNotes.length)
				{
					var baseSection = baseNotes[sectionIndex];
					if (nextSection.sectionNotes != null)
					{
						var nextSectionNotes:Array<Dynamic> = cast nextSection.sectionNotes;
						var baseSectionNotes:Array<Dynamic> = cast baseSection.sectionNotes;
						baseSection.sectionNotes = baseSectionNotes.concat(nextSectionNotes);

						// Update progress after each section
						parsedNotes += nextSectionNotes.length;
						showMergeProgress();
					}
				}
				else
				{
					baseNotes.push(nextSection);
					if (nextSection.sectionNotes != null)
					{
						parsedNotes += nextSection.sectionNotes.length;
						showMergeProgress();
					}
				}
			}
		}

		// Merge events
		if (nextSong.events != null)
		{
			var nextEvents:Array<Dynamic> = cast nextSong.events;
			var baseEvents:Array<Dynamic> = cast baseSong.events;
			baseSong.events = baseEvents.concat(nextEvents);
			parsedEvents += nextEvents.length;
			showMergeProgress(true); // Force update
		}

		trace('\nmergeInto() COMPLETE');
	}

	private function showMergingProgress(show:Bool, message:String, force:Bool = false)
	{
		progressBg.visible = show;
		progressText.visible = show;
		progressText.text = message;

		if (Main.isConsoleAvailable)
		{
			var currentTime = haxe.Timer.stamp() * 1000;
			if ((currentTime - syncTime > progressUpdateTime * 1000) || force)
			{
				Sys.stdout().writeString('\x1b[0G' + message);
				Sys.stdout().flush();
				syncTime = currentTime;
			}
		}
		else if (force)
		{
			Sys.println(message);
		}
	}

	var parsedNotes:Int = 0;
	var parsedEvents:Int = 0;
	function showMergeProgress(force:Bool = false)
	{
		if (Main.isConsoleAvailable)
		{
			var currentTime = haxe.Timer.stamp() * 1000;
			if ((currentTime - syncTime > progressUpdateTime * 1000) || force)
			{
				var totalNotes = parsedNotes;
				var totalEvents = parsedEvents;
				Sys.stdout().writeString('\x1b[0GMerging $totalNotes notes and $totalEvents events');
				Sys.stdout().flush();
				syncTime = currentTime;
			}
		}
		else if (force) 
		{
			var totalNotes = parsedNotes;
			var totalEvents = parsedEvents;
			Sys.println('Merging $totalNotes notes and $totalEvents events');
		}
	}

	private function loadChartFromFileWithProgress(path:String):String
	{
		var rawData:String = null;

		#if MODS_ALLOWED
		if(FileSystem.exists(path)) rawData = File.getContent(path);
		#end

		if (rawData == null)
		{
			trace("Could not read file: " + path);
			return null;
		}

		return rawData;
	}

	function saveChartStreaming(chart:Dynamic, path:String, useWrapper:Bool = false):Void
	{
		var file = sys.io.File.write(path, false);
		var isFirst = true;

		// Helper to write a field
		function writeField(name:String, value:Dynamic):Void
		{
			if (!isFirst) file.writeString(",");
			isFirst = false;
			file.writeString('"' + name + '":');

			if (Std.isOfType(value, String))
				file.writeString('"' + value + '"');
			else if (Std.isOfType(value, Bool))
				file.writeString(value ? "true" : "false");
			else if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
				file.writeString(Std.string(value));
			else if (value == null)
				file.writeString("null");
			else
				file.writeString(Json.stringify(value));
		}

		// Write opening wrapper if needed
		if (useWrapper)
		{
			file.writeString('{"song":');
			isFirst = true;
		}

		file.writeString("{");

		// Core fields (always present)
		writeField("song", chart.song);
		writeField("notes", chart.notes);
		writeField("events", chart.events != null ? chart.events : []);
		writeField("bpm", chart.bpm);
		writeField("needsVoices", chart.needsVoices);
		writeField("speed", chart.speed);
		writeField("player1", chart.player1);
		writeField("player2", chart.player2);
		writeField("gfVersion", chart.gfVersion);
		writeField("stage", chart.stage);

		// V1 fields (optional)
		if (Reflect.hasField(chart, "offset"))
			writeField("offset", chart.offset);

		if (Reflect.hasField(chart, "format"))
			writeField("format", chart.format);

		// Extra optional fields
		if (Reflect.hasField(chart, "gameOverChar") && chart.gameOverChar != null)
			writeField("gameOverChar", chart.gameOverChar);
		if (Reflect.hasField(chart, "gameOverSound") && chart.gameOverSound != null)
			writeField("gameOverSound", chart.gameOverSound);
		if (Reflect.hasField(chart, "gameOverLoop") && chart.gameOverLoop != null)
			writeField("gameOverLoop", chart.gameOverLoop);
		if (Reflect.hasField(chart, "gameOverEnd") && chart.gameOverEnd != null)
			writeField("gameOverEnd", chart.gameOverEnd);
		if (Reflect.hasField(chart, "disableNoteRGB") && chart.disableNoteRGB != null)
			writeField("disableNoteRGB", chart.disableNoteRGB);
		if (Reflect.hasField(chart, "arrowSkin") && chart.arrowSkin != null)
			writeField("arrowSkin", chart.arrowSkin);
		if (Reflect.hasField(chart, "splashSkin") && chart.splashSkin != null)
			writeField("splashSkin", chart.splashSkin);

		file.writeString("}");

		// Close wrapper if needed
		if (useWrapper)
			file.writeString("}");

		file.close();
	}

	private function saveMergedChart(chart:Dynamic):Void
	{
		var defaultName:String = chart.song + "-merged.json";

		var tempPath = "temp_merged_final.json";
		saveChartStreaming(chart, tempPath, false);

		var jsonString:String = File.getContent(tempPath);

		fileDialog.saveWithPath(defaultName, jsonString,
			function(path:String)
			{
				File.copy(tempPath, path);
				FileSystem.deleteFile(tempPath);
				showMergingProgress(false, "Merge complete!", true);
				trace("Chart saved to: " + path);
			},
			function()
			{
				FileSystem.deleteFile(tempPath);
				showMergingProgress(false, "Save cancelled", true);
			},
			function(e:String)
			{
				FileSystem.deleteFile(tempPath);
				showMergingProgress(false, "Error: " + e, true);
			}
		);
	}

	private function onBackButton()
	{
		MusicBeatState.switchState(new MasterEditorMenu());
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

class ChartBox extends FlxGroup
{
	public var boxIndex:Int;
	public var isUnlocked:Bool = false;
	public var hasChart:Bool = false;
	public var chartPath:String = null;
	public var isWaitingForPath:Bool = false;

	private var bg:FlxSprite;
	private var openButton:PsychUIButton;
	private var pathText:FlxText;
	private var lockOverlay:FlxSprite;

	public function new(x:Float, y:Float, width:Float, height:Float, index:Int)
	{
		super();
		boxIndex = index;

		bg = new FlxSprite(x, y).makeGraphic(Std.int(width), Std.int(height), FlxColor.BLACK);
		add(bg);

		var border:FlxSprite = new FlxSprite(x, y).makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
		border.pixels.fillRect(new flash.geom.Rectangle(0, 0, width, 2), FlxColor.WHITE);
		border.pixels.fillRect(new flash.geom.Rectangle(0, height - 2, width, 2), FlxColor.WHITE);
		border.pixels.fillRect(new flash.geom.Rectangle(0, 0, 2, height), FlxColor.WHITE);
		border.pixels.fillRect(new flash.geom.Rectangle(width - 2, 0, 2, height), FlxColor.WHITE);
		add(border);

		openButton = new PsychUIButton(x + width / 2 - 40, y + height / 2 - 15, "Open Chart", onOpenButton);
		openButton.normalStyle.bgColor = FlxColor.BLUE;
		openButton.normalStyle.textColor = FlxColor.WHITE;
		add(openButton);

		pathText = new FlxText(x + 10, y + height - 30, width - 20, "No chart selected", 12);
		add(pathText);

		lockOverlay = new FlxSprite(x, y).makeGraphic(Std.int(width), Std.int(height), FlxColor.BLACK);
		lockOverlay.alpha = 0.7;
		add(lockOverlay);

		var lockText:FlxText = new FlxText(x + width / 2 - 20, y + height / 2 - 10, 40, "🔒", 20);
		lockText.alignment = CENTER;
		add(lockText);

		setUnlocked(false);
	}

	public function setUnlocked(unlocked:Bool)
	{
		isUnlocked = unlocked;
		lockOverlay.visible = !unlocked;
		openButton.active = unlocked;
	}

	public function setChartPath(path:String)
	{
		chartPath = path;
		hasChart = true;

		var fileName:String = path.split("\\").pop().split("/").pop();
		pathText.text = fileName;
		pathText.color = FlxColor.WHITE;
	}

	private function onOpenButton()
	{
		if (!isUnlocked) return;

		isWaitingForPath = true;

		var fileDialog = new FileDialogHandler();
		fileDialog.open(null, null, null,
			function()
			{
				if (fileDialog.path != null && fileDialog.path.length > 0)
				{
					setChartPath(fileDialog.path);
				}
			});
	}
}