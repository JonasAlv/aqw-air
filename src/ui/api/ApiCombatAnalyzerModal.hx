package ui.api;

import com.aqwapi.Api;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;

class ApiCombatAnalyzerModal extends Sprite {
    private static var _instance:ApiCombatAnalyzerModal;
    private static var _meter:Sprite;
    private static var _meterText:TextField;
    private static var _trackedTarget:String;
    private static var _lastHp:Int = -1;
    private static var _damage:Int = 0;
    private static var _startedAt:Int = 0;

    private var pocket:Dynamic;
    private var targetText:TextField;
    private var statsText:TextField;
    private var frameCount:Int = 0;

    public static function show(pocket:Dynamic):Void {
        close();
        var stage = getStage(pocket);
        if (stage == null) {
            ApiNotificationManager.notify("Battle Analyzer needs the game stage to be available.");
            return;
        }

        _instance = new ApiCombatAnalyzerModal(pocket, stage.stageWidth, stage.stageHeight);
        stage.addChild(_instance);
    }

    public static function close():Void {
        if (_instance != null) {
            _instance.removeEventListener(Event.ENTER_FRAME, _instance.onEnterFrame);
            if (_instance.parent != null) _instance.parent.removeChild(_instance);
            _instance = null;
        }
    }

    public static function toggleMeter(pocket:Dynamic):Void {
        if (_meter != null && _meter.visible) {
            _meter.visible = false;
            return;
        }

        var stage = getStage(pocket);
        if (stage == null) {
            ApiNotificationManager.notify("Battle Analyzer needs the game stage to be available.");
            return;
        }
        if (_meter == null) {
            _meter = new Sprite();
            _meter.graphics.beginFill(0x151515, 0.92);
            _meter.graphics.lineStyle(1, 0xFFCC00, 0.9);
            _meter.graphics.drawRoundRect(0, 0, 170, 42, 8, 8);
            _meter.graphics.endFill();
            _meterText = makeTextField(156, 34, 10, 0xFFFFFF, true);
            _meterText.x = 7;
            _meterText.y = 4;
            _meter.addChild(_meterText);
            _meter.addEventListener(Event.ENTER_FRAME, updateMeter);
            _meter.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
                e.stopPropagation();
                _meter.visible = false;
            });
        } else if (_meter.parent != stage) {
            if (_meter.parent != null) _meter.parent.removeChild(_meter);
        }
        if (_meter.parent == null) stage.addChild(_meter);
        _meter.x = Math.max(0, stage.stageWidth - _meter.width - 12);
        _meter.y = 12;
        _meter.visible = true;
        updateMeter(null);
    }

    private static function updateMeter(e:Event):Void {
        if (_meterText == null || _meter == null || !_meter.visible) return;
        _meterText.text = sampleText(Api.game);
    }

    private function new(pocket:Dynamic, stageWidth:Float, stageHeight:Float) {
        super();
        this.pocket = pocket;
        graphics.beginFill(0x111111, 0.97);
        graphics.lineStyle(2, 0xFFCC00, 1);
        graphics.drawRoundRect(0, 0, 320, 158, 12, 12);
        graphics.endFill();
        x = Math.max(8, (stageWidth - 320) / 2);
        y = Math.max(8, (stageHeight - 158) / 2);

        var title = makeTextField(260, 24, 15, 0xFFCC00, true);
        title.text = "BATTLE ANALYZER";
        title.x = 16;
        title.y = 12;
        addChild(title);

        var closeButton = new Sprite();
        closeButton.graphics.beginFill(0x333333, 1);
        closeButton.graphics.lineStyle(1, 0x777777, 1);
        closeButton.graphics.drawRoundRect(0, 0, 28, 26, 5, 5);
        closeButton.graphics.endFill();
        closeButton.graphics.lineStyle(2, 0xFFFFFF, 1);
        closeButton.graphics.moveTo(8, 7);
        closeButton.graphics.lineTo(20, 19);
        closeButton.graphics.moveTo(20, 7);
        closeButton.graphics.lineTo(8, 19);
        closeButton.x = 278;
        closeButton.y = 10;
        closeButton.buttonMode = true;
        closeButton.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            e.stopPropagation();
            close();
        });
        addChild(closeButton);

        targetText = makeTextField(288, 28, 11, 0xFFFFFF, true);
        targetText.x = 16;
        targetText.y = 54;
        addChild(targetText);

        statsText = makeTextField(288, 52, 10, 0xCCCCCC, false);
        statsText.x = 16;
        statsText.y = 88;
        statsText.text = "Damage and DPS are estimated from target HP loss.";
        addChild(statsText);

        mouseChildren = true;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        refresh();
    }

    private function onEnterFrame(e:Event):Void {
        frameCount++;
        if (frameCount < 12) return;
        frameCount = 0;
        refresh();
    }

    private function refresh():Void {
        var info:Dynamic = getTargetInfo(pocket);
        if (info == null) {
            resetTarget();
            targetText.text = "Target: none";
            statsText.text = "Select a monster to begin tracking.\nDamage estimates use target HP loss from all sources.";
            return;
        }
        updateTarget(info);
        targetText.text = "Target: " + info.name + "  (" + info.hp + " / " + info.maxHp + " HP)";
        statsText.text = "Target HP lost: " + _damage + "\nEstimated DPS: " + currentDps() + "\nIncludes damage from all players.";
    }

    private static function sampleText(pocket:Dynamic):String {
        var info:Dynamic = getTargetInfo(pocket);
        if (info == null) {
            resetTarget();
            return "DPS METER\nNo target";
        }
        updateTarget(info);
        return "DPS " + currentDps() + "  |  DMG " + _damage + "\n" + info.name;
    }

    private static function updateTarget(info:Dynamic):Void {
        if (_trackedTarget != info.key) {
            _trackedTarget = info.key;
            _lastHp = info.hp;
            _damage = 0;
            _startedAt = flash.Lib.getTimer();
            return;
        }
        if (_lastHp >= 0 && info.hp < _lastHp) {
            _damage += Std.int(_lastHp - info.hp);
        }
        _lastHp = info.hp;
    }

    private static function resetTarget():Void {
        _trackedTarget = null;
        _lastHp = -1;
        _damage = 0;
        _startedAt = flash.Lib.getTimer();
    }

    private static function currentDps():Int {
        var elapsedMs:Int = flash.Lib.getTimer() - _startedAt;
        if (elapsedMs <= 0) return 0;
        return Std.int(Math.round(_damage * 1000 / elapsedMs));
    }

    private static function getTargetInfo(pocket:Dynamic):Dynamic {
        var game:Dynamic = (pocket != null && pocket.game != null) ? pocket.game : Api.game;
        if (game == null || game.world == null || game.world.myAvatar == null) return null;
        var target:Dynamic = game.world.myAvatar.target;
        if (target == null) return null;

        var dataLeaf:Dynamic = Reflect.field(target, "dataLeaf");
        var objData:Dynamic = Reflect.field(target, "objData");
        var hpValue:Dynamic = (dataLeaf != null) ? Reflect.field(dataLeaf, "intHP") : null;
        if (hpValue == null && objData != null) hpValue = Reflect.field(objData, "intHP");
        if (hpValue == null) hpValue = Reflect.field(target, "intHP");
        if (hpValue == null) return null;

        var maxHpValue:Dynamic = (dataLeaf != null) ? Reflect.field(dataLeaf, "intHPMax") : null;
        if (maxHpValue == null && objData != null) maxHpValue = Reflect.field(objData, "intHPMax");
        if (maxHpValue == null) maxHpValue = Reflect.field(target, "intHPMax");

        var nameValue:Dynamic = (objData != null) ? Reflect.field(objData, "strMonName") : null;
        if (nameValue == null && objData != null) nameValue = Reflect.field(objData, "strUsername");
        if (nameValue == null) nameValue = Reflect.field(target, "pnm");
        var keyValue:Dynamic = Reflect.field(target, "uid");
        if (keyValue == null && dataLeaf != null) keyValue = Reflect.field(dataLeaf, "MonMapID");
        if (keyValue == null) keyValue = nameValue;

        var targetName:String = (nameValue != null) ? Std.string(nameValue) : "Unknown";
        var targetKey:String = (keyValue != null) ? Std.string(keyValue) : targetName;
        return {
            name: targetName,
            key: targetKey,
            hp: Std.int(hpValue),
            maxHp: (maxHpValue != null) ? Std.int(maxHpValue) : Std.int(hpValue)
        };
    }

    private static function getStage(pocket:Dynamic):flash.display.Stage {
        if (pocket != null && pocket.game != null && pocket.game.stage != null) return pocket.game.stage;
        if (pocket != null && pocket.stage != null) return pocket.stage;
        if (Api.game != null && Api.game.stage != null) return Api.game.stage;
        return null;
    }

    private static function makeTextField(width:Float, height:Float, size:Int, color:Int, bold:Bool):TextField {
        var field = new TextField();
        field.defaultTextFormat = new TextFormat("_sans", size, color, bold);
        field.width = width;
        field.height = height;
        field.selectable = false;
        field.mouseEnabled = false;
        return field;
    }
}
