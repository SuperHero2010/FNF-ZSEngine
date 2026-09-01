package states.editors.content;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ui.PsychUIButton;
import states.editors.ChartingState;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

class ClipboardSubstate extends MusicBeatSubstate
{
    public var onConfirm:String->Void;
    public var onCancel:Void->Void;

    private var fileList:Array<String> = [];
    private var selectedIndex:Int = 0;
    private var listGroup:FlxTypedGroup<FlxText>;
    private var previewText:FlxText;
    private var previewContainer:FlxTypedGroup<FlxSprite>;
    private var confirmButton:PsychUIButton;
    private var cancelButton:PsychUIButton;
    private var deleteButton:PsychUIButton;
    private var currentPreviewData:Dynamic = null;
    private var chartingState:ChartingState;
    private var previewScroll:Float = 0;
    private var previewScrollSpeed:Float = 50;

    public function new(chartingState:ChartingState)
    {
        super();
        this.chartingState = chartingState;
        this.persistentUpdate = true;
        createUI();
        loadClipboardList();
    }

    private function createUI():Void
    {
        var width:Int = 900;
        var height:Int = 600;
        var x:Float = (FlxG.width - width) / 2;
        var y:Float = (FlxG.height - height) / 2;

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.7;
        bg.scrollFactor.set();
        add(bg);

        var containerBg = new FlxSprite(x - 10, y - 10).makeGraphic(width + 20, height + 20, FlxColor.GRAY);
        containerBg.alpha = 0.95;
        containerBg.scrollFactor.set();
        add(containerBg);

        var title = new FlxText(x + width/2 - 50, y + 10, 100, "Clipboards", 24);
        title.color = FlxColor.WHITE;
        title.alignment = CENTER;
        title.scrollFactor.set();
        add(title);

        // Left panel: list
        var listBg = new FlxSprite(x, y + 40).makeGraphic(280, height - 80, FlxColor.GRAY);
        listBg.alpha = 0.8;
        listBg.scrollFactor.set();
        add(listBg);

        var listTitle = new FlxText(x + 10, y + 50, 260, "Saved Clipboards", 16);
        listTitle.color = FlxColor.YELLOW;
        listTitle.scrollFactor.set();
        add(listTitle);

        listGroup = new FlxTypedGroup<FlxText>();
        add(listGroup);

        // Right panel: preview container
        var previewBg = new FlxSprite(x + 290, y + 40).makeGraphic(width - 300, height - 80, FlxColor.GRAY);
        previewBg.alpha = 0.8;
        previewBg.scrollFactor.set();
        add(previewBg);

        var previewTitle = new FlxText(x + 300, y + 50, width - 320, "Preview", 16);
        previewTitle.color = FlxColor.YELLOW;
        previewTitle.scrollFactor.set();
        add(previewTitle);

        previewText = new FlxText(x + 300, y + 70, width - 320, "", 14);
        previewText.color = FlxColor.WHITE;
        previewText.scrollFactor.set();
        add(previewText);

        // Preview container for ALL notes and events (no limit)
        previewContainer = new FlxTypedGroup<FlxSprite>();
        add(previewContainer);

        // Buttons
        deleteButton = new PsychUIButton(x + width - 310, y + height - 35, "Delete", onDeletePress);
        deleteButton.resize(80, 30);
        deleteButton.normalStyle.bgColor = FlxColor.RED;
        deleteButton.scrollFactor.set();
        add(deleteButton);

        cancelButton = new PsychUIButton(x + width - 220, y + height - 35, "Cancel", onCancelPress);
        cancelButton.resize(80, 30);
        cancelButton.scrollFactor.set();
        add(cancelButton);

        confirmButton = new PsychUIButton(x + width - 130, y + height - 35, "Load", onConfirmPress);
        confirmButton.resize(80, 30);
        confirmButton.normalStyle.bgColor = FlxColor.GREEN;
        confirmButton.scrollFactor.set();
        add(confirmButton);

        // Scroll for preview
        var scrollUpButton = new PsychUIButton(x + width - 70, y + 80, "▲", function()
        {
            previewScroll -= previewScrollSpeed;
            if (previewScroll < 0) previewScroll = 0;
            updatePreviewContent();
        });
        scrollUpButton.resize(30, 20);
        scrollUpButton.scrollFactor.set();
        add(scrollUpButton);

        var scrollDownButton = new PsychUIButton(x + width - 70, y + 100, "▼", function()
        {
            previewScroll += previewScrollSpeed;
            updatePreviewContent();
        });
        scrollDownButton.resize(30, 20);
        scrollDownButton.scrollFactor.set();
        add(scrollDownButton);
    }

    private function loadClipboardList():Void
    {
        var folder = "clipboards/";
        if (!FileSystem.exists(folder)) FileSystem.createDirectory(folder);
        fileList = FileSystem.readDirectory(folder).filter(f -> f.endsWith(".clipboard"));
        fileList.sort((a, b) ->
        {
            if (a > b) return -1;
            if (a < b) return 1;
            return 0;
        });

        listGroup.clear();

        for (i in 0...fileList.length)
        {
            var name = fileList[i];
            var displayName = name.replace('.clipboard', '');
            var parts = displayName.split('_');
            if (parts.length >= 2)
            {
                displayName = parts[0] + ' ' + parts[1];
            }
            var txt = new FlxText(30, 90 + i * 25, 270, displayName, 14);
            txt.color = (i == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
            txt.ID = i;
            txt.scrollFactor.set();
            listGroup.add(txt);
        }

        if (fileList.length > 0)
        {
            if (selectedIndex >= fileList.length) selectedIndex = fileList.length - 1;
            previewSelected(selectedIndex);
        }
        else
        {
            previewText.text = "No clipboards found.";
            previewContainer.clear();
            currentPreviewData = null;
        }
    }

    private function previewSelected(index:Int):Void
    {
        if (index < 0 || index >= fileList.length)
        {
            previewText.text = "Invalid selection";
            previewContainer.clear();
            currentPreviewData = null;
            return;
        }

        var filePath = "clipboards/" + fileList[index];
        try
        {
            var content = File.getContent(filePath);
            var data = haxe.Json.parse(content);
            currentPreviewData = data;
            previewScroll = 0;

            var dateStr = Date.fromTime(data.timestamp).toString();
            previewText.text = 'Notes: ${data.noteCount}  |  Events: ${data.eventCount}  |  Date: $dateStr';

            updatePreviewContent();
        }
        catch (e:Dynamic)
        {
            previewText.text = "Error loading preview: " + e;
            previewContainer.clear();
            currentPreviewData = null;
        }
    }

    private function updatePreviewContent():Void
    {
        previewContainer.clear();

        if (currentPreviewData == null) return;

        var gridBgX = chartingState.gridBg.x;
        var gridSize = ChartingState.GRID_SIZE;
        var curZoom = chartingState.curZoom;
        var cachedSectionCrochets = chartingState.cachedSectionCrochets;
        var cachedSectionTimes = chartingState.cachedSectionTimes;
        var cachedSectionRow = chartingState.cachedSectionRow;
        var gridBg = chartingState.gridBg;
        var showEventColumn = ChartingState.SHOW_EVENT_COLUMN;

        // Render ALL notes
        if (currentPreviewData.notes != null && currentPreviewData.notes.length > 0)
        {
            var notes = currentPreviewData.notes;
            var sectionTime = cachedSectionTimes[0];
            var crochet = cachedSectionCrochets[0];
            var row = cachedSectionRow[0];

            for (i in 0...notes.length)
            {
                var noteData = notes[i];
                var metaNote = chartingState.createNote(noteData, 0);
                if (metaNote != null)
                {
                    var strumTime = noteData[0];
                    var noteColumn = noteData[1];
                    var time = strumTime - sectionTime;
                    var noteYPos = (time / crochet) * gridSize * 4 * curZoom;
                    noteYPos += row * gridSize * curZoom;
                    noteYPos = Math.max(noteYPos, -150);

                    var xPos = gridBgX;
                    if (showEventColumn) xPos += gridSize;
                    xPos += noteColumn * gridSize;

                    metaNote.x = xPos;
                    metaNote.y = gridBg.y + noteYPos - previewScroll;
                    metaNote.scale.set(1.0, 1.0);
                    previewContainer.add(metaNote);
                }
            }
        }

        // Render ALL events
        if (currentPreviewData.events != null && currentPreviewData.events.length > 0)
        {
            var events = currentPreviewData.events;
            var sectionTime = cachedSectionTimes[0];
            var crochet = cachedSectionCrochets[0];
            var row = cachedSectionRow[0];

            for (i in 0...events.length)
            {
                var eventData = events[i];
                var eventNote = chartingState.createEvent(eventData);
                if (eventNote != null)
                {
                    var strumTime = eventData[0];
                    var time = strumTime - sectionTime;
                    var noteYPos = (time / crochet) * gridSize * 4 * curZoom;
                    noteYPos += row * gridSize * curZoom;
                    noteYPos = Math.max(noteYPos, -150);

                    eventNote.x = gridBgX;
                    eventNote.y = gridBg.y + noteYPos - previewScroll;
                    eventNote.scale.set(1.0, 1.0);
                    previewContainer.add(eventNote);
                }
            }
        }
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP)
        {
            if (selectedIndex > 0)
            {
                selectedIndex--;
                updateListSelection();
                previewSelected(selectedIndex);
            }
        }
        if (FlxG.keys.justPressed.DOWN)
        {
            if (selectedIndex < fileList.length - 1)
            {
                selectedIndex++;
                updateListSelection();
                previewSelected(selectedIndex);
            }
        }
        if (FlxG.keys.justPressed.ENTER) onConfirmPress();
        if (FlxG.keys.justPressed.ESCAPE) onCancelPress();

        if (FlxG.mouse.wheel != 0)
        {
            previewScroll -= FlxG.mouse.wheel * 20;
            if (previewScroll < 0) previewScroll = 0;
            updatePreviewContent();
        }
    }

    private function updateListSelection():Void
    {
        var i = 0;
        for (member in listGroup.members)
        {
            member.color = (i == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
            i++;
        }
    }

    private function onConfirmPress():Void
    {
        if (selectedIndex >= 0 && selectedIndex < fileList.length)
        {
            if (onConfirm != null) onConfirm("clipboards/" + fileList[selectedIndex]);
        }
        close();
    }

    private function onCancelPress():Void
    {
        if (onCancel != null) onCancel();
        close();
    }

    private function onDeletePress():Void
    {
        if (selectedIndex >= 0 && selectedIndex < fileList.length)
        {
            var filePath = "clipboards/" + fileList[selectedIndex];
            if (FileSystem.exists(filePath))
            {
                FileSystem.deleteFile(filePath);
                loadClipboardList();
                if (fileList.length > 0)
                {
                    if (selectedIndex >= fileList.length) selectedIndex = fileList.length - 1;
                    updateListSelection();
                    previewSelected(selectedIndex);
                }
                else
                {
                    previewText.text = "No clipboards found.";
                    previewContainer.clear();
                    currentPreviewData = null;
                }
            }
        }
    }
}