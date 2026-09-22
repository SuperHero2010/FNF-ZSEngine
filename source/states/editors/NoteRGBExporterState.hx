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
    var exportNoteButton:PsychUIButton;
    var exportSplashButton:PsychUIButton;
    var disableRGBCheckbox:PsychUICheckBox;
    var disableNoteRGB:Bool = false;

    var splashSprites:Array<FlxSprite> = [];
    var confirmSprites:Array<FlxSprite> = [];
    var noteSprites:Array<FlxSprite> = [];
    var strumSprites:Array<FlxSprite> = [];
    var sustainSprites:Array<FlxSprite> = [];
    var sustainEndSprites:Array<FlxSprite> = [];
    var splashAnimTime:Float = 0;

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

        exportNoteButton = new PsychUIButton(FlxG.width / 2 - 250, FlxG.height - 50, 'Export Note Spritesheet', function() {
            exportNoteSpritesheet();
        });
        exportNoteButton.resize(230, 40);
        exportNoteButton.normalStyle.bgColor = FlxColor.GREEN;
        add(exportNoteButton);

        exportSplashButton = new PsychUIButton(FlxG.width / 2 + 20, FlxG.height - 50, 'Export Splash Spritesheet', function() {
            exportSplashSpritesheet();
        });
        exportSplashButton.resize(230, 40);
        exportSplashButton.normalStyle.bgColor = FlxColor.BLUE;
        add(exportSplashButton);

        disableRGBCheckbox = new PsychUICheckBox(FlxG.width - 220, FlxG.height - 50, 'Disable Note RGB', 150, function() {
            disableNoteRGB = disableRGBCheckbox.checked;
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
                continue;
            }
            sp.x = startX + i * cellW;
            sp.y = startY;
            add(sp);
            splashSprites.push(sp);

            var lbl = new FlxText(startX + i * cellW, startY - 16, cellW, 'Splash ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var f = findFrame(noteFrames, '${dir} confirm0000');
            if (f == null) f = findFrame(noteFrames, '${dir} confirm0001');
            var sp = makeSprite(f, noteBitmap, 0.35);
            if (sp == null) {
                confirmSprites.push(null);
                continue;
            }
            sp.x = startX + i * cellW;
            sp.y = startY + rowGap;
            add(sp);
            confirmSprites.push(sp);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap - 16, cellW, 'Confirm ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);
        }

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(noteFrames, '${col}0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                noteSprites.push(null);
                continue;
            }

            var tempNote = new Note(0, i);
            Note.initializeGlobalRGBShader(i);
            tempNote.defaultRGB();
            if (tempNote.rgbShader != null && tempNote.rgbShader.parent != null && !disableNoteRGB) {
                spr.shader = tempNote.rgbShader.parent.shader;
            }

            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 2;
            add(spr);
            noteSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 2 - 16, cellW, '${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var f = findFrame(noteFrames, '${dir} press0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                strumSprites.push(null);
                continue;
            }
            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 3;
            add(spr);
            strumSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 3 - 16, cellW, 'Strum ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);
        }

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(noteFrames, '${col} hold piece0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                sustainSprites.push(null);
                continue;
            }

            var tempNote = new Note(0, i);
            Note.initializeGlobalRGBShader(i);
            tempNote.defaultRGB();
            if (tempNote.rgbShader != null && tempNote.rgbShader.parent != null && !disableNoteRGB) {
                spr.shader = tempNote.rgbShader.parent.shader;
            }

            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 4;
            add(spr);
            sustainSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 4 - 16, cellW, 'Sustain ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);
        }

        for (i in 0...4) {
            var col = orderColors[i];
            var f = findFrame(noteFrames, '${col} hold end0000');
            var spr = makeSprite(f, noteBitmap, 0.35);
            if (spr == null) {
                sustainEndSprites.push(null);
                continue;
            }

            var tempNote = new Note(0, i);
            Note.initializeGlobalRGBShader(i);
            tempNote.defaultRGB();
            if (tempNote.rgbShader != null && tempNote.rgbShader.parent != null && !disableNoteRGB) {
                spr.shader = tempNote.rgbShader.parent.shader;
            }

            spr.x = startX + i * cellW;
            spr.y = startY + rowGap * 5;
            add(spr);
            sustainEndSprites.push(spr);

            var lbl = new FlxText(startX + i * cellW, startY + rowGap * 5 - 16, cellW, 'End ${orderDirs[i]}', 11);
            lbl.color = FlxColor.WHITE;
            add(lbl);

            var defaultColors:Array<FlxColor> = ClientPrefs.data.arrowRGB[i];
            if (PlayState.instance != null && PlayState.isPixelStage) defaultColors = ClientPrefs.data.arrowRGBPixel[i];

            var baseY:Float = startY + rowGap * 5 + 55;
            var stepX:Float = startX + i * cellW + 5;

            var rStep = new PsychUINumericStepper(stepX, baseY, 1, defaultColors[0].red, 0, 255, 0, 45);
            var gStep = new PsychUINumericStepper(stepX, baseY + 22, 1, defaultColors[1].green, 0, 255, 0, 45);
            var bStep = new PsychUINumericStepper(stepX, baseY + 44, 1, defaultColors[2].blue, 0, 255, 0, 45);
            rStep.name = 'r$i'; gStep.name = 'g$i'; bStep.name = 'b$i';
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
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            MusicBeatState.switchState(new MasterEditorMenu());
        }
    }

    function applyRGBBlend(bitmap:BitmapData, r:FlxColor, g:FlxColor, b:FlxColor):Void
    {
        var rVec = [r.redFloat, r.greenFloat, r.blueFloat];
        var gVec = [g.redFloat, g.greenFloat, g.blueFloat];
        var bVec = [b.redFloat, b.greenFloat, b.blueFloat];

        for (x in 0...bitmap.width) {
            for (y in 0...bitmap.height) {
                var pixel:Int = bitmap.getPixel32(x, y);
                var alpha:Int = (pixel >> 24) & 0xFF;
                if (alpha == 0) continue;

                var origR:Float = ((pixel >> 16) & 0xFF) / 255.0;
                var origG:Float = ((pixel >> 8) & 0xFF) / 255.0;
                var origB:Float = (pixel & 0xFF) / 255.0;

                var newR:Float = Math.min(origR * rVec[0] + origG * rVec[1] + origB * rVec[2], 1.0);
                var newG:Float = Math.min(origR * gVec[0] + origG * gVec[1] + origB * gVec[2], 1.0);
                var newB:Float = Math.min(origR * bVec[0] + origG * bVec[1] + origB * bVec[2], 1.0);

                var red:Int = Std.int(newR * 255);
                var green:Int = Std.int(newG * 255);
                var blue:Int = Std.int(newB * 255);

                bitmap.setPixel32(x, y, (alpha << 24) | (red << 16) | (green << 8) | blue);
            }
        }
    }

    function exportNoteSpritesheet()
    {
        var packed:Array<{frame:SpriteFrame, rgb:{r:FlxColor, g:FlxColor, b:FlxColor}, source:String, colorIndex:Int}> = [];

        for (i in 0...4) {
            var col = orderColors[i];
            var rgb = getStepperRGB(i);

            var arrow = findFrame(noteFrames, '${col}0000');
            if (arrow != null) packed.push({frame: arrow, rgb: rgb, source: 'note', colorIndex: i});

            var piece = findFrame(noteFrames, '${col} hold piece0000');
            if (piece != null) packed.push({frame: piece, rgb: rgb, source: 'note', colorIndex: i});

            var end = findFrame(noteFrames, '${col} hold end0000');
            if (end != null) packed.push({frame: end, rgb: rgb, source: 'note', colorIndex: i});
        }

        for (i in 0...4) {
            var dir = orderDirLower[i];
            var strum = findFrame(noteFrames, '${dir} press0000');
            if (strum != null) packed.push({frame: strum, rgb: null, source: 'note', colorIndex: -1});
        }

        var maxW:Int = 0;
        var maxH:Int = 0;
        for (p in packed) {
            if (p.frame.w > maxW) maxW = p.frame.w;
            if (p.frame.h > maxH) maxH = p.frame.h;
        }
        var cols:Int = 4;
        var rows:Int = Std.int(Math.ceil(packed.length / cols));
        var totalW:Int = maxW * cols;
        var totalH:Int = maxH * rows;

        var out = new BitmapData(totalW, totalH, true, 0x00000000);
        var xmlEntries:Array<String> = [];

        for (idx in 0...packed.length) {
            var p = packed[idx];
            var col = idx % cols;
            var row = Std.int(idx / cols);
            var px = col * maxW;
            var py = row * maxH;

            var bmd = new BitmapData(p.frame.w, p.frame.h, true, 0x00000000);
            bmd.copyPixels(noteBitmap, new Rectangle(p.frame.x, p.frame.y, p.frame.w, p.frame.h), new Point(0, 0));

            if (!disableNoteRGB && p.colorIndex >= 0 && p.rgb != null) {
                applyRGBBlend(bmd, p.rgb.r, p.rgb.g, p.rgb.b);
            }

            out.copyPixels(bmd, bmd.rect, new Point(px, py));

            xmlEntries.push('  <SubTexture name="${p.frame.name}" x="$px" y="$py" width="${p.frame.w}" height="${p.frame.h}"/>');
        }

        var xml:String = '<?xml version="1.0" encoding="utf-8"?>\n';
        xml += '<TextureAtlas imagePath="noteRGB.png">\n';
        for (e in xmlEntries) xml += e + '\n';
        xml += '</TextureAtlas>';

        saveBoth(out, xml, 'noteRGB');
    }

    function exportSplashSpritesheet()
    {
        var packed:Array<{frame:SpriteFrame, rgb:{r:FlxColor, g:FlxColor, b:FlxColor}}> = [];

        for (i in 0...4) {
            var col = orderColors[i];
            var rgb = getStepperRGB(i);

            for (frameIdx in 0...4) {
                var f = findFrame(splashFrames, 'note splash ${col} 2000$frameIdx');
                if (f == null) continue;
                packed.push({frame: f, rgb: rgb});
            }
        }

        var maxW:Int = 0;
        var maxH:Int = 0;
        for (p in packed) {
            if (p.frame.w > maxW) maxW = p.frame.w;
            if (p.frame.h > maxH) maxH = p.frame.h;
        }

        var cols:Int = 4;
        var rows:Int = Std.int(Math.ceil(packed.length / cols));
        var totalW:Int = maxW * cols;
        var totalH:Int = maxH * rows;

        var out = new BitmapData(totalW, totalH, true, 0x00000000);
        var xmlEntries:Array<String> = [];

        for (idx in 0...packed.length) {
            var p = packed[idx];
            var col = idx % cols;
            var row = Std.int(idx / cols);
            var px = col * maxW;
            var py = row * maxH;

            var bmd = new BitmapData(p.frame.w, p.frame.h, true, 0x00000000);
            bmd.copyPixels(splashBitmap, new Rectangle(p.frame.x, p.frame.y, p.frame.w, p.frame.h), new Point(0, 0));

            if (!disableNoteRGB) {
                applyRGBBlend(bmd, p.rgb.r, p.rgb.g, p.rgb.b);
            }

            out.copyPixels(bmd, bmd.rect, new Point(px, py));

            xmlEntries.push('  <SubTexture name="${p.frame.name}" x="$px" y="$py" width="${p.frame.w}" height="${p.frame.h}"/>');
        }

        var xml:String = '<?xml version="1.0" encoding="utf-8"?>\n';
        xml += '<TextureAtlas imagePath="splashRGB.png">\n';
        for (e in xmlEntries) xml += e + '\n';
        xml += '</TextureAtlas>';

        saveBoth(out, xml, 'splashRGB');
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