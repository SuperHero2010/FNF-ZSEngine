package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import flixel.FlxSubState;

import backend.Song;
import backend.SongJson;
import backend.MemoryUtil;
import backend.ui.*;
import states.editors.content.*;
import states.editors.content.Prompt;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;

class MergeChartState extends MusicBeatState
{
	private var chartBoxes:Array<ChartBox> = [];
	private var selectedCharts:Array<String> = [];
	private var mergeButton:PsychUIButton;
	private var fileDialog:FileDialogHandler;
	private var syncTime:Float = 0;
	private var progressUpdateTime:Float = 0.1;
	var mergeChartSave:FlxSave = new FlxSave();
	var indentation:Bool = false;
	var indentationCheckbox:PsychUICheckBox;
	var temp:Bool = true;
	var tempCheckbox:PsychUICheckBox;
	var rewrite:Bool = false;
	var rewriteCheckbox:PsychUICheckBox;
	var convertToTxt:Bool = false;
	var convertToTxtCheckbox:PsychUICheckBox;

	static public var mergeThread:sys.thread.Thread;
	private var mergeComplete:Bool = false;
	private var mergeError:String = null;
	private var mergeProgress:Float = 0;
	private var progressSubState:BasePrompt = null;

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
		});
		rewriteCheckbox.checked = (mergeChartSave.data.rewrite == true);
		rewrite = rewriteCheckbox.checked;
		add(rewriteCheckbox);

		convertToTxtCheckbox = new PsychUICheckBox(20, backButton.y - 120, "Convert to TXT", 200, function() {
			mergeChartSave.data.convertToTxt = convertToTxtCheckbox.checked;
			mergeChartSave.flush();
			convertToTxt = convertToTxtCheckbox.checked;
		});
		convertToTxtCheckbox.checked = (mergeChartSave.data.convertToTxt == true);
		convertToTxt = convertToTxtCheckbox.checked;
		add(convertToTxtCheckbox);

		fileDialog = new FileDialogHandler();
		add(fileDialog);
		fileDialog.onComplete = onFileSelected;

		if (mergeChartSave.data.indentation == null) mergeChartSave.data.indentation = false;
		indentation = mergeChartSave.data.indentation;
		if (mergeChartSave.data.temp == null) mergeChartSave.data.temp = true;
		temp = mergeChartSave.data.temp;
		if (mergeChartSave.data.rewrite == null) mergeChartSave.data.rewrite = false;
		rewrite = mergeChartSave.data.rewrite;
		if (mergeChartSave.data.convertToTxt == null) mergeChartSave.data.convertToTxt = false;
		convertToTxt = mergeChartSave.data.convertToTxt;
	}

	private function callLater(callback:Void->Void, delay:Float):Void
	{
		new FlxTimer().start(delay, function(_) { callback(); });
	}

	private function mergeChartsThread(chartPaths:Array<String>):Void
	{
		var startTime = haxe.Timer.stamp();

		var updateUI = function(msg:String) {
			callLater(function() {
				showMergingProgress(true, msg, true);
			}, 0);
		};

		try
		{
			#if cpp
			MemoryUtil.disable();
			#end

			updateUI('Loading first chart...\n');

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

			var tempPath:String = '';
			if (temp) {
				updateUI('Writing temp file...\n');
				tempPath = 'temp_merged.json';
				saveChartStreaming(baseChart, tempPath, hasWrapper, false, "base", false);
			}
			else if (convertToTxt) {
				updateUI('Converting to TXT format...\n');
				tempPath = 'temp_merged.txt';
				var txtContent = convertToTxtFormat(baseChart, hasWrapper);
				var outputFile = sys.io.File.write(tempPath, false);
				outputFile.writeString(txtContent);
				outputFile.close();
			}

			var totalCharts:Int = chartPaths.length;
			var baseChart2:Dynamic = null;

			for (i in 1...totalCharts)
			{
				var progressMsg = 'Merging chart ${i + 1}/${totalCharts}...\n';
				updateUI(progressMsg);

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
				else if (convertToTxt) {
					var txtContent = File.getContent(tempPath);
					baseChart2 = txtContent;
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
						updateUI('Fast array concatenation...\n');

						if (baseChart2 == null) {
							baseChart2 = baseChart;
						}

						if (baseChart2.notes == null) baseChart2.notes = [];
						if (baseChart2.events == null) baseChart2.events = [];

						var newNotes = extractNewNotesFromChart(nextChart);
						var newEvents = extractNewEventsFromChart(nextChart);

						var baseNotes:Array<Dynamic> = cast baseChart2.notes;
						var baseEvents:Array<Dynamic> = cast baseChart2.events;
						baseNotes = baseNotes.concat(newNotes);
						baseChart2.notes = baseNotes;
						baseEvents = baseEvents.concat(newEvents);
						baseChart2.events = baseEvents;
						updateUI('Merged ${newEvents.length} events\n');

						updateUI('Merged ${newNotes.length} notes and ${newEvents.length} events\n');

						if (!(totalCharts == 2 && i == 1)) {
							updateUI('Saving temp file...\n');
							saveChartStreaming(baseChart2, tempPath, hasWrapper, false, 'chart ${i + 1}', false);
						}
					}
					else {
						updateUI('Appending chart ${i + 1}...\n');
						appendChartToTempFile(tempPath, nextChart, hasWrapper, i + 1, indentation);
					}
				}
				else if (convertToTxt) {
					updateUI('Appending to TXT format...\n');

					var newNotes = extractNewNotesFromChart(nextChart);
					var newEvents = extractNewEventsFromChart(nextChart);

					var input = sys.io.File.read(tempPath, false);
					var content = input.readAll().toString();
					input.close();

					var notesArrayStart = content.indexOf('notes: [');
					var eventsArrayStart = content.indexOf('events:');

					if (notesArrayStart > 0 && eventsArrayStart > notesArrayStart) {
						var beforeNotes = content.substring(0, notesArrayStart + 8);
						var notesContent = content.substring(notesArrayStart + 8, eventsArrayStart);
						var afterEvents = content.substring(eventsArrayStart);

						var notesEndBracket = notesContent.lastIndexOf(']');
						var notesArrayContent = notesContent.substring(0, notesEndBracket);

						var eventsArrayBracket = afterEvents.indexOf('[');
						var eventsEndBracket = afterEvents.lastIndexOf(']');
						var eventsArrayContent = afterEvents.substring(eventsArrayBracket + 1, eventsEndBracket);

						var output = sys.io.File.write(tempPath, false);
						output.writeString(beforeNotes);
						output.writeString(notesArrayContent);

						if (newNotes.length > 0) {
							for (i in 0...newNotes.length) {
								var section = newNotes[i];
								if (i > 0 || notesArrayContent.length > 0) output.writeString(",");
								output.writeString("\n    [\n");
								output.writeString('        gfSection: ${Reflect.field(section, "gfSection")},\n');
								output.writeString('        altAnim: ${Reflect.field(section, "altAnim")},\n');
								output.writeString('        sectionNotes: ${Json.stringify(Reflect.field(section, "sectionNotes"))},\n');
								output.writeString('        bpm: ${Reflect.field(section, "bpm")},\n');
								output.writeString('        sectionBeats: ${Reflect.field(section, "sectionBeats")},\n');
								output.writeString('        changeBPM: ${Reflect.field(section, "changeBPM")},\n');
								output.writeString('        mustHitSection: ${Reflect.field(section, "mustHitSection")}\n');
								output.writeString('    ]');
							}
						}

						output.writeString("]\n");
						output.writeString(afterEvents.substring(0, eventsArrayBracket + 1));
						output.writeString(eventsArrayContent);

						if (newEvents.length > 0) {
							for (i in 0...newEvents.length) {
								var event = newEvents[i];
								if (i > 0 || eventsArrayContent.length > 0) output.writeString(",");
								output.writeString("\n    ");
								output.writeString(Json.stringify(event));
							}
						}

						output.writeString("\n]");
						output.writeString(afterEvents.substring(eventsEndBracket + 1));
						output.close();

						updateUI('Appended ${newNotes.length} notes and ${newEvents.length} events\n');
					}
				}
				else {
					updateUI('Fast array concatenation...\n');

					if (baseChart.notes == null) baseChart.notes = [];
					if (baseChart.events == null) baseChart.events = [];

					var newNotes = extractNewNotesFromChart(nextChart);
					var newEvents = extractNewEventsFromChart(nextChart);

					var baseNotes:Array<Dynamic> = cast baseChart.notes;
					var baseEvents:Array<Dynamic> = cast baseChart.events;
					baseNotes = baseNotes.concat(newNotes);
					baseChart.notes = baseNotes;
					baseEvents = baseEvents.concat(newEvents);
					baseChart.events = baseEvents;
					updateUI('Merged ${newEvents.length} events\n');

					updateUI('Merged ${newNotes.length} notes and ${newEvents.length} events\n');
				}

				nextObj = null;
				nextChart = null;

				#if cpp
				cpp.vm.Gc.run(true);
				#end
			}

			updateUI('Finalizing...\n');

			var finalChart:Dynamic;
			if (convertToTxt) {
				updateUI('Loading TXT temp file...\n');
				try {
					var txtContent = File.getContent(tempPath);
					var finalObj = convertToJsonFormat(txtContent);
					if (finalObj.song != null && Std.isOfType(finalObj.song, Dynamic))
						finalChart = finalObj.song;
					else
						finalChart = finalObj;
				} catch(e:Dynamic) {
					updateUI('Error loading TXT: ' + Std.string(e) + '\n');
					finalChart = baseChart;
				}
			}
			else if (temp) {
				if (rewrite) {
					updateUI('Saving temp file...\n');
					saveChartStreaming(baseChart2, tempPath, hasWrapper, false, "temp", false);
					var baseData = File.getContent(tempPath);
					var baseObj = SongJson.parse(baseData);
					if (baseObj.song != null && Std.isOfType(baseObj.song, Dynamic))
						finalChart = baseObj.song;
					else
						finalChart = baseObj;
				}
				else {
					var baseData = File.getContent(tempPath);
					var baseObj = SongJson.parse(baseData);
					if (baseObj.song != null && Std.isOfType(baseObj.song, Dynamic))
						finalChart = baseObj.song;
					else
						finalChart = baseObj;
				}
			}
			else {
				finalChart = baseChart;
			}

			callLater(function() {
				if (finalChart == null) {
					trace('ERROR: finalChart is null, cannot save merged chart');
					updateUI('ERROR: finalChart is null, cannot save merged chart\n');
					return;
				}
				saveMergedChart(finalChart, hasWrapper, indentation, convertToTxt);
			}, 0);

			#if cpp
			MemoryUtil.enable();
			MemoryUtil.collect(true);
			#end

			if (temp && rewrite && FileSystem.exists(tempPath))
				FileSystem.deleteFile(tempPath);
			else if (temp && !rewrite && FileSystem.exists(tempPath))
				FileSystem.deleteFile(tempPath);

			trace('Merge completed in ' + (haxe.Timer.stamp() - startTime) + ' seconds');
			mergeComplete = true;
		}
		catch(e:Dynamic)
		{
			mergeError = Std.string(e);
			callLater(function() {
				showMergingProgress(false, 'Error: ' + mergeError + '\n', true);
			}, 0);
		}
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

		mergeButton.active = false;
		mergeButton.alpha = 0.5;

		mergeComplete = false;
		mergeError = null;
		mergeProgress = 0;

		mergeThread = sys.thread.Thread.create(function() {
			mergeChartsThread(chartPaths);
			mergeComplete = true;
		});

		checkThreadComplete();
	}

	private function checkThreadComplete():Void
	{
		if (mergeComplete)
		{
			mergeButton.active = true;
			mergeButton.alpha = 1;
			if (mergeError != null)
			{
				callLater(function() {
					showMergingProgress(false, "Merge failed: " + mergeError, true);
				}, 0);
				mergeThread = null;
			}
			else
			{
				callLater(function() {
					showMergingProgress(false, "Merge complete!", true);
				}, 0);
				mergeThread = null;
			}
		}
		else
		{
			callLater(checkThreadComplete, 0.1);
		}
	}

	/* Old function
	private function mergeCharts(chartPaths:Array<String>)
	{
		trace('mergeCharts() called with ' + chartPaths.length + ' charts');

		if (chartPaths.length < 2) {
			trace('mergeCharts: Less than 2 charts, returning');
			return;
		}

		#if cpp
		MemoryUtil.disable();
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
		MemoryUtil.enable();
		MemoryUtil.collect(true);
		#end

		if (FileSystem.exists(tempPath))
			FileSystem.deleteFile(tempPath);
	}
	*/

	private function appendChartToTempFile(tempPath:String, nextChart:Dynamic, hasWrapper:Bool, chartIndex:Int, indentation:Bool = false):Void
	{
		var newNotes = extractNewNotesFromChart(nextChart);
		var newEvents = extractNewEventsFromChart(nextChart);

		if (newNotes.length == 0 && newEvents.length == 0) {
			return;
		}

		var fileIndentation = detectIndentation(tempPath);
		var useIndentation = fileIndentation || indentation;

		var positions = findBothArrayEndPositions(tempPath);
		var notesEndPos = positions.notes;
		var eventsEndPos = positions.events;

		var shouldAppend = true;

		if (notesEndPos == -1 || eventsEndPos == -1) {
			shouldAppend = false;
			var funcYes = function() {
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

		if (shouldAppend) {
			showMergingProgress(true, '\nReading file for in-place modification...\n');

			var content = File.getContent(tempPath);

			#if cpp
			Sys.sleep(0.001);
			#end

			showMergingProgress(true, 'Building new notes string...\n');

			var newNotesStr = "";
			if (newNotes.length > 0) {
				if (useIndentation) newNotesStr += ",\n\t\t";
				else newNotesStr += ",";
				for (i in 0...newNotes.length) {
					if (useIndentation) newNotesStr += "\t\t\t";
					newNotesStr += Json.stringify(newNotes[i]);
					if (i < newNotes.length - 1) {
						if (useIndentation) newNotesStr += ",\n\t\t\t";
						else newNotesStr += ",";
					}

					showMergingProgress(true, 'Building notes: $i/${newNotes.length}');
					#if cpp
					Sys.sleep(0.001);
					#end
				}
				if (useIndentation) newNotesStr += "\n\t";
			}

			showMergingProgress(true, 'Building new events string...\n');

			var newEventsStr = "";
			if (newEvents.length > 0) {
				if (useIndentation) newEventsStr += ",\n\t\t";
				else newEventsStr += ",";
				for (i in 0...newEvents.length) {
					if (useIndentation) newEventsStr += "\t\t\t";
					newEventsStr += Json.stringify(newEvents[i]);
					if (i < newEvents.length - 1) {
						if (useIndentation) newEventsStr += ",\n\t\t\t";
						else newEventsStr += ",";
					}

					showMergingProgress(true, 'Building events: $i/${newEvents.length}');
					#if cpp
					Sys.sleep(0.001);
					#end
				}
				if (useIndentation) newEventsStr += "\n\t";
			}

			showMergingProgress(true, 'Modifying file content...\n');

			var beforeNotes = content.substring(0, notesEndPos + 1);
			var betweenArrays = content.substring(notesEndPos + 1, eventsEndPos + 1);
			var afterEvents = content.substring(eventsEndPos + 1);

			var newContent = beforeNotes + newNotesStr + betweenArrays + newEventsStr + afterEvents;

			showMergingProgress(true, 'Writing modified content back to file...\n');

			var outputFile = sys.io.File.write(tempPath, false);
			outputFile.writeString(newContent);
			outputFile.close();

			showMergingProgress(true, 'Appended ${newNotes.length} notes and ${newEvents.length} events\n');
		}
	}

	private function convertToTxtFormat(chart:Dynamic, hasWrapper:Bool):String
	{
		var sb = new StringBuf();

		if (hasWrapper) {
			sb.add('songWrapper: true\n');
			sb.add('speed: ${Reflect.field(chart, "speed")}\n');
			sb.add('bpm: ${Reflect.field(chart, "bpm")}\n');
			sb.add('stage: "${Reflect.field(chart, "stage")}"\n');
			sb.add('player1: "${Reflect.field(chart, "player1")}"\n');
			sb.add('player2: "${Reflect.field(chart, "player2")}"\n');
			sb.add('events: ${Json.stringify(Reflect.field(chart, "events"))}\n');
		} else {
			sb.add('songWrapper: false\n');
			sb.add('speed: ${Reflect.field(chart, "speed")}\n');
			sb.add('bpm: ${Reflect.field(chart, "bpm")}\n');
			sb.add('stage: "${Reflect.field(chart, "stage")}"\n');
			sb.add('player1: "${Reflect.field(chart, "player1")}"\n');
			sb.add('player2: "${Reflect.field(chart, "player2")}"\n');
			sb.add('events: ${Json.stringify(Reflect.field(chart, "events"))}\n');
		}

		sb.add('notes: [\n');
		var notes = Reflect.field(chart, "notes");
		if (notes != null) {
			for (i in 0...notes.length) {
				var section = notes[i];
				sb.add('    [\n');
				sb.add('        gfSection: ${Reflect.field(section, "gfSection")},\n');
				sb.add('        altAnim: ${Reflect.field(section, "altAnim")},\n');
				sb.add('        sectionNotes: ${Json.stringify(Reflect.field(section, "sectionNotes"))},\n');
				sb.add('        bpm: ${Reflect.field(section, "bpm")},\n');
				sb.add('        sectionBeats: ${Reflect.field(section, "sectionBeats")},\n');
				sb.add('        changeBPM: ${Reflect.field(section, "changeBPM")},\n');
				sb.add('        mustHitSection: ${Reflect.field(section, "mustHitSection")}\n');
				sb.add('    ]');
				if (i < notes.length - 1) sb.add(',\n');
				else sb.add('\n');
			}
		}
		sb.add(']\n');

		if (hasWrapper) {
			sb.add('gfVersion: "${Reflect.field(chart, "gfVersion")}"\n');
			sb.add('format: "psych_v1"\n');
			sb.add('bpm: ${Reflect.field(chart, "bpm")}\n');
			sb.add('needsVoices: ${Reflect.field(chart, "needsVoices")}\n');
			sb.add('song: "${Reflect.field(chart, "song")}"\n');
			sb.add('offset: ${Reflect.field(chart, "offset")}\n');
		} else {
			sb.add('gfVersion: "${Reflect.field(chart, "gfVersion")}"\n');
			sb.add('bpm: ${Reflect.field(chart, "bpm")}\n');
			sb.add('needsVoices: ${Reflect.field(chart, "needsVoices")}\n');
			sb.add('song: "${Reflect.field(chart, "song")}"\n');
		}

		return sb.toString();
	}

	private function valueToTxt(value:Dynamic):String
	{
		if (value == null)
			return "null";
		if (Std.isOfType(value, String))
			return '"' + value + '"';
		if (Std.isOfType(value, Bool))
			return value ? "true" : "false";
		if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
			return Std.string(value);
		if (Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			var result = new StringBuf();
			result.add("[");
			for (i in 0...arr.length)
			{
				if (i > 0) result.add(",");
				result.add(valueToTxt(arr[i]));
			}
			result.add("]");
			return result.toString();
		}
		if (Reflect.isObject(value))
		{
			var result = new StringBuf();
			result.add("{");
			var fields = Reflect.fields(value);
			for (i in 0...fields.length)
			{
				if (i > 0) result.add(",");
				result.add(fields[i]);
				result.add(":");
				result.add(valueToTxt(Reflect.field(value, fields[i])));
			}
			result.add("}");
			return result.toString();
		}
		return Json.stringify(value);
	}

	private function convertToJsonFormat(txtContent:String):Dynamic
	{
		trace("convertToJsonFormat() called");
		var lines = txtContent.split('\n');
		var result:Dynamic = {};
		var songWrapper:Bool = false;
		var inNotesArray = false;
		var inSection = false;
		var currentSection:Dynamic = null;
		var notesArray:Array<Dynamic> = [];
		var sectionNotesStr = "";

		for (line in lines) {
			line = StringTools.trim(line);
			if (line.length == 0) continue;

			if (line.startsWith('songWrapper:')) {
				songWrapper = line.substring(13) == 'true';
				continue;
			}

			if (line == 'notes: [') {
				inNotesArray = true;
				continue;
			}

			if (line == ']') {
				if (inSection) {
					if (sectionNotesStr.length > 0) {
						try {
							var parsedNotes = Json.parse(sectionNotesStr);
							trace('Successfully parsed sectionNotes: $sectionNotesStr -> $parsedNotes');
							Reflect.setField(currentSection, "sectionNotes", parsedNotes);
						} catch(e:Dynamic) {
							trace('Error parsing sectionNotes: "$sectionNotesStr", error: $e');
							Reflect.setField(currentSection, "sectionNotes", []);
						}
					} else {
						trace('sectionNotesStr is empty, setting to []');
						Reflect.setField(currentSection, "sectionNotes", []);
					}
					notesArray.push(currentSection);
					currentSection = null;
					inSection = false;
					sectionNotesStr = "";
				}
				if (inNotesArray) {
					inNotesArray = false;
					Reflect.setField(result, "notes", notesArray);
				}
				continue;
			}

			if (inNotesArray) {
				if (line == '[') {
					inSection = true;
					currentSection = {};
					continue;
				}

				if (inSection) {
					if (line.startsWith('sectionNotes:')) {
						sectionNotesStr = line.substring(13);
						sectionNotesStr = StringTools.trim(sectionNotesStr);
						if (sectionNotesStr.endsWith(',')) sectionNotesStr = sectionNotesStr.substring(0, sectionNotesStr.length - 1);
					} else if (line.indexOf(':') > 0) {
						var parts = line.split(':');
						var key = StringTools.trim(parts[0]);
						var value = StringTools.trim(parts[1]);
						if (value.endsWith(',')) value = value.substring(0, value.length - 1);

						if (value == 'true') Reflect.setField(currentSection, key, true);
						else if (value == 'false') Reflect.setField(currentSection, key, false);
						else if (value.startsWith('"')) Reflect.setField(currentSection, key, value.substring(1, value.length - 1));
						else Reflect.setField(currentSection, key, Std.parseInt(value));
					}
				}
			} else {
				if (line.indexOf(':') > 0) {
					var parts = line.split(':');
					var key = StringTools.trim(parts[0]);
					var value = StringTools.trim(parts[1]);

					if (value.startsWith('[') || value.startsWith('{')) {
						Reflect.setField(result, key, Json.parse(value));
					} else if (value == 'true') {
						Reflect.setField(result, key, true);
					} else if (value == 'false') {
						Reflect.setField(result, key, false);
					} else if (value.startsWith('"')) {
						Reflect.setField(result, key, value.substring(1, value.length - 1));
					} else {
						Reflect.setField(result, key, Std.parseInt(value));
					}
				}
			}
		}

		if (songWrapper) {
			var wrapped:Dynamic = {};
			Reflect.setField(wrapped, "song", result);
			return wrapped;
		}
		return result;
	}

	private function copyChunk(inputFile:sys.io.FileInput, outputFile:sys.io.FileOutput, bytesToCopy:Int, message:String):Void
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

			if (bytesCopied % (bufferSize * 10) == 0) {
				var percent = Math.floor((bytesCopied / bytesToCopy) * 100);
				showMergingProgress(true, '$message $percent%');
			}
		}
		showMergingProgress(true, '$message 100%\n');
	}

	private function detectIndentation(filePath:String):Bool
	{
		var file = sys.io.File.read(filePath, false);
		var chunk = file.read(4096);
		file.close();

		var chunkStr = chunk.toString();
		return chunkStr.indexOf('\n\t') != -1 || chunkStr.indexOf('\n  ') != -1;
	}

	private function findBothArrayEndPositions(filePath:String):{notes:Int, events:Int}
	{
		showMergingProgress(true, 'Finding append positions... 0%');

		var content = File.getContent(filePath);

		var notesEndPos = -1;
		var eventsEndPos = -1;

		var notesIdx = content.indexOf('"notes"');
		var eventsIdx = content.indexOf('"events"');

		if (notesIdx != -1) {
			var searchEnd = (eventsIdx != -1) ? eventsIdx : content.length;
			var searchArea = content.substring(notesIdx, searchEnd);

			var openBrackets = searchArea.split('[').length - 1;
			var closeBrackets = 0;
			var pos = notesIdx;
			var targetClose = openBrackets;

			while (closeBrackets < targetClose && pos < searchEnd) {
				var nextClose = content.indexOf(']', pos);
				if (nextClose == -1 || nextClose >= searchEnd) break;
				closeBrackets++;
				pos = nextClose + 1;

				if (closeBrackets % 10 == 0) {
					var percent = Math.floor((closeBrackets / targetClose) * 50);
					showMergingProgress(true, 'Finding append positions... $percent%');
				}
			}

			if (closeBrackets == targetClose) {
				notesEndPos = pos - 1;
			}
		}

		if (eventsIdx != -1) {
			var searchArea = content.substring(eventsIdx);
			var openBrackets = searchArea.split('[').length - 1;
			var closeBrackets = 0;
			var pos = eventsIdx;
			var targetClose = openBrackets;

			while (closeBrackets < targetClose && pos < content.length) {
				var nextClose = content.indexOf(']', pos);
				if (nextClose == -1) break;
				closeBrackets++;
				pos = nextClose + 1;

				if (closeBrackets % 10 == 0) {
					var percent = Math.floor((closeBrackets / targetClose) * 50) + 50;
					showMergingProgress(true, 'Finding append positions... $percent%');
				}
			}

			if (closeBrackets == targetClose) {
				eventsEndPos = pos - 1;
			}
		}

		showMergingProgress(true, 'Finding append positions... 100%\n');
		return {notes: notesEndPos, events: eventsEndPos};
	}

	private function extractNewNotesFromChart(chart:Dynamic):Array<Dynamic>
	{
		var newNotes:Array<Dynamic> = [];

		if (chart.notes != null) {
			var notes:Array<Dynamic> = cast chart.notes;
			for (section in notes) {
				newNotes.push(section);
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

	var parsedNotes:Int = 0;
	var parsedEvents:Int = 0;
	private function mergeInto(baseSong:Dynamic, nextSong:Dynamic):Void
	{
		if (baseSong.notes == null)
		{
			baseSong.notes = [];
		}
		if (baseSong.events == null)
		{
			baseSong.events = [];
		}

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

	private function showMergingProgress(show:Bool, message:String, force:Bool = false, ?updateSubState:Bool = true)
	{
		if (!show)
		{
			if (progressSubState != null)
			{
				try {
					closeSubState();
				} catch(e:Dynamic) {
					trace('Error closing substate: $e');
				}
				progressSubState = null;
			}
		}
		else
		{
			if (progressSubState == null || force)
			{
				if (progressSubState != null)
				{
					try {
						closeSubState();
					} catch(e:Dynamic) {
						trace('Error closing substate: $e');
					}
					progressSubState = null;
				}
				try {
					progressSubState = new BasePrompt(420, 160, '$message');
					openSubState(progressSubState);
				} catch(e:Dynamic) {
					trace('Error opening substate: $e');
					progressSubState = null;
				}
			}
			else
			{
				try {
					if (progressSubState.titleText != null && updateSubState) {
						progressSubState.titleText.text = '$message';
					}
				} catch(e:Dynamic) {
					trace('Error updating substate text: $e');
				}
			}

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
	}

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

	function saveChartStreaming(chart:Dynamic, path:String, hasWrapper:Bool = true, useIndentation:Bool = false, ?message:String, silent:Bool = false):Void
	{
		var file = sys.io.File.write(path, false);
		var buffer = new StringBuf();
		var flushCount = 0;
		var flushThreshold = 1000;

		function flushBuffer():Void
		{
			if (buffer.length > 0)
			{
				file.writeString(buffer.toString());
				buffer = new StringBuf();
			}
		}

		function writeString(str:String):Void
		{
			buffer.add(str);
			flushCount++;
			if (flushCount >= flushThreshold)
			{
				flushBuffer();
				flushCount = 0;
			}
		}

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
		var lastProgressUpdate = 0;
		var progressUpdateThreshold:Int = totalItems > 1000000 ? 100000 : 1000;

		function updateProgress():Void
		{
			if (silent) return;
			if (totalItems > 0)
			{
				processedItems++;
				if (processedItems - lastProgressUpdate >= progressUpdateThreshold || processedItems == totalItems)
				{
					var percent = Std.int((processedItems / totalItems) * 100);
					showMergingProgress(true, 'Writing ' + message + ' ... $percent%', false);
					lastProgressUpdate = processedItems;
				}
			}
		}

		var newline = useIndentation ? "\n" : "";

		function writeIndent(level:Int):Void
		{
			if (useIndentation)
			{
				for (i in 0...level)
					writeString("\t");
			}
		}

		if (hasWrapper)
		{
			writeString('{"song":');
			if (useIndentation) writeString(newline);
		}

		writeIndent(useIndentation ? 1 : 0);
		writeString("{");
		if (useIndentation) writeString(newline);

		function writeField(name:String, value:Dynamic, level:Int, isFirst:Bool):Bool
		{
			if (value == null) return isFirst;

			if (!isFirst)
			{
				writeString(",");
				if (useIndentation) writeString(newline);
			}

			writeIndent(level);
			writeString('"' + name + '":');
			if (useIndentation && (Std.isOfType(value, Array) || Std.isOfType(value, Dynamic)))
				writeString(" ");

			if (Std.isOfType(value, String))
				writeString('"' + value + '"');
			else if (Std.isOfType(value, Bool))
				writeString(value ? "true" : "false");
			else if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
				writeString(Std.string(value));
			else if (Std.isOfType(value, Array))
			{
				writeString("[");
				var arr:Array<Dynamic> = cast value;
				for (i in 0...arr.length)
				{
					if (i > 0) writeString(",");
					if (useIndentation) writeString(newline);
					writeIndent(level + 1);
					writeString(Json.stringify(arr[i]));

					if (name == "notes")
					{
						var section = arr[i];
						if (section.sectionNotes != null)
						{
							var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
							for (note in sectionNotes)
							{
								updateProgress();
							}
						}
					}
					else if (name == "events")
					{
						updateProgress();
					}
				}
				if (useIndentation && arr.length > 0) writeString(newline);
				writeIndent(level);
				writeString("]");
			}
			else
				writeString(Json.stringify(value));

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

		if (useIndentation) writeString(newline);
		writeIndent(level - 1);
		writeString("}");

		if (hasWrapper)
		{
			if (useIndentation) writeString(newline);
			writeIndent(0);
			writeString("}");
		}

		flushBuffer();
		file.close();

		showMergingProgress(true, '\nFile written: $path\n', true);
	}

	private function saveMergedChart(chart:Dynamic, hasWrapper:Bool = true, indentation:Bool = false, txt:Bool = false):Void
	{
		var defaultName:String = chart.song + "-merged.json";
		var tempPath:String;

		if (!txt) {
			tempPath = "temp_final_merged.json";
			saveChartStreaming(chart, tempPath, hasWrapper, indentation, "final");
		}
		else {
			tempPath = "temp_final_merged.txt";
			var txtContent = convertToTxtFormat(chart, hasWrapper);
			var outputFile = sys.io.File.write(tempPath, false);
			outputFile.writeString(txtContent);
			tempPath = "temp_final_merged.json";
			var jsonContent = convertToJsonFormat(txtContent);
			saveChartStreaming(jsonContent, tempPath, hasWrapper, indentation, "final");
			outputFile.close();
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

	override function destroy()
	{
		if (MergeChartState.mergeThread != null)
		{
			MergeChartState.mergeThread = null;
		}
		super.destroy();
	}
}