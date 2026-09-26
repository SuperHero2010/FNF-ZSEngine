package states.editors;

import objects.Note;
import objects.NoteSplash;

import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
import openfl.events.Event;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;

import backend.ui.*;
import haxe.Json;

typedef SpriteFrame = {
    name:String,
    x:Int,
    y:Int,
    w:Int,
    h:Int
}

class NoteRGBExporterState extends MusicBeatState
{
    var noteFrames:Array<SpriteFrame> = [];
    var splashFrames:Array<SpriteFrame> = [];
    var noteBitmap:BitmapData;
    var splashBitmap:BitmapData;
    var noteSkin:String = '';
    var splashSkin:String = '';

    var orderDirs:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
    var orderColors:Array<String> = ['purple', 'blue', 'green', 'red'];
    var orderDirLower:Array<String> = ['left', 'down', 'up', 'right'];

    var backButton:PsychUIButton;
    var disableRGBCheckbox:PsychUICheckBox;
    var disableNoteRGB:Bool = false;

    var splashSprites:Array<FlxSprite> = [];
    var confirmSprites:Array<FlxSprite> = [];
    var noteSprites:Array<FlxSprite> = [];
    var normalStrumSprites:Array<FlxSprite> = [];
    var strumSprites:Array<FlxSprite> = [];
    var sustainSprites:Array<FlxSprite> = [];
    var sustainEndSprites:Array<FlxSprite> = [];
    var splashAnimTime:Float = 0;
    var strumAnimTime:Float = 0;

    var splashExportButtons:Array<PsychUIButton> = [];
    var confirmExportButtons:Array<PsychUIButton> = [];
    var noteExportButtons:Array<PsychUIButton> = [];
    var normalStrumExportButtons:Array<PsychUIButton> = [];
    var strumExportButtons:Array<PsychUIButton> = [];
    var sustainExportButtons:Array<PsychUIButton> = [];
    var sustainEndExportButtons:Array<PsychUIButton> = [];

    var rSteppers:Array<PsychUINumericStepper> = [];
    var gSteppers:Array<PsychUINumericStepper> = [];
    var bSteppers:Array<PsychUINumericStepper> = [];

    var _file:FileReference;

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

        var title:FlxText = new FlxText(0, 6, FlxG.width, 'Note RGB Exporter', 28);
        title.alignment = CENTER;
        title.color = FlxColor.WHITE;
        add(title);

        noteSkin = Note.defaultNoteSkin;
        noteBitmap = Paths.image(noteSkin).bitmap;
        noteFrames = loadFramesFromXML('images/$noteSkin.xml');

        splashSkin = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
        if (!Paths.fileExists('images/$splashSkin.png', IMAGE))
            splashSkin = NoteSplash.defaultNoteSplash;
        splashBitmap = Paths.image(splashSkin).bitmap;
        splashFrames = loadFramesFromXML('images/$splashSkin.xml');

        buildLayout();

        backButton = new PsychUIButton(20, FlxG.height - 50, 'Back', function() {
            MusicBeatState.switchState(new MasterEditorMenu());
        });
        backButton.resize(100, 40);
        add(backButton);

        disableRGBCheckbox = new PsychUICheckBox(FlxG.width - 220, FlxG.height - 50, 'Disable Note RGB', 150, function() {
            disableNoteRGB = disableRGBCheckbox.checked;
            refreshUI();
        });
        disableRGBCheckbox.checked = disableNoteRGB;
        add(disableRGBCheckbox);

        super.create();
    }

    function loadFramesFromXML(xmlPath:String):Array<SpriteFrame>
    {
        var result:Array<SpriteFrame> = [];
        if (!Paths.fileExists(xmlPath, TEXT)) return result;

        var xml:Xml = Xml.parse(Paths.getTextFromFile(xmlPath));
        var atlas = xml.firstElement();
        for (sub in atlas.elements()) {
            result.push({
                name: sub.get('name'),
                x:    Std.parseInt(sub.get('x')),
                y:    Std.parseInt(sub.get('y')),
                w:    Std.parseInt(sub.get('width')),
                h:    Std.parseInt(sub.get('height'))
            });
        }
        return result;
    }

    function findFrame(frames:Array<SpriteFrame>, name:String):SpriteFrame
    {
        for (f in frames) if (f.name == name) return f;
        return null;
    }

    function getSplashAnimSets(frames:Array<SpriteFrame>):Array<Int>
    {
        var sets:Array<Int> = [];
        var setMap:Map<Int, Bool> = new Map();
        for (f in frames) {
            var regex = ~/note splash \w+ (\d+)000\d/;
            if (regex.match(f.name)) {
                var setNum = Std.parseInt(regex.matched(1));
                if (!setMap.exists(setNum)) {
                    setMap.set(setNum, true);
                    sets.push(setNum);
                }
            }
        }
        sets.sort(function(a, b) return a - b);
        return sets;
    }

    function makeSprite(f:SpriteFrame, source:BitmapData, scale:Float):FlxSprite
    {
        if (f == null) return null;

        var spr = new FlxSprite();
        var bmd = new BitmapData(f.w, f.h, true, 0x00000000);
        bmd.copyPixels(source, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));
        spr.loadGraphic(FlxGraphic.fromBitmapData(bmd));
        spr.scale.set(scale, scale);
        spr.updateHitbox();
        return spr;
    }

    function getStepperRGB(index:Int):{r:FlxColor, g:FlxColor, b:FlxColor}
    {
        return {
            r: FlxColor.fromRGB(Std.int(rSteppers[index].value), 0, 0),
            g: FlxColor.fromRGB(0, Std.int(gSteppers[index].value), 0),
            b: FlxColor.fromRGB(0, 0, Std.int(bSteppers[index].value))
        };
    }

    function buildLayout()
    {
        var cellW:Float = 120;
        var startX:Float = (FlxG.width - cellW * 4) / 2;
        var startY:Float = 50;
        var rowGap:Float = 100;

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(splashFrames, 'note splash ${col} 20000');
            if (f == null) f = findFrame(splashFrames, 'note splash ${col} 20001');
            var sp = makeSprite(f, splashBitmap, 0.35);
            if (sp == null) {
                splashSprites.push(null);
                splashExportButtons.push(null);
                continue;
            }
            sp.x = startX + i * cellW;
            sp.y = startY;
            add(sp);
            splashSprites.push(sp);

            var lbl = new FlxText(startX + i * cellW, startY - 16, cellW, 'Splash ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(startX + i * cellW + 10, startY + 50, 'Export', function() {
                var animIdx:Int = Std.int(splashAnimTime * 24) % 4;
                var currentF = findFrame(splashFrames, 'note splash ${col} 2000$animIdx');
                if (currentF != null) {
                    exportSingleFrame(currentF, splashBitmap, i, 'splash');
                }
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            splashExportButtons.push(exportBtn);
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var f = findFrame(noteFrames, '${dir} confirm0000');
            if (f == null) f = findFrame(noteFrames, '${dir} confirm0001');
            var sp = makeSprite(f, noteBitmap, 0.35);
            if (sp == null) {
                confirmSprites.push(null);
                confirmExportButtons.push(null);
                continue;
            }
            sp.x = startX + i * cellW;
            sp.y = startY + rowGap;
            add(sp);
            confirmSprites.push(sp);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap - 16, cellW, 'Confirm ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(startX + i * cellW + 10, startY + rowGap + 50, 'Export', function() {
                var animIdx:Int = Std.int(splashAnimTime * 24) % 4;
                var currentF = findFrame(noteFrames, '${dir} confirm000$animIdx');
                if (currentF != null) {
                    exportSingleFrame(currentF, noteBitmap, i, 'confirm');
                }
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            confirmExportButtons.push(exportBtn);
        }

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(noteFrames, '${col}0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                noteSprites.push(null);
                noteExportButtons.push(null);
                continue;
            }

            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 2;
            add(spr);
            noteSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 2 - 16, cellW, '${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(startX + i * cellW + 10, startY + rowGap * 2 + 50, 'Export', function() {
                exportSingleFrame(f, noteBitmap, i, 'note');
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            noteExportButtons.push(exportBtn);
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var f = findFrame(noteFrames, 'arrow${orderDirs[i]}0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                normalStrumSprites.push(null);
                normalStrumExportButtons.push(null);
                continue;
            }

            spr.x = 50 + i * cellW;
            spr.y = startY + rowGap * 3;
            add(spr);
            normalStrumSprites.push(spr);

            var lbl = new FlxText(50 + i * cellW, startY + rowGap * 3 - 16, cellW, 'Normal strum ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(50 + i * cellW + 10, startY + rowGap * 3 + 50, 'Export', function() {
                exportSingleFrame(f, noteBitmap, i, 'normalStrum');
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            normalStrumExportButtons.push(exportBtn);
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var f = findFrame(noteFrames, '${dir} press0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                strumSprites.push(null);
                strumExportButtons.push(null);
                continue;
            }
            spr.x = FlxG.width - 50 - (4 - i) * cellW;
            spr.y = startY + rowGap * 3;
            add(spr);
            strumSprites.push(spr);

            var lbl = new FlxText(FlxG.width - 50 - (4 - i) * cellW, startY + rowGap * 3 - 16, cellW, 'Pressed strum ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(FlxG.width - 50 - (4 - i) * cellW + 10, startY + rowGap * 3 + 50, 'Export', function() {
                var animIdx:Int = Std.int(strumAnimTime * 24) % 4;
                var currentF = findFrame(noteFrames, '${dir} press000$animIdx');
                if (currentF != null) {
                    exportSingleFrame(currentF, noteBitmap, i, 'pressedStrum');
                }
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            strumExportButtons.push(exportBtn);
        }

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(noteFrames, '${col} hold piece0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                sustainSprites.push(null);
                sustainExportButtons.push(null);
                continue;
            }

            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 4;
            add(spr);
            sustainSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 4 - 16, cellW, 'Sustain ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(startX + i * cellW + 10, startY + rowGap * 4 + 50, 'Export', function() {
                exportSingleFrame(f, noteBitmap, i, 'sustain');
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            sustainExportButtons.push(exportBtn);
        }

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(noteFrames, '${col} hold end0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                sustainEndSprites.push(null);
                sustainEndExportButtons.push(null);
                continue;
            }

            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 5;
            add(spr);
            sustainEndSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 5 - 16, cellW, 'End ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var exportBtn = new PsychUIButton(startX + i * cellW + 10, startY + rowGap * 5 + 50, 'Export', function() {
                exportSingleFrame(f, noteBitmap, i, 'sustainEnd');
            });
            exportBtn.resize(80, 20);
            add(exportBtn);
            sustainEndExportButtons.push(exportBtn);

            var defaultColors:Array<FlxColor> = ClientPrefs.data.arrowRGB[i];
            if (PlayState.instance != null && PlayState.isPixelStage) defaultColors = ClientPrefs.data.arrowRGBPixel[i];

            var baseY:Float = startY + rowGap * 5 + 55;
            var stepX:Float = startX + i * cellW + 5;

            var rStep = new PsychUINumericStepper(stepX, baseY, 1, defaultColors[0].red, 0, 255, 0);
            var gStep = new PsychUINumericStepper(stepX, baseY + 22, 1, defaultColors[1].green, 0, 255, 0);
            var bStep = new PsychUINumericStepper(stepX, baseY + 44, 1, defaultColors[2].blue, 0, 255, 0);
            rStep.name = 'r$i'; gStep.name = 'g$i'; bStep.name = 'b$i';
            rStep.onChange = refreshUI;
            gStep.onChange = refreshUI;
            bStep.onChange = refreshUI;
            add(rStep); add(gStep); add(bStep);

            rSteppers.push(rStep);
            gSteppers.push(gStep);
            bSteppers.push(bStep);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        splashAnimTime += elapsed;
        var splashIdx:Int = Std.int(splashAnimTime * 24) % 4;
        var confirmIdx:Int = Std.int(splashAnimTime * 24) % 4;

        for (i in 0...4) {
            var col = orderColors[i];
            var name = 'note splash ${col} 2000$splashIdx';
            var f = findFrame(splashFrames, name);
            if (f == null) continue;

            var sp = splashSprites[i];
            if (sp == null || sp.graphic == null) continue;

            sp.graphic.bitmap.fillRect(sp.graphic.bitmap.rect, 0x00000000);
            sp.graphic.bitmap.copyPixels(splashBitmap, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));

            if (!disableNoteRGB) {
                var rgb = getStepperRGB(i);
                applyRGBBlend(sp.graphic.bitmap, rgb.r, rgb.g, rgb.b);
            }
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var name = '${dir} confirm000$confirmIdx';
            var f = findFrame(noteFrames, name);
            if (f == null) continue;

            var sp = confirmSprites[i];
            if (sp == null || sp.graphic == null) continue;

            sp.graphic.bitmap.fillRect(sp.graphic.bitmap.rect, 0x00000000);
            sp.graphic.bitmap.copyPixels(noteBitmap, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));

            if (!disableNoteRGB) {
                var rgb = getStepperRGB(i);
                applyRGBBlend(sp.graphic.bitmap, rgb.r, rgb.g, rgb.b);
            }
        }

        strumAnimTime += elapsed;
        var strumIdx:Int = Std.int(strumAnimTime * 24) % 4;

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var name = '${dir} press000$strumIdx';
            var f = findFrame(noteFrames, name);
            if (f == null) continue;

            var sp = strumSprites[i];
            if (sp == null || sp.graphic == null) continue;

            sp.graphic.bitmap.fillRect(sp.graphic.bitmap.rect, 0x00000000);
            sp.graphic.bitmap.copyPixels(noteBitmap, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));

            if (!disableNoteRGB) {
                var rgb = getStepperRGB(i);
                applyRGBBlend(sp.graphic.bitmap, rgb.r, rgb.g, rgb.b);
            }
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            MusicBeatState.switchState(new MasterEditorMenu());
        }
    }

    function refreshUI(?name:String, ?value:String)
    {
        for (i in 0...4) {
            var rgb = getStepperRGB(i);

            // Note sprites
            if (noteSprites[i] != null && noteSprites[i].graphic != null) {
                var col = orderColors[i];
                var f = findFrame(noteFrames, '${col}0000');
                if (f != null) {
                    noteSprites[i].graphic.bitmap.fillRect(noteSprites[i].graphic.bitmap.rect, 0x00000000);
                    noteSprites[i].graphic.bitmap.copyPixels(noteBitmap, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));
                    if (!disableNoteRGB) {
                        applyRGBBlend(noteSprites[i].graphic.bitmap, rgb.r, rgb.g, rgb.b);
                    }
                }
            }

            // Sustain sprites
            if (sustainSprites[i] != null && sustainSprites[i].graphic != null) {
                var col = orderColors[i];
                var f = findFrame(noteFrames, '${col} hold piece0000');
                if (f != null) {
                    sustainSprites[i].graphic.bitmap.fillRect(sustainSprites[i].graphic.bitmap.rect, 0x00000000);
                    sustainSprites[i].graphic.bitmap.copyPixels(noteBitmap, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));
                    if (!disableNoteRGB) {
                        applyRGBBlend(sustainSprites[i].graphic.bitmap, rgb.r, rgb.g, rgb.b);
                    }
                }
            }

            // Sustain end sprites
            if (sustainEndSprites[i] != null && sustainEndSprites[i].graphic != null) {
                var col = orderColors[i];
                var f = findFrame(noteFrames, '${col} hold end0000');
                if (f != null) {
                    sustainEndSprites[i].graphic.bitmap.fillRect(sustainEndSprites[i].graphic.bitmap.rect, 0x00000000);
                    sustainEndSprites[i].graphic.bitmap.copyPixels(noteBitmap, new Rectangle(f.x, f.y, f.w, f.h), new Point(0, 0));
                    if (!disableNoteRGB) {
                        applyRGBBlend(sustainEndSprites[i].graphic.bitmap, rgb.r, rgb.g, rgb.b);
                    }
                }
            }
        }
    }

    function applyRGBBlend(bitmap:BitmapData, r:FlxColor, g:FlxColor, b:FlxColor, mult:Float = 1.0):Void
    {
        var rv = [r.redFloat, r.greenFloat, r.blueFloat];
        var gv = [g.redFloat, g.greenFloat, g.blueFloat];
        var bv = [b.redFloat, b.greenFloat, b.blueFloat];

        var multClamped:Float = Math.max(0.0, Math.min(1.0, mult));

        for (x in 0...bitmap.width) {
            for (y in 0...bitmap.height) {
                var pixel:Int = bitmap.getPixel32(x, y);
                var alpha:Int = (pixel >> 24) & 0xFF;
                if (alpha == 0 || multClamped == 0.0) continue;

                var origR:Float = ((pixel >> 16) & 0xFF) / 255.0;
                var origG:Float = ((pixel >> 8) & 0xFF) / 255.0;
                var origB:Float = (pixel & 0xFF) / 255.0;

                var newR:Float = Math.min(origR * rv[0] + origG * gv[0] + origB * bv[0], 1.0);
                var newG:Float = Math.min(origR * rv[1] + origG * gv[1] + origB * bv[1], 1.0);
                var newB:Float = Math.min(origR * rv[2] + origG * gv[2] + origB * bv[2], 1.0);

                var finalR:Float = origR * (1.0 - multClamped) + newR * multClamped;
                var finalG:Float = origG * (1.0 - multClamped) + newG * multClamped;
                var finalB:Float = origB * (1.0 - multClamped) + newB * multClamped;

                var red:Int = Std.int(Math.min(finalR, 1.0) * 255);
                var green:Int = Std.int(Math.min(finalG, 1.0) * 255);
                var blue:Int = Std.int(Math.min(finalB, 1.0) * 255);

                bitmap.setPixel32(x, y, (alpha << 24) | (red << 16) | (green << 8) | blue);
            }
        }
    }

    function exportSingleFrame(frame:SpriteFrame, bitmap:BitmapData, colorIndex:Int, source:String)
    {
        var bmd = new BitmapData(frame.w, frame.h, true, 0x00000000);
        bmd.copyPixels(bitmap, new Rectangle(frame.x, frame.y, frame.w, frame.h), new Point(0, 0));

        if (!disableNoteRGB && colorIndex >= 0) {
            var rgb = getStepperRGB(colorIndex);
            applyRGBBlend(bmd, rgb.r, rgb.g, rgb.b);
        }

        var fileName = '${frame.name}_RGB.png';
        _file = new FileReference();
        _file.addEventListener(Event.COMPLETE, function(_) {
            _file.removeEventListener(Event.COMPLETE, function(_) {});
        });
        _file.save(bmd.encode(bmd.rect, new PNGEncoderOptions()), fileName);
    }

    function saveBoth(bitmap:BitmapData, xml:String, baseName:String)
    {
        var pngData = bitmap.encode(bitmap.rect, new PNGEncoderOptions());

        #if sys
        try {
            sys.io.File.saveBytes(baseName + '.png', pngData);
            sys.io.File.saveContent(baseName + '.xml', xml);
            trace('Saved ' + baseName + '.png and ' + baseName + '.xml');
        } catch (e:Dynamic) { trace(e); }
        #else
        _file = new FileReference();
        _file.save(pngData, baseName + '.png');
        #end
    }

    override function destroy()
    {
        FlxG.sound.music.volume = 1;
        FlxG.sound.muteKeys = [FlxKey.ZERO];
        FlxG.sound.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
        FlxG.sound.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
        super.destroy();
    }
}