package ui.shortcut;

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import util.Helper;

/**
 * Modern Shortcut Action Definition
 */
class ShortcutActionItem {
    public var name:String;
    public var category:String; // "Combat", "Storage", "Movement", "Interface"
    public var description:String;

    public function new(name:String, category:String, description:String) {
        this.name = name;
        this.category = category;
        this.description = description;
    }
}

/**
 * Modern On-Screen Shortcut Picker created from scratch.
 * Features categorized tabs, instant search filtering, status indicators,
 * and mouse-wheel scrolling with zero reliance on missing Flash FLA symbols.
 */
class ShortcutPicker extends Sprite {
    public static var ACTIONS:Array<ShortcutActionItem> = [
        // COMBAT
        new ShortcutActionItem("Auto Attack", "Combat", "Attack / Approach nearest target"),
        new ShortcutActionItem("Skill 2", "Combat", "Cast class skill 2"),
        new ShortcutActionItem("Skill 3", "Combat", "Cast class skill 3"),
        new ShortcutActionItem("Skill 4", "Combat", "Cast class skill 4"),
        new ShortcutActionItem("Skill 5", "Combat", "Cast class skill 5"),
        new ShortcutActionItem("Skill 6", "Combat", "Use potion or consumable"),
        new ShortcutActionItem("Target Random Monster", "Combat", "Target nearest monster"),
        new ShortcutActionItem("Cancel Target", "Combat", "Deselect active target"),
        new ShortcutActionItem("Battle Analyzer", "Combat", "Open combat DPS analyzer"),
        new ShortcutActionItem("Battle Analyzer Toggle", "Combat", "Toggle floating DPS meter"),

        // STORAGE
        new ShortcutActionItem("Bank", "Storage", "Toggle bank storage panel"),
        new ShortcutActionItem("Inventory", "Storage", "Open player inventory"),
        new ShortcutActionItem("Outfits", "Storage", "Open saved equipment outfits"),
        new ShortcutActionItem("Custom Drops UI", "Storage", "Open custom item drops screen"),
        new ShortcutActionItem("Decline All Drops", "Storage", "Decline all current drop items"),

        // MOVEMENT
        new ShortcutActionItem("Rest", "Movement", "Rest to regenerate HP & MP"),
        new ShortcutActionItem("Jump", "Movement", "Jump to pad in current room"),
        new ShortcutActionItem("Dash", "Movement", "Perform dodge / dash roll"),
        new ShortcutActionItem("Area List", "Movement", "Open room / cell navigator"),
        new ShortcutActionItem("Toggle World", "Movement", "Toggle world map view"),

        // INTERFACE
        new ShortcutActionItem("Character Panel", "Interface", "View stats and character sheet"),
        new ShortcutActionItem("Quest Log", "Interface", "Open active quest log"),
        new ShortcutActionItem("Player HP Bar", "Interface", "Toggle player frame display"),
        new ShortcutActionItem("Friends List", "Interface", "Open friends list"),
        new ShortcutActionItem("Friendships UI", "Interface", "Open NPC friendships panel"),
        new ShortcutActionItem("Options", "Interface", "Open game options modal"),
        new ShortcutActionItem("Focus Chat", "Interface", "Focus chat input box"),
        new ShortcutActionItem("Fix Lag", "Interface", "Stop background MovieClips"),
        new ShortcutActionItem("Hide Monsters", "Interface", "Toggle monster visibility"),
        new ShortcutActionItem("Hide Players", "Interface", "Toggle player visibility"),
        new ShortcutActionItem("Hide UI", "Interface", "Toggle game HUD visibility"),
        new ShortcutActionItem("Toggle Joystick", "Interface", "Toggle virtual walk joystick"),
        new ShortcutActionItem("Toggle Skills", "Interface", "Toggle AQW skill action bar"),
        new ShortcutActionItem("Toggle Shortcuts", "Interface", "Toggle all shortcut buttons")
    ];

    private static var TAB_DEFS:Array<{id:String, label:String, w:Float}> = [
        { id: "ALL",       label: "ALL ACTIONS", w: 104.0 },
        { id: "Combat",    label: "COMBAT",      w: 84.0 },
        { id: "Storage",   label: "STORAGE",     w: 88.0 },
        { id: "Movement",  label: "MOVEMENT",    w: 94.0 },
        { id: "Interface", label: "INTERFACE",   w: 98.0 }
    ];

    private var pocket:Dynamic;
    private var onPick:String->Void;

    private var win:Sprite;
    private var searchInput:TextField;
    private var listContainer:Sprite;
    private var listMask:Shape;

    private var selectedCategory:String = "ALL";
    private var searchQuery:String = "";

    private static inline var WIN_W:Float = 550;
    private static inline var WIN_H:Float = 430;
    private static inline var LIST_X:Float = 18;
    private static inline var LIST_Y:Float = 125;
    private static inline var LIST_W:Float = 496;
    private static inline var LIST_H:Float = 285;

    public function new(pocket:Dynamic, onPick:String->Void) {
        super();
        this.pocket = pocket;
        this.onPick = onPick;
        this.name = "ShortcutPicker";

        addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }

    private function onAdded(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        buildUI();
    }

    private function buildUI():Void {
        var stageW:Float = (stage != null && stage.stageWidth > 0) ? stage.stageWidth : 960;
        var stageH:Float = (stage != null && stage.stageHeight > 0) ? stage.stageHeight : 550;

        // 1. Semi-transparent backdrop
        var backdrop = new Sprite();
        backdrop.graphics.beginFill(0x000000, 0.72);
        backdrop.graphics.drawRect(0, 0, stageW, stageH);
        backdrop.graphics.endFill();
        backdrop.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            if (e.target == backdrop) onDismiss();
        });
        addChild(backdrop);

        // 2. Main Window
        win = new Sprite();
        win.graphics.beginFill(0x131313, 0.98);
        win.graphics.lineStyle(2, 0xFFCC00, 0.95);
        win.graphics.drawRoundRect(0, 0, WIN_W, WIN_H, 12, 12);
        win.graphics.endFill();

        // Inner header line
        win.graphics.lineStyle(1, 0x333333, 0.8);
        win.graphics.moveTo(0, 48);
        win.graphics.lineTo(WIN_W, 48);

        win.x = (stageW - WIN_W) / 2;
        win.y = (stageH - WIN_H) / 2;
        addChild(win);

        // 3. Header Title
        var title = new TextField();
        title.defaultTextFormat = new TextFormat("_sans", 13, 0xFFCC00, true);
        title.text = "ADD ON-SCREEN SHORTCUT";
        title.autoSize = TextFieldAutoSize.LEFT;
        title.x = 18;
        title.y = 10;
        title.selectable = false;
        title.mouseEnabled = false;
        win.addChild(title);

        var subTitle = new TextField();
        subTitle.defaultTextFormat = new TextFormat("_sans", 9, 0x888888, false);
        subTitle.text = "Tap any action to place a touch shortcut button onto your HUD";
        subTitle.autoSize = TextFieldAutoSize.LEFT;
        subTitle.x = 18;
        subTitle.y = 28;
        subTitle.selectable = false;
        subTitle.mouseEnabled = false;
        win.addChild(subTitle);

        // 4. Close Button (Pure vector X — zero fonts, zero missing glyphs)
        var closeBtn = new Sprite();
        closeBtn.x = WIN_W - 38;
        closeBtn.y = 10;
        closeBtn.buttonMode = true;
        closeBtn.useHandCursor = true;

        var drawClose = function(hovered:Bool):Void {
            closeBtn.graphics.clear();
            closeBtn.graphics.beginFill(hovered ? 0xDC3545 : 0x222222, 0.95);
            closeBtn.graphics.lineStyle(1.5, hovered ? 0xFFFFFF : 0x444444);
            closeBtn.graphics.drawRoundRect(0, 0, 28, 28, 6, 6);
            closeBtn.graphics.endFill();

            // Vector X
            closeBtn.graphics.lineStyle(2, hovered ? 0xFFFFFF : 0xCCCCCC, 1.0);
            closeBtn.graphics.moveTo(9, 9);
            closeBtn.graphics.lineTo(19, 19);
            closeBtn.graphics.moveTo(19, 9);
            closeBtn.graphics.lineTo(9, 19);
        };
        drawClose(false);

        closeBtn.addEventListener(MouseEvent.ROLL_OVER, function(_):Void drawClose(true));
        closeBtn.addEventListener(MouseEvent.ROLL_OUT, function(_):Void drawClose(false));
        closeBtn.addEventListener(MouseEvent.CLICK, function(_):Void onDismiss());
        win.addChild(closeBtn);

        // 5. Category Tabs with Fixed Widths (No shrinking or text clipping)
        var tabX:Float = 18;
        var tabH:Float = 26;
        for (tDef in TAB_DEFS) {
            var tabBtn = makeCategoryTab(tDef.id, tDef.label, tDef.w, tabH);
            tabBtn.x = tabX;
            tabBtn.y = 55;
            win.addChild(tabBtn);
            tabX += tDef.w + 8;
        }

        // 6. Search Bar
        var searchBg = new Sprite();
        searchBg.graphics.beginFill(0x1E1E1E, 0.9);
        searchBg.graphics.lineStyle(1, 0x444444);
        searchBg.graphics.drawRoundRect(0, 0, WIN_W - 36, 26, 6, 6);
        searchBg.graphics.endFill();
        searchBg.x = 18;
        searchBg.y = 90;
        win.addChild(searchBg);

        // Vector Magnifying Glass (zero font symbols)
        var searchIcon = new Shape();
        searchIcon.graphics.lineStyle(1.6, 0x888888, 0.9);
        searchIcon.graphics.drawCircle(32, 103, 4);
        searchIcon.graphics.moveTo(35, 106);
        searchIcon.graphics.lineTo(39, 110);
        win.addChild(searchIcon);

        searchInput = new TextField();
        searchInput.type = TextFieldType.INPUT;
        searchInput.defaultTextFormat = new TextFormat("_sans", 11, 0xFFFFFF);
        searchInput.text = "";
        searchInput.width = WIN_W - 80;
        searchInput.height = 20;
        searchInput.x = 46;
        searchInput.y = 94;
        searchInput.addEventListener(Event.CHANGE, function(_):Void {
            searchQuery = StringTools.trim(searchInput.text).toLowerCase();
            refreshList();
        });
        win.addChild(searchInput);

        // 7. Scrollable List Container & Mask
        listContainer = new Sprite();
        listContainer.x = LIST_X;
        listContainer.y = LIST_Y;
        win.addChild(listContainer);

        listMask = new Shape();
        listMask.graphics.beginFill(0xFFFFFF);
        listMask.graphics.drawRect(0, 0, LIST_W, LIST_H);
        listMask.graphics.endFill();
        listMask.x = LIST_X;
        listMask.y = LIST_Y;
        win.addChild(listMask);
        listContainer.mask = listMask;

        // 8. Mouse Wheel Scroll
        win.addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):Void {
            scrollList(e.delta * 22);
        });

        refreshList();
    }

    private function makeCategoryTab(cat:String, label:String, tabW:Float, tabH:Float):Sprite {
        var sp = new Sprite();
        sp.name = "tab_" + cat;
        sp.buttonMode = true;
        sp.useHandCursor = true;
        sp.mouseChildren = false;

        var isSelected = (selectedCategory == cat);

        var txt = new TextField();
        var tf = new TextFormat("_sans", 10, isSelected ? 0x000000 : 0xAAAAAA, true);
        tf.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = tf;
        txt.text = label;
        txt.autoSize = TextFieldAutoSize.NONE;
        txt.width = tabW;
        txt.height = tabH;
        txt.x = 0;
        txt.y = 5;
        txt.selectable = false;
        txt.mouseEnabled = false;

        drawTabGraphics(sp, tabW, tabH, isSelected);
        sp.addChild(txt);

        sp.addEventListener(MouseEvent.CLICK, function(_):Void {
            selectedCategory = cat;
            for (tDef in TAB_DEFS) {
                var otherTab:Sprite = cast win.getChildByName("tab_" + tDef.id);
                if (otherTab != null) {
                    var otherSelected = (tDef.id == selectedCategory);
                    drawTabGraphics(otherTab, tDef.w, tabH, otherSelected);
                    var otherTxt:TextField = cast otherTab.getChildAt(0);
                    if (otherTxt != null) {
                        var otf = new TextFormat("_sans", 10, otherSelected ? 0x000000 : 0xAAAAAA, true);
                        otf.align = TextFormatAlign.CENTER;
                        otherTxt.defaultTextFormat = otf;
                        otherTxt.setTextFormat(otf);
                    }
                }
            }
            refreshList();
        });

        return sp;
    }

    private function drawTabGraphics(tab:Sprite, w:Float, h:Float, isSelected:Bool):Void {
        tab.graphics.clear();
        tab.graphics.beginFill(isSelected ? 0xFFCC00 : 0x242424, 0.95);
        tab.graphics.lineStyle(1, isSelected ? 0xFFDD00 : 0x404040);
        tab.graphics.drawRoundRect(0, 0, w, h, 6, 6);
        tab.graphics.endFill();
    }

    private function refreshList():Void {
        while (listContainer.numChildren > 0) {
            listContainer.removeChildAt(0);
        }
        listContainer.y = LIST_Y;

        var filtered = ACTIONS.filter(function(item) {
            if (selectedCategory != "ALL" && item.category != selectedCategory) return false;
            if (searchQuery.length > 0) {
                var matchName = item.name.toLowerCase().indexOf(searchQuery) != -1;
                var matchDesc = item.description.toLowerCase().indexOf(searchQuery) != -1;
                return matchName || matchDesc;
            }
            return true;
        });

        var CARD_W:Float = (LIST_W - 10) / 2;
        var CARD_H:Float = 42;
        var GAP:Float = 8;

        for (i in 0...filtered.length) {
            var item = filtered[i];
            var col = i % 2;
            var row = Std.int(i / 2);

            var card = makeActionCard(item, CARD_W, CARD_H);
            card.x = col * (CARD_W + GAP);
            card.y = row * (CARD_H + GAP);
            listContainer.addChild(card);
        }
    }

    private function makeActionCard(item:ShortcutActionItem, w:Float, h:Float):Sprite {
        var card = new Sprite();
        card.buttonMode = true;
        card.useHandCursor = true;

        var isPlaced = false;
        if (pocket != null && pocket.gameUI != null && pocket.gameUI.shortcutButtons != null) {
            isPlaced = Reflect.field(pocket.gameUI.shortcutButtons, item.name) != null;
        }

        var catColor = getCategoryColor(item.category);

        var drawCard = function(isHover:Bool):Void {
            card.graphics.clear();

            var fill = isPlaced ? 0x1A1A1A : (isHover ? 0x2A2A2A : 0x1E1E1E);
            var border = isPlaced ? 0x333333 : (isHover ? 0xFFCC00 : 0x3A3A3A);

            card.graphics.beginFill(fill, 0.95);
            card.graphics.lineStyle(1.5, border, 0.95);
            card.graphics.drawRoundRect(0, 0, w, h, 6, 6);
            card.graphics.endFill();

            // Left Category Color Pill
            card.graphics.beginFill(isPlaced ? 0x555555 : catColor, 0.9);
            card.graphics.lineStyle(0, 0, 0);
            card.graphics.drawRoundRect(3, 4, 4, h - 8, 2, 2);
            card.graphics.endFill();
        };

        drawCard(false);

        // Action Name
        var nameTxt = new TextField();
        var nTf = new TextFormat("_sans", 11, isPlaced ? 0x777777 : 0xFFFFFF, true);
        nameTxt.defaultTextFormat = nTf;
        nameTxt.text = item.name;
        nameTxt.x = 14;
        nameTxt.y = 4;
        nameTxt.width = isPlaced ? (w - 75) : (w - 24);
        nameTxt.height = 18;
        nameTxt.selectable = false;
        nameTxt.mouseEnabled = false;
        card.addChild(nameTxt);

        // Action Description
        var descTxt = new TextField();
        var dTf = new TextFormat("_sans", 9, isPlaced ? 0x555555 : 0x888888, false);
        descTxt.defaultTextFormat = dTf;
        descTxt.text = item.description;
        descTxt.x = 14;
        descTxt.y = 22;
        descTxt.width = w - 24;
        descTxt.height = 16;
        descTxt.selectable = false;
        descTxt.mouseEnabled = false;
        card.addChild(descTxt);

        if (isPlaced) {
            // Placed Badge (Plain ASCII)
            var badge = new TextField();
            var bTf = new TextFormat("_sans", 8, 0x888888, true);
            bTf.align = TextFormatAlign.RIGHT;
            badge.defaultTextFormat = bTf;
            badge.text = "[ ACTIVE ]";
            badge.autoSize = TextFieldAutoSize.RIGHT;
            badge.x = w - 62;
            badge.y = 12;
            badge.selectable = false;
            badge.mouseEnabled = false;
            card.addChild(badge);
            card.alpha = 0.55;
        } else {
            card.addEventListener(MouseEvent.ROLL_OVER, function(_):Void {
                drawCard(true);
            });
            card.addEventListener(MouseEvent.ROLL_OUT, function(_):Void {
                drawCard(false);
            });
            card.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
                if (onPick != null) {
                    onPick(item.name);
                }
                onDismiss();
            });
        }

        return card;
    }

    private function getCategoryColor(cat:String):Int {
        return switch (cat) {
            case "Combat": 0xDC3545; // Red
            case "Storage": 0x007BFF; // Blue
            case "Movement": 0x28A745; // Green
            default: 0x9B59B6; // Purple
        };
    }

    private function scrollList(delta:Float):Void {
        var contentH = listContainer.height;
        if (contentH <= LIST_H) {
            listContainer.y = LIST_Y;
            return;
        }

        var newY = listContainer.y + delta;
        var minY = LIST_Y - (contentH - LIST_H);
        var maxY = LIST_Y;

        if (newY < minY) newY = minY;
        if (newY > maxY) newY = maxY;

        listContainer.y = newY;
    }

    private function onDismiss(?e:MouseEvent):Void {
        if (parent != null) {
            parent.removeChild(this);
        }
    }
}
