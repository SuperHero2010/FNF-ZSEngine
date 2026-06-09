package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

import backend.Song;
import backend.SongJson;
import backend.ui.*;
import states.editors.content.FileDialogHandler;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

import hxbitmini.Serializable;
import hxbitmini.Serializer;
import hxbitmini.Unserializer;

@:hxbit.Serializable
class SerializableChart
{
    public var song:String;
    public var notes:Array<SerializableSection>;
    public var events:Array<Array<Dynamic>>;
    public var bpm:Float;
    public var needsVoices:Bool;
    public var speed:Float;
    public var offset:Float;
    public var player1:String;
    public var player2:String;
    public var gfVersion:String;
    public var stage:String;
    public var format:String;

    public function new() {}

    public static function fromDynamic(data:Dynamic):SerializableChart
    {
        var chart = new SerializableChart();
        chart.song = data.song;
        chart.bpm = data.bpm;
        chart.needsVoices = data.needsVoices;
        chart.speed = data.speed;
        chart.offset = data.offset;
        chart.player1 = data.player1;
        chart.player2 = data.player2;
        chart.gfVersion = data.gfVersion;
        chart.stage = data.stage;
        chart.format = data.format;

        // Convert notes
        chart.notes = [];
        if (data.notes != null)
        {
            for (section in data.notes)
            {
                chart.notes.push(SerializableSection.fromDynamic(section));
            }
        }

        // Convert events
        chart.events = data.events != null ? data.events : [];

        return chart;
    }

    public function toDynamic():Dynamic
    {
        var data:Dynamic = {};
        data.song = song;
        data.bpm = bpm;
        data.needsVoices = needsVoices;
        data.speed = speed;
        data.offset = offset;
        data.player1 = player1;
        data.player2 = player2;
        data.gfVersion = gfVersion;
        data.stage = stage;
        data.format = format;

        // Convert notes
        data.notes = [];
        for (section in notes)
        {
            data.notes.push(section.toDynamic());
        }

        data.events = events;

        return data;
    }
}

@:hxbit.Serializable
class SerializableSection
{
    public var sectionNotes:Array<Array<Dynamic>>;
    public var sectionBeats:Float;
    public var mustHitSection:Bool;
    public var changeBPM:Bool;
    public var bpm:Float;
    public var altAnim:Bool;
    public var gfSection:Bool;

    public function new() {}

    public static function fromDynamic(data:Dynamic):SerializableSection
    {
        var section = new SerializableSection();
        section.sectionNotes = data.sectionNotes != null ? data.sectionNotes : [];
        section.sectionBeats = data.sectionBeats;
        section.mustHitSection = data.mustHitSection;
        section.changeBPM = data.changeBPM;
        section.bpm = data.bpm;
        section.altAnim = data.altAnim;
        section.gfSection = data.gfSection;
        return section;
    }

    public function toDynamic():Dynamic
    {
        return {
            sectionNotes: sectionNotes,
            sectionBeats: sectionBeats,
            mustHitSection: mustHitSection,
            changeBPM: changeBPM,
            bpm: bpm,
            altAnim: altAnim,
            gfSection: gfSection
        };
    }
}

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
	mergeChartSave.bind("MergeChartState", CoolUtil.getSavePath());

	override function create()
	{
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

		var indentationCheckbox:PsychUICheckBox = new PsychUICheckBox(20, FlxG.height - 10, "Use Indentation", 140, function() {
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

	function saveChartBinary(chart:Dynamic, path:String):Void
	{
		var serializable = SerializableChart.fromDynamic(chart);
		var serializer = new Serializer();
		serializer.serialize(serializable);
		var bytes = serializer.getBytes();

		var output = File.write(path, true);
		output.writeBytes(bytes, 0, bytes.length);
		output.close();
	}

	function loadChartBinary(path:String):Dynamic
	{
		if (!FileSystem.exists(path)) return null;

		var bytes = File.getBytes(path);
		var unserializer = new Unserializer();
		unserializer.setBytes(bytes);
		var serializable:SerializableChart = unserializer.unserialize();

		return serializable != null ? serializable.toDynamic() : null;
	}

	private function mergeCharts(chartPaths:Array<String>)
	{
		if (chartPaths.length < 2) return;

		var tempDir:String;
		#if windows
		tempDir = Sys.getEnv("TEMP");
		#else
		tempDir = "/tmp";
		#end

		var baseData = loadChartFromFileWithProgress(chartPaths[0]);
		var baseObj = SongJson.parse(baseData);
		var baseChart = baseObj.song != null ? baseObj.song : baseObj;

		var currentMergedPath = tempDir + "/temp_merged_base.bin";
		saveChartBinary(baseChart, currentMergedPath);

		var totalCharts:Int = chartPaths.length;

		for (i in 1...totalCharts)
		{
			showMergingProgress(true, 'Merging chart ${i+1}/${totalCharts}...');

			var baseChart = loadChartBinary(currentMergedPath);
			if (baseChart == null) return;

			var nextData = loadChartFromFileWithProgress(chartPaths[i]);
			var nextObj = SongJson.parse(nextData);
			var nextChart = nextObj.song != null ? nextObj.song : nextObj;

			var baseNotesCount = 0;
			var baseEventsCount = 0;
			for (section in baseChart.notes)
				if (section.sectionNotes != null)
					baseNotesCount += section.sectionNotes.length;
			if (baseChart.events != null) baseEventsCount = baseChart.events.length;

			parsedNotes = 0;
			parsedEvents = 0;
			syncTime = haxe.Timer.stamp() * 1000;

			mergeInto(baseChart, nextChart);

			saveChartBinary(baseChart, currentMergedPath);

			baseChart = null;
			nextObj = null;
			nextChart = null;

			#if cpp
			cpp.vm.Gc.run(true);
			#end
		}

		var finalChart = loadChartBinary(currentMergedPath);
		var finalJson:String;
		if (indentation) {
			finalJson = Json.stringify(finalChart, null, "\t");
		}
		else {
			finalJson = Json.stringify(finalChart);
		}
		saveMergedChart(finalJson);

		if (FileSystem.exists(currentMergedPath))
			FileSystem.deleteFile(currentMergedPath);
	}

	private function mergeInto(baseSong:Dynamic, nextSong:Dynamic):Void
	{
		trace('[TRACE] mergeInto() called');

		// Ensure base has notes and events arrays
		if (baseSong.notes == null)
		{
			trace('[TRACE] baseSong.notes was null, creating empty array');
			baseSong.notes = [];
		}
		if (baseSong.events == null)
		{
			trace('[TRACE] baseSong.events was null, creating empty array');
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

		trace('[TRACE] mergeInto() COMPLETE');
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
		if(FileSystem.exists(path))
		{
			// Enable SongJson progress logging during loading
			SongJson.log = true;
			rawData = File.getContent(path);
			SongJson.log = false;
		}
		#end

		if (rawData == null)
		{
			trace("Could not read file: " + path);
			return null;
		}

		return rawData;
	}

	private function saveMergedChart(mergedData:String)
	{
		// Extract song name from the merged data
		var songName:String = "merged";
		try
		{
			var mergedObj:Dynamic = Json.parse(mergedData);
			if (mergedObj.song != null) songName = mergedObj.song;
		}
		catch (e:Dynamic) {}

		var defaultName:String = songName + "-merged.json";

		fileDialog.save(defaultName, mergedData,
			function()
			{
				showMergingProgress(false, "Merge complete!");
			}, null, function()
			{
				showMergingProgress(false, "Error saving chart");
			});
	}

	private function onBackButton()
	{
		FlxG.switchState(new MasterEditorMenu());
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

		openButton = new PsychUIButton(x + width / 2 - 50, y + height / 2 - 15, "Open Chart", onOpenButton);
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