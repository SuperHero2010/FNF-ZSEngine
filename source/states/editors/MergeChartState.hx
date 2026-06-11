package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.FlxSubState;

import backend.Song;
import backend.SongJson;
import backend.ui.*;
import states.editors.content.*;

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
	var mergeChartSave:FlxSave = new FlxSave();
	var indentation:Bool = false;
	var indentationCheckbox:PsychUICheckBox;
	var temp:Bool = true;
	var tempCheckbox:PsychUICheckBox;
	var rewrite:Bool = false;
	var rewriteCheckbox:PsychUICheckBox;

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

		tempCheckbox = new PsychUICheckBox(20, backButton.y - 60, "Use Temp file (fast)", 200, function() {
			mergeChartSave.data.temp = tempCheckbox.checked;
			mergeChartSave.flush();
			temp = tempCheckbox.checked;
		});
		tempCheckbox.checked = (mergeChartSave.data.temp == true);
		temp = tempCheckbox.checked;
		add(tempCheckbox);

		rewriteCheckbox = new PsychUICheckBox(20, backButton.y - 90, "Rewrite mode", 200, function() {
			mergeChartSave.data.rewrite = rewriteCheckbox.checked;
			mergeChartSave.flush();
			rewrite = rewriteCheckbox.checked;
			var funcYes:Void->Void = function() {
				rewrite = true;
				rewriteCheckbox.checked = true;
			};
			var funcNo:Void->Void = function() {
				rewrite = false;
				rewriteCheckbox.checked = false;
			};
			openSubState(new Prompt('Enable rewrite mode?\nThis will rewrite the base chart instead of appending.', funcYes, funcNo));
		});
		rewriteCheckbox.checked = (mergeChartSave.data.rewrite == true);
		rewrite = rewriteCheckbox.checked;
		add(rewriteCheckbox);

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
		if (mergeChartSave.data.temp == null) mergeChartSave.data.temp = true;
		temp = mergeChartSave.data.temp;
		if (mergeChartSave.data.rewrite == null) mergeChartSave.data.rewrite = false;
		rewrite = mergeChartSave.data.rewrite;
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
		var baseData = loadChartFromFileWithProgress(chartPaths[0]);
		var baseObj = SongJson.parse(baseData);

		var hasWrapper = (baseObj.song != null && Std.isOfType(baseObj.song, Dynamic));
		var baseChart:Dynamic;
		if (hasWrapper)
			baseChart = baseObj.song;
		else
			baseChart = baseObj;

		SongJson.log = false;

		var tempPath:String = "";
		if (temp) {
			tempPath = "temp_merged.json";
			saveChartStreaming(baseChart, tempPath, hasWrapper, false, "temp");
		}

		var totalCharts:Int = chartPaths.length;

		for (i in 1...totalCharts)
		{
			showMergingProgress(true, 'Merging chart ${i + 1}/${totalCharts}...\n');

			var baseChart2:Dynamic = null;
			if (temp) {
				SongJson.log = true;
				var baseJson = File.getContent(tempPath);
				var baseObj2 = SongJson.parse(baseJson);

				if (baseObj2.song != null && Std.isOfType(baseObj2.song, Dynamic))
					baseChart2 = baseObj2.song;
				else
					baseChart2 = baseObj2;
				SongJson.log = false;
			}

			SongJson.log = true;
			var nextData = loadChartFromFileWithProgress(chartPaths[i]);
			var nextObj = SongJson.parse(nextData);

			var nextChart:Dynamic;
			if (nextObj.song != null && Std.isOfType(nextObj.song, Dynamic))
				nextChart = nextObj.song;
			else
				nextChart = nextObj;
			SongJson.log = false;

			if (temp) {
				if (rewrite) {
					mergeInto(baseChart2, nextChart);
					showMergingProgress(true, "\n");
					saveChartStreaming(baseChart2, tempPath, hasWrapper, false, 'chart ${i + 1}');
					baseChart2 = null;
				}
				else {
					showMergingProgress(true, "\n");
					appendChartToTempFile(tempPath, nextChart, hasWrapper, i + 1, indentation);
				}
			}
			else {
				mergeInto(baseChart, nextChart);
				showMergingProgress(true, "\n");
			}

			nextObj = null;
			nextChart = null;

			#if cpp
			cpp.vm.Gc.run(true);
			#end
		}

		var finalJson:Dynamic;
		if (temp) finalJson = File.getContent(tempPath);
		else finalJson = baseChart;
		var finalObj = SongJson.parse(finalJson);

		var finalChart:Dynamic;
		if (finalObj.song != null && Std.isOfType(finalObj.song, Dynamic))
			finalChart = finalObj.song;
		else
			finalChart = finalObj;

		saveMergedChart(finalChart, hasWrapper, indentation);

		#if cpp
		cpp.vm.Gc.enable(true);
		cpp.vm.Gc.run(true);
		#end

		if (FileSystem.exists(tempPath))
			FileSystem.deleteFile(tempPath);
	}

	private function appendChartToTempFile(tempPath:String, nextChart:Dynamic, hasWrapper:Bool, chartIndex:Int, indentation:Bool = false):Void
	{
		trace('appendChartToTempFile() called for chart $chartIndex');

		var newNotes = extractNewNotesFromChart(nextChart);
		var newEvents = extractNewEventsFromChart(nextChart);

		if (newNotes.length == 0 && newEvents.length == 0) {
			trace('No new notes or events to append');
			return;
		}

		var fileIndentation = detectIndentation(tempPath);
		var useIndentation = fileIndentation || indentation;

		trace('Finding append positions...');

		var notesEndPos = findArrayEndPositionInFile(tempPath, "notes");
		var eventsEndPos = findArrayEndPositionInFile(tempPath, "events");

		if (notesEndPos == -1 || eventsEndPos == -1) {
			var funcYes = function() {
				trace('Could not find array end positions, falling back to full rewrite');
				var tempContent = File.getContent(tempPath);
				var tempObj = SongJson.parse(tempContent);
				var tempChart:Dynamic;
				if (tempObj.song != null && Std.isOfType(tempObj.song, Dynamic)) {
					tempChart = tempObj.song;
				} else {
					tempChart = tempObj;
				}
				mergeInto(tempChart, nextChart);
				saveChartStreaming(tempChart, tempPath, hasWrapper, false, 'chart $chartIndex');
				return;
			};
			var funcNo = function() {
				return;
			};
			openSubState(new Prompt("Error! Could not find array end positions, falling back to full rewrite. Continue?", funcYes, funcNo));
		}

		trace('Copying file content...');

		var inputFile = sys.io.File.read(tempPath, false);
		var outputFile = sys.io.File.write(tempPath + ".new", false);

		copyChunk(inputFile, outputFile, notesEndPos);

		trace('Writing ${newNotes.length} new notes...');

		if (newNotes.length > 0) {
			if (useIndentation) outputFile.writeString(",\n\t\t");
			else outputFile.writeString(",");
			for (i in 0...newNotes.length) {
				if (useIndentation) outputFile.writeString("\t\t\t");
				outputFile.writeString(Json.stringify(newNotes[i]));
				if (i < newNotes.length - 1) {
					if (useIndentation) outputFile.writeString(",\n\t\t\t");
					else outputFile.writeString(",");
				}

				if (i % 10000 == 0) {
					showMergingProgress(true, 'Writing notes: $i/${newNotes.length}');
				}
			}
			if (useIndentation) outputFile.writeString("\n\t");
		}

		if (useIndentation) outputFile.writeString("\n\t");
		outputFile.writeString("]");

		trace('Copying content between arrays...');

		inputFile.seek(notesEndPos + 1, sys.io.FileSeek.SeekBegin);
		copyChunk(inputFile, outputFile, eventsEndPos - notesEndPos - 1);

		trace('Writing ${newEvents.length} new events...');

		if (newEvents.length > 0) {
			if (useIndentation) outputFile.writeString(",\n\t\t");
			else outputFile.writeString(",");
			for (i in 0...newEvents.length) {
				if (useIndentation) outputFile.writeString("\t\t\t");
				outputFile.writeString(Json.stringify(newEvents[i]));
				if (i < newEvents.length - 1) {
					if (useIndentation) outputFile.writeString(",\n\t\t\t");
					else outputFile.writeString(",");
				}

				if (i % 1000 == 0) {
					showMergingProgress(true, 'Writing events: $i/${newEvents.length}');
				}
			}
			if (useIndentation) outputFile.writeString("\n\t");
		}

		if (useIndentation) outputFile.writeString("\n\t");
		outputFile.writeString("]");

		trace('Copying remaining content...');

		inputFile.seek(eventsEndPos + 1, sys.io.FileSeek.SeekBegin);
		var remainingBytes = inputFile.readAll();
		outputFile.write(remainingBytes);

		inputFile.close();
		outputFile.close();

		trace('Replacing original file...');

		FileSystem.deleteFile(tempPath);
		FileSystem.rename(tempPath + ".new", tempPath);

		trace('Appended ${newNotes.length} notes and ${newEvents.length} events');
	}

	private function copyChunk(inputFile:sys.io.FileInput, outputFile:sys.io.FileOutput, bytesToCopy:Int):Void
	{
		var bufferSize = 65536;
		var bytesCopied = 0;

		while (bytesCopied < bytesToCopy) {
			var bytesToRead = bufferSize;
			if (bytesCopied + bufferSize > bytesToCopy) {
				bytesToRead = bytesToCopy - bytesCopied;
			}

			var chunk = inputFile.read(bytesToRead);
			outputFile.write(chunk);
			bytesCopied += bytesToRead;
		}
	}

	private function detectIndentation(filePath:String):Bool
	{
		var file = sys.io.File.read(filePath, false);
		var chunk = file.read(4096);
		file.close();

		var chunkStr = chunk.toString();
		return chunkStr.indexOf('\n\t') != -1 || chunkStr.indexOf('\n  ') != -1;
	}

	private function findArrayEndPositionInFile(filePath:String, arrayName:String):Int
	{
		var file = sys.io.File.read(filePath, false);
		var bufferSize = 65536;
		var buffer = "";
		var totalRead = 0;
		var pattern = '"$arrayName"\\s*:\\s*\\[';
		var patternFound = false;
		var bracketCount = 0;
		var inString = false;
		var escapeNext = false;

		try {
			while (true) {
				var chunk = file.read(bufferSize);
				if (chunk.length == 0) break;

				buffer += chunk;
				totalRead += chunk.length;

				if (!patternFound) {
					var patternIndex = buffer.indexOf(pattern);
					if (patternIndex != -1) {
						patternFound = true;
						buffer = buffer.substr(patternIndex);
						bracketCount = 1;
					}
				}

				if (patternFound) {
					for (i in 0...buffer.length) {
						var char = buffer.charAt(i);

						if (escapeNext) {
							escapeNext = false;
							continue;
						}

						if (char == '\\') {
							escapeNext = true;
							continue;
						}

						if (char == '"') {
							inString = !inString;
							continue;
						}

						if (!inString) {
							if (char == '[') bracketCount++;
							else if (char == ']') {
								bracketCount--;
								if (bracketCount == 0) {
									file.close();
									return totalRead - buffer.length + i;
								}
							}
						}
					}

					// Keep last part of buffer for pattern matching across chunks
					if (buffer.length > 1000) {
						buffer = buffer.substr(buffer.length - 1000);
					}
				}
			}
		} catch (e:Dynamic) {
			file.close();
		}

		file.close();
		return -1;
	}

	private function findArrayEndPosition(content:String, arrayName:String):Int
	{
		var pattern = '"$arrayName"\\s*:\\s*\\[';
		var startIndex = content.indexOf(pattern);
		if (startIndex == -1) return -1;

		var bracketCount = 0;
		var inString = false;
		var escapeNext = false;

		for (i in startIndex...content.length) {
			var char = content.charAt(i);

			if (escapeNext) {
				escapeNext = false;
				continue;
			}

			if (char == '\\') {
				escapeNext = true;
				continue;
			}

			if (char == '"') {
				inString = !inString;
				continue;
			}

			if (!inString) {
				if (char == '[') bracketCount++;
				else if (char == ']') {
					bracketCount--;
					if (bracketCount == 0) return i;
				}
			}
		}

		return -1;
	}

	private function extractNewNotesFromChart(chart:Dynamic):Array<Dynamic>
	{
		var newNotes:Array<Dynamic> = [];

		if (chart.notes != null) {
			var notes:Array<Dynamic> = cast chart.notes;
			for (section in notes) {
				if (section.sectionNotes != null) {
					var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
					for (note in sectionNotes) {
						newNotes.push(note);
					}
				}
			}
		}

		return newNotes;
	}

	private function extractNewEventsFromChart(chart:Dynamic):Array<Dynamic>
	{
		var newEvents:Array<Dynamic> = [];

		if (chart.events != null) {
			var events:Array<Dynamic> = cast chart.events;
			for (event in events) {
				newEvents.push(event);
			}
		}

		return newEvents;
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
						if (sectionIndex == nextNotes.length) showMergeProgress(false, true);
						else showMergeProgress();
					}
				}
				else
				{
					baseNotes.push(nextSection);
					if (nextSection.sectionNotes != null)
					{
						parsedNotes += nextSection.sectionNotes.length;
						if (sectionIndex == nextNotes.length) showMergeProgress(false, true);
						else showMergeProgress();
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
			showMergeProgress(false, true);
		}

		showMergingProgress(true, '\nmergeInto() COMPLETE');
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
	function showMergeProgress(force:Bool = false, ?newLine:Bool = false)
	{
		if (Main.isConsoleAvailable)
		{
			var currentTime = haxe.Timer.stamp() * 1000;
			if ((currentTime - syncTime > progressUpdateTime * 1000) || force)
			{
				var totalNotes = parsedNotes;
				var totalEvents = parsedEvents;
				if (newLine) Sys.stdout().writeString('\x1b[0GMerging $totalNotes notes and $totalEvents events\n');
				else Sys.stdout().writeString('\x1b[0GMerging $totalNotes notes and $totalEvents events');
				Sys.stdout().flush();
				syncTime = currentTime;
			}
		}
		else if (force) 
		{
			var totalNotes = parsedNotes;
			var totalEvents = parsedEvents;
			if (newLine) Sys.println('Merging $totalNotes notes and $totalEvents events\n');
			else Sys.println('Merging $totalNotes notes and $totalEvents events');
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

	function saveChartStreaming(chart:Dynamic, path:String, hasWrapper:Bool = true, useIndentation:Bool = false, ?message:String):Void
	{
		var file = sys.io.File.write(path, false);

		var totalNotes:Int = 0;
		if (chart.notes != null)
		{
			var notesArray:Array<Dynamic> = cast chart.notes;
			for (section in notesArray)
			{
				if (section.sectionNotes != null)
					totalNotes += section.sectionNotes.length;
			}
		}
		var totalEvents:Int = chart.events != null ? chart.events.length : 0;
		var totalItems:Int = totalNotes + totalEvents;
		var processedItems:Int = 0;

		function updateProgress():Void
		{
			if (totalItems > 0)
			{
				var percent = Std.int((processedItems / totalItems) * 100);
				showMergingProgress(true, 'Writing ' + message + ' ... $percent%', false);
			}
		}

		var indent = useIndentation ? "\t" : "";
		var newline = useIndentation ? "\n" : "";

		function writeIndent(level:Int):Void
		{
			if (useIndentation)
			{
				for (i in 0...level)
					file.writeString("\t");
			}
		}

		if (hasWrapper)
		{
			file.writeString('{"song":');
			if (useIndentation) file.writeString(newline);
		}

		writeIndent(useIndentation ? 1 : 0);
		file.writeString("{");
		if (useIndentation) file.writeString(newline);

		function writeField(name:String, value:Dynamic, level:Int, isFirst:Bool):Bool
		{
			if (value == null) return isFirst;

			if (!isFirst)
			{
				file.writeString(",");
				if (useIndentation) file.writeString(newline);
			}

			writeIndent(level);
			file.writeString('"' + name + '":');
			if (useIndentation && (Std.isOfType(value, Array) || Std.isOfType(value, Dynamic)))
				file.writeString(" ");

			if (Std.isOfType(value, String))
				file.writeString('"' + value + '"');
			else if (Std.isOfType(value, Bool))
				file.writeString(value ? "true" : "false");
			else if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
				file.writeString(Std.string(value));
			else if (Std.isOfType(value, Array))
			{
				file.writeString("[");
				var arr:Array<Dynamic> = cast value;
				for (i in 0...arr.length)
				{
					if (i > 0) file.writeString(",");
					if (useIndentation) file.writeString(newline);
					writeIndent(level + 1);
					file.writeString(Json.stringify(arr[i]));

					if (name == "notes")
					{
						var section = arr[i];
						if (section.sectionNotes != null)
						{
							var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
							processedItems += sectionNotes.length;
							updateProgress();
						}
					}
				}
				if (useIndentation && arr.length > 0) file.writeString(newline);
				writeIndent(level);
				file.writeString("]");
			}
			else
				file.writeString(Json.stringify(value));

			return false;
		}

		var level = hasWrapper ? 2 : 1;
		var first = true;
		first = writeField("song", chart.song, level, first);
		first = writeField("notes", chart.notes, level, first);
		first = writeField("events", chart.events != null ? chart.events : [], level, first);
		first = writeField("bpm", chart.bpm, level, first);
		first = writeField("needsVoices", chart.needsVoices, level, first);
		first = writeField("speed", chart.speed, level, first);
		first = writeField("offset", chart.offset, level, first);
		first = writeField("player1", chart.player1, level, first);
		first = writeField("player2", chart.player2, level, first);
		first = writeField("gfVersion", chart.gfVersion, level, first);
		first = writeField("stage", chart.stage, level, first);
		first = writeField("format", chart.format, level, first);

		if (Reflect.hasField(chart, "arrowSkin"))
			first = writeField("arrowSkin", chart.arrowSkin, level, first);
		if (Reflect.hasField(chart, "splashSkin"))
			first = writeField("splashSkin", chart.splashSkin, level, first);
		if (Reflect.hasField(chart, "gameOverChar"))
			first = writeField("gameOverChar", chart.gameOverChar, level, first);
		if (Reflect.hasField(chart, "gameOverSound"))
			first = writeField("gameOverSound", chart.gameOverSound, level, first);
		if (Reflect.hasField(chart, "gameOverLoop"))
			first = writeField("gameOverLoop", chart.gameOverLoop, level, first);
		if (Reflect.hasField(chart, "gameOverEnd"))
			first = writeField("gameOverEnd", chart.gameOverEnd, level, first);
		if (Reflect.hasField(chart, "disableNoteRGB"))
			first = writeField("disableNoteRGB", chart.disableNoteRGB, level, first);

		if (useIndentation) file.writeString(newline);
		writeIndent(level - 1);
		file.writeString("}");

		if (hasWrapper)
		{
			if (useIndentation) file.writeString(newline);
			writeIndent(0);
			file.writeString("}");
		}

		file.close();

		showMergingProgress(true, '\nFile written: $path\n', true);
	}

	private function saveMergedChart(chart:Dynamic, hasWrapper:Bool = true, indentation:Bool = false):Void
	{
		var defaultName:String = chart.song + "-merged.json";
		var tempPath = "temp_final_merged.json";

		if (temp && !rewrite) {
			var mergedTempPath = "temp_merged.json";
			if (FileSystem.exists(mergedTempPath)) {
				sys.io.File.copy(mergedTempPath, tempPath);
			} else {
				saveChartStreaming(chart, tempPath, hasWrapper, indentation, "final");
			}
		} else {
			saveChartStreaming(chart, tempPath, hasWrapper, indentation, "final");
		}

		fileDialog.saveFile(tempPath, defaultName,
			function(path:String)
			{
				showMergingProgress(false, "Merge complete!\n", true);
				trace("Chart saved to: " + path);
			},
			function()
			{
				if (FileSystem.exists(tempPath)) FileSystem.deleteFile(tempPath);
				showMergingProgress(false, "Save cancelled\n", true);
			},
			function(e:String)
			{
				if (FileSystem.exists(tempPath)) FileSystem.deleteFile(tempPath);
				showMergingProgress(false, "Error saving chart: " + e + "\n", true);
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

	override function openSubState(SubState:FlxSubState)
	{
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		super.closeSubState();
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