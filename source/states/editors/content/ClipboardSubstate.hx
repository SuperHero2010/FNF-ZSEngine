package states.editors.content;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ui.PsychUIButton;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

class ClipboardSubstate extends MusicBeatSubstate {
    public var onConfirm:String->Void;
    public var onCancel:Void->Void;

    private var fileList:Array<String> = [];
    private var selectedIndex:Int = 0;
    private var listGroup:FlxTypedGroup<FlxText>;
    private var previewText:FlxText;
    private var previewNotesText:FlxText;
    private var previewEventsText:FlxText;
    private var previewScroll:Int = 0;
    private var previewMaxLines:Int = 20;
    private var confirmButton:PsychUIButton;
    private var cancelButton:PsychUIButton;
    private var deleteButton:PsychUIButton;
    private var scrollOffset:Int = 0;
    private var maxVisibleItems:Int = 15;
    private var currentPreviewData:Dynamic = null;

    public function new() {
        super();
        createUI();
        loadClipboardList();
    }

    private function createUI():Void {
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.7;
        add(bg);

        // Left panel: list
        var listBg = new FlxSprite(20, 40).makeGraphic(300, FlxG.height - 100, FlxColor.GRAY);
        listBg.alpha = 0.8;
        add(listBg);

        var title = new FlxText(30, 50, 280, "Clipboards", 20);
        title.color = FlxColor.WHITE;
        add(title);

        listGroup = new FlxTypedGroup<FlxText>();
        add(listGroup);

        // Right panel: preview
        var previewBg = new FlxSprite(340, 40).makeGraphic(FlxG.width - 380, FlxG.height - 100, FlxColor.GRAY);
        previewBg.alpha = 0.8;
        add(previewBg);

        // Preview header
        var previewTitle = new FlxText(350, 50, FlxG.width - 400, "Preview", 16);
        previewTitle.color = FlxColor.YELLOW;
        add(previewTitle);

        // Preview info (notes/events count, timestamp)
        previewText = new FlxText(350, 70, FlxG.width - 400, "", 14);
        previewText.color = FlxColor.WHITE;
        add(previewText);

        // Preview notes list (scrollable)
        var notesLabel = new FlxText(350, 100, FlxG.width - 400, "Notes:", 14);
        notesLabel.color = FlxColor.CYAN;
        add(notesLabel);

        previewNotesText = new FlxText(350, 120, FlxG.width - 400, "", 12);
        previewNotesText.color = FlxColor.WHITE;
        add(previewNotesText);

        // Preview events list (scrollable)
        var eventsLabel = new FlxText(350, 120, FlxG.width - 400, "Events:", 14);
        eventsLabel.color = FlxColor.MAGENTA;
        add(eventsLabel);

        previewEventsText = new FlxText(350, 140, FlxG.width - 400, "", 12);
        previewEventsText.color = FlxColor.WHITE;
        add(previewEventsText);

        // Buttons
        confirmButton = new PsychUIButton(FlxG.width - 200, FlxG.height - 50, "Load", onConfirmPress);
        confirmButton.resize(80, 30);
        add(confirmButton);

        cancelButton = new PsychUIButton(FlxG.width - 110, FlxG.height - 50, "Cancel", onCancelPress);
        cancelButton.resize(80, 30);
        add(cancelButton);

        deleteButton = new PsychUIButton(FlxG.width - 290, FlxG.height - 50, "Delete", onDeletePress);
        deleteButton.resize(80, 30);
        deleteButton.normalStyle.bgColor = FlxColor.RED;
        add(deleteButton);

        // Preview scroll buttons
        var scrollUpButton = new PsychUIButton(FlxG.width - 110, 120, "▲", function() {
            if (previewScroll > 0) {
                previewScroll--;
                updatePreviewContent();
            }
        });
        scrollUpButton.resize(40, 20);
        add(scrollUpButton);

        var scrollDownButton = new PsychUIButton(FlxG.width - 110, 140, "▼", function() {
            if (currentPreviewData != null) {
                var maxScroll = 0;
                if (currentPreviewData.notes != null) maxScroll += currentPreviewData.notes.length;
                if (currentPreviewData.events != null) maxScroll += currentPreviewData.events.length;
                maxScroll -= previewMaxLines;
                if (previewScroll < maxScroll) {
                    previewScroll++;
                    updatePreviewContent();
                }
            }
        });
        scrollDownButton.resize(40, 20);
        add(scrollDownButton);
    }

    private function loadClipboardList():Void {
        var folder = "clipboards/";
        if (!FileSystem.exists(folder)) FileSystem.createDirectory(folder);
        fileList = FileSystem.readDirectory(folder).filter(f -> f.endsWith(".clipboard"));
        fileList.sort((a, b) -> b.compare(a));

        listGroup.clear();

        var startIdx = scrollOffset;
        var endIdx = Math.min(startIdx + maxVisibleItems, fileList.length);

        for (i in startIdx...endIdx) {
            var name = fileList[i];
            var displayName = name.replace('.clipboard', '');
            var parts = displayName.split('_');
            if (parts.length >= 2) {
                displayName = parts[0] + ' ' + parts[1];
            }
            var txt = new FlxText(30, 90 + (i - startIdx) * 25, 270, displayName, 14);
            txt.color = (i == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
            txt.ID = i;
            txt.scrollFactor.set();
            listGroup.add(txt);
        }

        if (fileList.length > 0) {
            if (selectedIndex >= fileList.length) selectedIndex = fileList.length - 1;
            previewSelected(selectedIndex);
        } else {
            previewText.text = "No clipboards found.";
            previewNotesText.text = "";
            previewEventsText.text = "";
            currentPreviewData = null;
        }
    }

    private function previewSelected(index:Int):Void {
        if (index < 0 || index >= fileList.length) {
            previewText.text = "Invalid selection";
            previewNotesText.text = "";
            previewEventsText.text = "";
            currentPreviewData = null;
            return;
        }

        var filePath = "clipboards/" + fileList[index];
        try {
            var content = File.getContent(filePath);
            var data = haxe.Json.parse(content);
            currentPreviewData = data;
            previewScroll = 0;

            var dateStr = Date.fromTime(data.timestamp).toString();
            previewText.text = 'Notes: ${data.noteCount}  |  Events: ${data.eventCount}  |  Date: $dateStr';

            updatePreviewContent();

        } catch (e:Dynamic) {
            previewText.text = "Error loading preview: " + e;
            previewNotesText.text = "";
            previewEventsText.text = "";
            currentPreviewData = null;
        }
    }

    private function updatePreviewContent():Void {
        if (currentPreviewData == null) return;

        var notesStr = "";
        var eventsStr = "";
        var currentLine = 0;
        var maxLines = previewMaxLines;
        var startLine = previewScroll;

        // Build notes preview
        if (currentPreviewData.notes != null && currentPreviewData.notes.length > 0) {
            var notes = currentPreviewData.notes;
            for (i in 0...notes.length) {
                if (currentLine >= startLine && currentLine < startLine + maxLines) {
                    var note = notes[i];
                    notesStr += '  [${i+1}] strumTime: ${note[0]}, noteData: ${note[1]}, sustain: ${note[2]}\n';
                }
                currentLine++;
            }
        } else {
            notesStr = '  No notes\n';
            currentLine++;
        }

        // Build events preview
        if (currentPreviewData.events != null && currentPreviewData.events.length > 0) {
            var events = currentPreviewData.events;
            for (i in 0...events.length) {
                if (currentLine >= startLine && currentLine < startLine + maxLines) {
                    var event = events[i];
                    eventsStr += '  [${i+1}] strumTime: ${event[0]}, event: ${event[1]}\n';
                }
                currentLine++;
            }
        } else {
            eventsStr = '  No events\n';
            currentLine++;
        }

        previewNotesText.text = notesStr;
        previewEventsText.text = eventsStr;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP) {
            if (selectedIndex > 0) {
                selectedIndex--;
                if (selectedIndex < scrollOffset) {
                    scrollOffset = selectedIndex;
                    loadClipboardList();
                } else {
                    updateListSelection();
                    previewSelected(selectedIndex);
                }
            }
        }
        if (FlxG.keys.justPressed.DOWN) {
            if (selectedIndex < fileList.length - 1) {
                selectedIndex++;
                if (selectedIndex >= scrollOffset + maxVisibleItems) {
                    scrollOffset = selectedIndex - maxVisibleItems + 1;
                    loadClipboardList();
                } else {
                    updateListSelection();
                    previewSelected(selectedIndex);
                }
            }
        }
        if (FlxG.keys.justPressed.ENTER) {
            onConfirmPress();
        }
        if (FlxG.keys.justPressed.ESCAPE) {
            onCancelPress();
        }
        if (FlxG.keys.justPressed.PAGE_UP) {
            if (previewScroll > 0) {
                previewScroll -= previewMaxLines;
                if (previewScroll < 0) previewScroll = 0;
                updatePreviewContent();
            }
        }
        if (FlxG.keys.justPressed.PAGE_DOWN) {
            if (currentPreviewData != null) {
                var maxScroll = 0;
                if (currentPreviewData.notes != null) maxScroll += currentPreviewData.notes.length;
                if (currentPreviewData.events != null) maxScroll += currentPreviewData.events.length;
                maxScroll -= previewMaxLines;
                if (previewScroll < maxScroll) {
                    previewScroll += previewMaxLines;
                    if (previewScroll > maxScroll) previewScroll = maxScroll;
                    updatePreviewContent();
                }
            }
        }
    }

    private function updateListSelection():Void {
        var i = 0;
        for (member in listGroup.members) {
            member.color = (i + scrollOffset == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
            i++;
        }
    }

    private function onConfirmPress():Void {
        if (selectedIndex >= 0 && selectedIndex < fileList.length) {
            if (onConfirm != null) onConfirm("clipboards/" + fileList[selectedIndex]);
        }
        close();
    }

    private function onCancelPress():Void {
        if (onCancel != null) onCancel();
        close();
    }

    private function onDeletePress():Void {
        if (selectedIndex >= 0 && selectedIndex < fileList.length) {
            var filePath = "clipboards/" + fileList[selectedIndex];
            if (FileSystem.exists(filePath)) {
                FileSystem.deleteFile(filePath);
                loadClipboardList();
                if (fileList.length > 0) {
                    if (selectedIndex >= fileList.length) selectedIndex = fileList.length - 1;
                    updateListSelection();
                    previewSelected(selectedIndex);
                } else {
                    previewText.text = "No clipboards found.";
                    previewNotesText.text = "";
                    previewEventsText.text = "";
                    currentPreviewData = null;
                }
            }
        }
    }
}