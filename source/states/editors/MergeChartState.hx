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
import haxe.io.Path;
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
			var box:ChartBox = new ChartBox(startX + i * (boxWidth + spacing), startY * 3, boxWidth, boxHeight, i);
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
		showMergingProgress(true, "Loading charts...");

		var allCharts:Array<String> = [];

		for (i in 0...chartPaths.length)
		{
			var path:String = chartPaths[i];

			// Get file size in MB
			var fileSizeMB:Float = 0;
			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			{
				fileSizeMB = FileSystem.stat(path).size / (1024 * 1024);
			}
			#end

			showMergingProgress(true, 'Loading chart ${i + 1}/${chartPaths.length} (${fileSizeMB} MB)');

			try
			{
				var rawData:String = loadChartFromFileWithProgress(path);
				if (rawData != null)
				{
					allCharts.push(rawData);
					trace("Loaded chart " + (i + 1) + " successfully");
				}
				else
				{
					trace("Failed to load chart " + (i + 1));
				}
			}
			catch (e:Dynamic)
			{
				trace("Error loading chart " + (i + 1) + ": " + e);
			}
		}

		if (allCharts.length < 2)
		{
			showMergingProgress(false, "Need at least 2 valid charts");
			return;
		}

		// Calculate total notes and events estimate before merging
		var totalNotesEstimate:Int = 0;
		var totalEventsEstimate:Int = 0;
		for (chartJson in allCharts)
		{
			try
			{
				// Enable SongJson progress logging during parsing
				SongJson.log = true;
				var chart:Dynamic = SongJson.parse(chartJson);
				SongJson.log = false;
				if (chart.notes != null)
				{
					var notesArray:Array<Dynamic> = cast chart.notes;
					for (section in notesArray)
					{
						if (section.sectionNotes != null)
						{
							var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
							totalNotesEstimate += sectionNotes.length;
						}
					}
				}
				if (chart.events != null)
				{
					var eventsArray:Array<Dynamic> = cast chart.events;
					totalEventsEstimate += eventsArray.length;
				}
			}
			catch (e:Dynamic) 
			{
				SongJson.log = false;
			}
		}

		showMergingProgress(true, 'Merging ${totalNotesEstimate} notes and ${totalEventsEstimate} events');
		var mergedData:String = mergeSongData(allCharts);

		if (mergedData != null)
		{
			showMergingProgress(true, "Saving merged chart...");
			saveMergedChart(mergedData);
		}
		else
		{
			showMergingProgress(false, "Merge failed");
		}
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

				// Show both notes and events being inserted, like reloadNotes()
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

	private function loadChartFromFile(path:String):String
	{
		var rawData:String = null;

		#if MODS_ALLOWED
		if(FileSystem.exists(path))
			rawData = File.getContent(path);
		#end

		if (rawData == null)
		{
			trace("Could not read file: " + path);
			return null;
		}

		return rawData;
	}

	private function loadChartFromFileWithProgress(path:String):String
	{
		var rawData:String = null;

		#if MODS_ALLOWED
		if(FileSystem.exists(path))
		{
			// Enable SongJson progress logging during loading
			SongJson.log = true;
			showMergingProgress(true, 'Loading chart: ${Path.withoutDirectory(path)}');
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

	private function mergeSongData(charts:Array<String>):String
	{
		if (charts.length == 0) return null;

		// Parse all charts to Dynamic objects
		var chartObjects:Array<Dynamic> = [];
		for (chartJson in charts)
		{
			try
			{
				// Enable SongJson progress logging during parsing
				SongJson.log = true;
				showMergingProgress(true, 'Parsing chart JSON...');
				var chartObj:Dynamic = SongJson.parse(chartJson);
				SongJson.log = false;
				chartObjects.push(chartObj);
			}
			catch (e:Dynamic)
			{
				SongJson.log = false;
				trace("Error parsing JSON: " + e);
				return null;
			}
		}

		if (chartObjects.length < 2) return null;

		// Reset progress counters and timing
		parsedNotes = 0;
		parsedEvents = 0;
		syncTime = haxe.Timer.stamp() * 1000;

		// JS Engine approach: Force major GC before massive operation
		#if sys
		cpp.vm.Gc.run(true);
		#end

		// Use first chart as base (deep copy)
		var merged:Dynamic = Json.parse(charts[0]);

		// Ensure notes and events arrays exist
		if (merged.notes == null) merged.notes = [];
		if (merged.events == null) merged.events = [];

		// Count notes and events from first chart
		if (merged.notes != null)
		{
			var mergedNotes:Array<Dynamic> = cast merged.notes;
			for (section in mergedNotes)
			{
				if (section.sectionNotes != null)
				{
					var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
					parsedNotes += sectionNotes.length;
				}
			}
		}
		if (merged.events != null)
		{
			var mergedEvents:Array<Dynamic> = cast merged.events;
			parsedEvents = mergedEvents.length;
		}

		// Calculate total notes to determine if GC should be disabled
		var totalNotesEstimate:Int = 0;
		for (chart in chartObjects)
		{
			if (chart.notes != null)
			{
				var notesArray:Array<Dynamic> = cast chart.notes;
				for (section in notesArray)
				{
					if (section.sectionNotes != null)
					{
						var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
						totalNotesEstimate += sectionNotes.length;
					}
				}
			}
		}

		// Conditional GC disabling for massive operations (JS Engine method)
		#if sys
		if (totalNotesEstimate > 1000000) {
			cpp.vm.Gc.enable(false);
		}
		#end

		// Merge additional charts (starting from index 1) - section-by-section merge
		for (i in 1...chartObjects.length)
		{
			var chart:Dynamic = chartObjects[i];

			// Merge notes section-by-section
			if (chart.notes != null)
			{
				var notesArray:Array<Dynamic> = cast chart.notes;
				var mergedNotes:Array<Dynamic> = cast merged.notes;

				for (sectionIndex in 0...notesArray.length)
				{
					var chartSection:Dynamic = notesArray[sectionIndex];

					// If merged chart has this section, append notes to it
					if (sectionIndex < mergedNotes.length)
					{
						var mergedSection:Dynamic = mergedNotes[sectionIndex];
						if (chartSection.sectionNotes != null)
						{
							var chartSectionNotes:Array<Dynamic> = cast chartSection.sectionNotes;
							var mergedSectionNotes:Array<Dynamic> = cast mergedSection.sectionNotes;

							// Use concat for faster array joining (dupeNotes approach)
							mergedSection.sectionNotes = mergedSectionNotes.concat(chartSectionNotes);
							parsedNotes += chartSectionNotes.length;
						}
					}
					else
					{
						// If merged chart doesn't have this section, add it
						mergedNotes.push(chartSection);
						if (chartSection.sectionNotes != null)
						{
							var sectionNotes:Array<Dynamic> = cast chartSection.sectionNotes;
							parsedNotes += sectionNotes.length;
						}
					}

					// Show progress periodically
					showMergeProgress();
				}
			}

			// Merge events - append all events using concat
			if (chart.events != null)
			{
				var eventsArray:Array<Dynamic> = cast chart.events;
				var mergedEvents:Array<Dynamic> = cast merged.events;

				// Use concat for faster array joining
				merged.events = mergedEvents.concat(eventsArray);
				parsedEvents += eventsArray.length;
				showMergeProgress();
			}
		}

		// Count total notes and events
		var totalNotes:Int = 0;
		var totalEvents:Int = 0;

		if (merged.notes != null)
		{
			var mergedNotes:Array<Dynamic> = cast merged.notes;
			for (section in mergedNotes)
			{
				if (section.sectionNotes != null)
				{
					var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
					totalNotes += sectionNotes.length;
				}
			}
		}

		if (merged.events != null)
		{
			var mergedEvents:Array<Dynamic> = cast merged.events;
			totalEvents = mergedEvents.length;
		}

		trace("Merged " + totalNotes + " notes and " + totalEvents + " events");

		// JS Engine approach: Always re-enable GC and force collection
		#if sys
		cpp.vm.Gc.enable(true);
		cpp.vm.Gc.run(true);
		#end

		// Return merged as JSON string
		return Json.stringify(merged, null, "\t");
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