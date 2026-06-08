package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

import backend.Song;
import backend.SongJson;
import backend.ui.PsychUIBox;
import backend.ui.PsychUIButton;
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
		trace('[TRACE] mergeCharts() called with ' + chartPaths.length + ' charts');

		if (chartPaths.length < 2)
		{
			trace('[TRACE] mergeCharts: Less than 2 charts, returning');
			return;
		}

		var currentMergedPath:String = chartPaths[0];
		trace('[TRACE] mergeCharts: Starting with first chart: ' + currentMergedPath);
		var totalCharts:Int = chartPaths.length;

		for (i in 1...totalCharts)
		{
			trace('[TRACE] mergeCharts: Processing chart ' + (i+1) + '/' + totalCharts);
			showMergingProgress(true, 'Merging chart ${i+1}/${totalCharts}...');

			trace('[TRACE] mergeCharts: Loading base chart: ' + currentMergedPath);
			var baseData = loadChartFromFileWithProgress(currentMergedPath);
			if (baseData == null)
			{
				trace('[TRACE] mergeCharts: ERROR - baseData is null');
				showMergingProgress(false, 'Failed to load base chart');
				return;
			}
			trace('[TRACE] mergeCharts: Base chart loaded, size: ' + baseData.length + ' bytes');

			trace('[TRACE] mergeCharts: Loading next chart: ' + chartPaths[i]);
			var nextData = loadChartFromFileWithProgress(chartPaths[i]);
			if (nextData == null)
			{
				trace('[TRACE] mergeCharts: ERROR - nextData is null');
				showMergingProgress(false, 'Failed to load chart ${i+1}');
				return;
			}
			trace('[TRACE] mergeCharts: Next chart loaded, size: ' + nextData.length + ' bytes');

			trace('[TRACE] mergeCharts: Parsing base chart...');
			SongJson.log = true;
			var baseObj:Dynamic = SongJson.parse(baseData);
			trace('[TRACE] mergeCharts: Base chart parsed');

			trace('[TRACE] mergeCharts: Parsing next chart...');
			var nextObj:Dynamic = SongJson.parse(nextData);
			SongJson.log = false;
			trace('[TRACE] mergeCharts: Next chart parsed');

			var baseChart = baseObj.song != null ? baseObj.song : baseObj;
			var nextChart = nextObj.song != null ? nextObj.song : nextObj;

			parsedNotes = 0;
			parsedEvents = 0;
			syncTime = haxe.Timer.stamp() * 1000;

			trace('[TRACE] mergeCharts: Merging into base chart...');
			mergeInto(baseChart, nextChart);
			trace('[TRACE] mergeCharts: Merge complete');

			var tempPath = "temp_merged_" + i + ".json";
			trace('[TRACE] mergeCharts: Saving intermediate result to ' + tempPath);

			var mergedJson:String;
			if (baseObj.song != null)
			{
				baseObj.song = baseChart;
				mergedJson = Json.stringify(baseObj, null, "\t");
			}
			else
			{
				mergedJson = Json.stringify(baseChart, null, "\t");
			}

			File.saveContent(tempPath, mergedJson);
			trace('[TRACE] mergeCharts: Saved ' + mergedJson.length + ' bytes');

			// Free memory
			baseData = null;
			nextData = null;
			baseObj = null;
			nextObj = null;
			baseChart = null;
			nextChart = null;
			#if cpp
			trace('[TRACE] mergeCharts: Running GC');
			cpp.vm.Gc.run(true);
			#end

			currentMergedPath = tempPath;
			trace('[TRACE] mergeCharts: Current merged path updated to ' + currentMergedPath);
		}

		trace('[TRACE] mergeCharts: Loading final merged data from ' + currentMergedPath);
		var finalData = File.getContent(currentMergedPath);
		trace('[TRACE] mergeCharts: Final data size: ' + finalData.length + ' bytes');

		trace('[TRACE] mergeCharts: Calling saveMergedChart');
		saveMergedChart(finalData);

		// Clean up temp files
		trace('[TRACE] mergeCharts: Cleaning up temp files');
		for (i in 1...totalCharts)
		{
			var tempPath = "temp_merged_" + i + ".json";
			if (FileSystem.exists(tempPath))
			{
				FileSystem.deleteFile(tempPath);
				trace('[TRACE] mergeCharts: Deleted ' + tempPath);
			}
		}

		trace('[TRACE] mergeCharts: COMPLETE');
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
		trace('[TRACE] showMergingProgress called: show=' + show + ', message=' + message + ', force=' + force);
		
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
		trace('[TRACE] showMergeProgress called: force=' + force + ', parsedNotes=' + parsedNotes + ', parsedEvents=' + parsedEvents);
		
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