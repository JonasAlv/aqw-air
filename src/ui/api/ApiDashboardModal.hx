package ui.api;

#if flash
import com.aqwapi.Api;
import com.aqwapi.modules.CombatEngine;
import com.aqwapi.modules.ScriptManager;
import com.aqwapi.utils.ApiLogger;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Keyboard;
import ui.api.ApiNotificationManager;
import ui.Overlay;
import ui.shortcut.ShortcutPicker;
import controller.walk.MouseWalkSimulatorController;
import load.SWFCache;
import ui.api.prompts.ApiPrompts;
import util.HelperSetting;

enum DashboardTab {
    // API Automation tabs
    TabScripts;
    TabAutomation;
    TabEnhancements;
    TabHud;
    TabApiSettings;
    TabSettings;
    // Client Settings tabs
    TabGeneral;
    TabGameplay;
    TabGraphics;
    TabControls;
    TabShortcuts;
}

class ApiDashboardModal extends Sprite {
    private static var _instance:ApiDashboardModal = null;

    public static function show(overlay:Dynamic, pocket:Dynamic = null):Void {
        close();
        _instance = new ApiDashboardModal(overlay, pocket);
        if (overlay != null) {
            overlay.addChild(_instance);
        }
    }

    public static function close():Void {
        if (_instance != null && _instance.parent != null) {
            _instance.parent.removeChild(_instance);
        }
        _instance = null;
    }

    public static function isOpen():Bool {
        return _instance != null && _instance.parent != null;
    }

    // Modal layout constants
    private static inline var DIALOG_WIDTH:Float = 780;
    private static inline var DIALOG_HEIGHT:Float = 470;
    private static inline var SIDEBAR_WIDTH:Float = 175;
    private static inline var CONTENT_WIDTH:Float = 565;
    private static inline var CONTENT_HEIGHT:Float = 405;

    private var _overlay:Dynamic;
    private var _pocket:Dynamic;
    private var _backdrop:Sprite;
    private var _window:Sprite;

    private var _titleTxt:TextField;
    private var _badgeTxt:TextField;
    private var _sidebarContainer:Sprite;

    private var _currentTab:DashboardTab = TabScripts;
    private var _tabButtons:Map<DashboardTab, Sprite> = new Map<DashboardTab, Sprite>();
    private var _tabLabels:Map<DashboardTab, TextField> = new Map<DashboardTab, TextField>();

    private var _contentViewport:Sprite;
    private var _contentMask:Shape;
    private var _contentContainer:Sprite;
    private var _totalContentHeight:Float = 0;

    // Scrolling state
    private var _scrollbarTrack:Shape;
    private var _scrollbarThumb:Shape;
    private var _isDraggingScroll:Bool = false;
    private var _hasDraggedScroll:Bool = false;
    private var _dragStartY:Float = 0;
    private var _dragStartContentY:Float = 0;

    public function new(overlay:Dynamic, pocket:Dynamic) {
        super();
        _overlay = overlay;
        _pocket = pocket;

        var stageW:Float = 960;
        var stageH:Float = 500;
        if (overlay != null && overlay.stage != null) {
            stageW = overlay.stage.stageWidth > 0 ? overlay.stage.stageWidth : 960;
            stageH = overlay.stage.stageHeight > 0 ? overlay.stage.stageHeight : 500;
        }

        // 1. Semi-transparent backdrop
        _backdrop = new Sprite();
        _backdrop.graphics.beginFill(0x000000, 0.65);
        _backdrop.graphics.drawRect(0, 0, stageW, stageH);
        _backdrop.graphics.endFill();
        _backdrop.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            if (e.target == _backdrop) close();
        });
        addChild(_backdrop);

        // 2. Main Dialog Window
        _window = new Sprite();
        _window.graphics.beginFill(0x121212, 0.98);
        _window.graphics.lineStyle(1, 0x2A2A2A);
        _window.graphics.drawRoundRect(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT, 8, 8);
        _window.graphics.endFill();

        _window.x = (stageW - DIALOG_WIDTH) / 2;
        _window.y = (stageH - DIALOG_HEIGHT) / 2;
        addChild(_window);

        // 3. Header Bar
        setupHeader();

        // 4. Sidebar Tabs
        _sidebarContainer = new Sprite();
        _window.addChild(_sidebarContainer);
        setupSidebar();

        // 5. Content Viewport
        setupContentViewport();

        // 6. Render Initial Tab
        switchTab(TabScripts);

        // 7. Global Stage Listeners
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
    }

    private function onAddedToStage(e:Event):Void {
        if (stage != null) {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }
    }

    private function onRemovedFromStage(e:Event):Void {
        if (stage != null) {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }
    }

    private function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == 27) { // ESC key
            close();
        }
    }

    // =========================================================================
    // HEADER
    // =========================================================================

    private function setupHeader():Void {
        // Divider line below header
        _window.graphics.lineStyle(1, 0x242424);
        _window.graphics.moveTo(0, 48);
        _window.graphics.lineTo(DIALOG_WIDTH, 48);

        // Title
        _titleTxt = new TextField();
        var titleFmt = new TextFormat("_sans", 16, 0xEEEEEE, true);
        _titleTxt.defaultTextFormat = titleFmt;
        _titleTxt.text = "Control Center";
        _titleTxt.x = 20;
        _titleTxt.y = 13;
        _titleTxt.width = 140;
        _titleTxt.height = 28;
        _titleTxt.selectable = false;
        _titleTxt.mouseEnabled = false;
        _window.addChild(_titleTxt);

        // Subtitle badge
        _badgeTxt = new TextField();
        var badgeFmt = new TextFormat("_sans", 11, 0x666666, false);
        _badgeTxt.defaultTextFormat = badgeFmt;
        _badgeTxt.text = "AQW Pocket Mod & Automation";
        _badgeTxt.x = 160;
        _badgeTxt.y = 17;
        _badgeTxt.width = 240;
        _badgeTxt.height = 20;
        _badgeTxt.selectable = false;
        _badgeTxt.mouseEnabled = false;
        _window.addChild(_badgeTxt);

        // Close Button (Vector ✕)
        var closeBtn = new Sprite();
        var cbW:Float = 32;
        var cbH:Float = 28;
        closeBtn.buttonMode = true;
        closeBtn.x = DIALOG_WIDTH - cbW - 14;
        closeBtn.y = 10;

        var renderCloseBtn = function(isHover:Bool):Void {
            closeBtn.graphics.clear();
            var bg = isHover ? 0x990000 : 0x1E1E1E;
            var border = isHover ? 0xCC0000 : 0x333333;
            var xColor = isHover ? 0xFFFFFF : 0xAAAAAA;

            closeBtn.graphics.beginFill(bg, 1);
            closeBtn.graphics.lineStyle(1, border);
            closeBtn.graphics.drawRoundRect(0, 0, cbW, cbH, 5, 5);
            closeBtn.graphics.endFill();

            var cx:Float = cbW / 2;
            var cy:Float = cbH / 2;
            var size:Float = 4.5;
            closeBtn.graphics.lineStyle(2, xColor, 1);
            closeBtn.graphics.moveTo(cx - size, cy - size);
            closeBtn.graphics.lineTo(cx + size, cy + size);
            closeBtn.graphics.moveTo(cx + size, cy - size);
            closeBtn.graphics.lineTo(cx - size, cy + size);
        };
        renderCloseBtn(false);

        closeBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):Void {
            renderCloseBtn(true);
        });
        closeBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
            renderCloseBtn(false);
        });
        closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            close();
        });
        _window.addChild(closeBtn);
    }

    // =========================================================================
    // SIDEBAR
    // =========================================================================

    private function setupSidebar():Void {
        // Vertical divider line between sidebar and content
        _window.graphics.lineStyle(1, 0x242424);
        _window.graphics.moveTo(SIDEBAR_WIDTH + 14, 48);
        _window.graphics.lineTo(SIDEBAR_WIDTH + 14, DIALOG_HEIGHT);

        while (_sidebarContainer.numChildren > 0) {
            _sidebarContainer.removeChildAt(0);
        }
        _tabButtons = new Map<DashboardTab, Sprite>();
        _tabLabels = new Map<DashboardTab, TextField>();

        var tabW:Float = SIDEBAR_WIDTH - 12;
        var tabH:Float = 27;
        var tabY:Float = 56;

        // Section 1: Automation
        var autoHeader = createSidebarSectionHeader("AUTOMATION", tabW);
        autoHeader.x = 14;
        autoHeader.y = tabY;
        _sidebarContainer.addChild(autoHeader);
        tabY += 18;

        var autoTabs = [
            { id: TabScripts, label: "Scripts" },
            { id: TabAutomation, label: "Combat & Quests" },
            { id: TabEnhancements, label: "Enhancements" },
            { id: TabHud, label: "HUD Controls" },
            { id: TabApiSettings, label: "API Settings" }
        ];

        for (t in autoTabs) {
            var btn = createTabButton(t.label, tabW, tabH, t.id);
            btn.x = 14;
            btn.y = tabY;
            _sidebarContainer.addChild(btn);
            tabY += tabH + 4;
        }

        tabY += 10;

        // Section 2: Client Settings
        var clientHeader = createSidebarSectionHeader("CLIENT SETTINGS", tabW);
        clientHeader.x = 14;
        clientHeader.y = tabY;
        _sidebarContainer.addChild(clientHeader);
        tabY += 18;

        var clientTabs = [
            { id: TabGeneral, label: "Display & FPS" },
            { id: TabGameplay, label: "Gameplay & Bags" },
            { id: TabGraphics, label: "Graphics & Hides" },
            { id: TabControls, label: "Controls & Touch" },
            { id: TabShortcuts, label: "Hotkeys & Bar" },
            { id: TabSettings, label: "System Settings" }
        ];

        for (t in clientTabs) {
            var btn = createTabButton(t.label, tabW, tabH, t.id);
            btn.x = 14;
            btn.y = tabY;
            _sidebarContainer.addChild(btn);
            tabY += tabH + 4;
        }
    }

    private function createSidebarSectionHeader(title:String, w:Float):Sprite {
        var sp = new Sprite();
        var txt = new TextField();
        var fmt = new TextFormat("_sans", 9, 0xCC4444, true);
        txt.defaultTextFormat = fmt;
        txt.text = title;
        txt.x = 6;
        txt.y = 0;
        txt.width = w - 12;
        txt.height = 16;
        txt.selectable = false;
        txt.mouseEnabled = false;
        sp.addChild(txt);
        return sp;
    }

    private function createTabButton(label:String, w:Float, h:Float, tabId:DashboardTab):Sprite {
        var btn = new Sprite();
        btn.buttonMode = true;

        var txt = new TextField();
        var fmt = new TextFormat("_sans", 11, 0x888888, true);
        txt.defaultTextFormat = fmt;
        txt.text = label;
        txt.x = 12;
        txt.y = (h - 17) / 2;
        txt.width = w - 16;
        txt.selectable = false;
        txt.mouseEnabled = false;

        btn.addChild(txt);
        _tabButtons.set(tabId, btn);
        _tabLabels.set(tabId, txt);

        btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            switchTab(tabId);
        });

        btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):Void {
            if (_currentTab != tabId) {
                renderTabGraphic(btn, w, h, false, true);
                txt.textColor = 0xCCCCCC;
            }
        });

        btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
            if (_currentTab != tabId) {
                renderTabGraphic(btn, w, h, false, false);
                txt.textColor = 0x888888;
            }
        });

        renderTabGraphic(btn, w, h, false, false);
        return btn;
    }

    private function renderTabGraphic(btn:Sprite, w:Float, h:Float, isActive:Bool, isHover:Bool):Void {
        btn.graphics.clear();
        if (isActive) {
            btn.graphics.beginFill(0x880000, 1);
            btn.graphics.lineStyle(1, 0xAA0000);
            btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
            btn.graphics.endFill();

            btn.graphics.beginFill(0xFF4444, 1);
            btn.graphics.lineStyle(0, 0, 0);
            btn.graphics.drawRoundRect(0, 3, 3, h - 6, 2, 2);
            btn.graphics.endFill();
        } else if (isHover) {
            btn.graphics.beginFill(0x222222, 1);
            btn.graphics.lineStyle(1, 0x3A3A3A);
            btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
            btn.graphics.endFill();
        } else {
            btn.graphics.beginFill(0x171717, 1);
            btn.graphics.lineStyle(1, 0x242424);
            btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
            btn.graphics.endFill();
        }
    }

    private function switchTab(tabId:DashboardTab):Void {
        _currentTab = tabId;

        var tabW:Float = SIDEBAR_WIDTH - 12;
        var tabH:Float = 27;

        for (t in _tabButtons.keys()) {
            var btn = _tabButtons.get(t);
            var txt = _tabLabels.get(t);
            var isActive = (t == tabId);
            renderTabGraphic(btn, tabW, tabH, isActive, false);
            txt.textColor = isActive ? 0xFFFFFF : 0x888888;
        }

        renderTabContent(tabId);
    }

    // =========================================================================
    // CONTENT VIEWPORT & SCROLLING
    // =========================================================================

    private function setupContentViewport():Void {
        _contentViewport = new Sprite();
        _contentViewport.x = SIDEBAR_WIDTH + 26;
        _contentViewport.y = 56;
        _window.addChild(_contentViewport);

        _contentMask = new Shape();
        _contentMask.graphics.beginFill(0xFF0000);
        _contentMask.graphics.drawRect(0, 0, CONTENT_WIDTH, CONTENT_HEIGHT);
        _contentMask.graphics.endFill();
        _contentMask.x = _contentViewport.x;
        _contentMask.y = _contentViewport.y;
        _window.addChild(_contentMask);

        _contentContainer = new Sprite();
        _contentViewport.addChild(_contentContainer);
        _contentViewport.mask = _contentMask;

        _scrollbarTrack = new Shape();
        _scrollbarTrack.x = _contentViewport.x + CONTENT_WIDTH - 8;
        _scrollbarTrack.y = _contentViewport.y;
        _window.addChild(_scrollbarTrack);

        _scrollbarThumb = new Shape();
        _scrollbarThumb.x = _scrollbarTrack.x;
        _scrollbarThumb.y = _scrollbarTrack.y;
        _window.addChild(_scrollbarThumb);

        _window.addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):Void {
            var totalH = getTotalContentHeight();
            if (totalH <= CONTENT_HEIGHT) return;
            var maxScroll = CONTENT_HEIGHT - totalH;
            _contentContainer.y += e.delta * 25;
            if (_contentContainer.y > 0) _contentContainer.y = 0;
            if (_contentContainer.y < maxScroll) _contentContainer.y = maxScroll;
            updateScrollbar();
        });

        _contentViewport.addEventListener(MouseEvent.MOUSE_DOWN, onContentMouseDown);
    }

    private function onContentMouseDown(e:MouseEvent):Void {
        var totalH = getTotalContentHeight();
        if (stage == null || totalH <= CONTENT_HEIGHT) return;
        _isDraggingScroll = false;
        _hasDraggedScroll = false;
        _dragStartY = stage.mouseY;
        _dragStartContentY = _contentContainer.y;

        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
    }

    private function onStageMouseMove(e:MouseEvent):Void {
        var totalH = getTotalContentHeight();
        if (stage == null || totalH <= CONTENT_HEIGHT) return;
        var dy = stage.mouseY - _dragStartY;
        if (!_isDraggingScroll && Math.abs(dy) > 10) {
            _isDraggingScroll = true;
            _hasDraggedScroll = true;
        }
        if (_isDraggingScroll) {
            var newY = _dragStartContentY + dy;
            var maxScroll = CONTENT_HEIGHT - totalH;
            if (newY > 0) newY = 0;
            if (newY < maxScroll) newY = maxScroll;
            _contentContainer.y = newY;
            updateScrollbar();
        }
    }

    private function onStageMouseUp(e:MouseEvent):Void {
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }
        haxe.Timer.delay(function() {
            _isDraggingScroll = false;
            _hasDraggedScroll = false;
        }, 80);
    }

    private function updateScrollbar():Void {
        var totalH = getTotalContentHeight();
        if (totalH <= CONTENT_HEIGHT) {
            _scrollbarTrack.visible = false;
            _scrollbarThumb.visible = false;
            return;
        }

        _scrollbarTrack.visible = true;
        _scrollbarThumb.visible = true;

        var sbW:Float = 6;
        _scrollbarTrack.graphics.clear();
        _scrollbarTrack.graphics.beginFill(0x1E1E1E, 0.8);
        _scrollbarTrack.graphics.drawRoundRect(0, 0, sbW, CONTENT_HEIGHT, 3, 3);
        _scrollbarTrack.graphics.endFill();

        var viewRatio = CONTENT_HEIGHT / totalH;
        var thumbH = Math.max(20, CONTENT_HEIGHT * viewRatio);
        var scrollRatio = -_contentContainer.y / (totalH - CONTENT_HEIGHT);
        var thumbY = scrollRatio * (CONTENT_HEIGHT - thumbH);

        _scrollbarThumb.graphics.clear();
        _scrollbarThumb.graphics.beginFill(0x555555, 0.9);
        _scrollbarThumb.graphics.drawRoundRect(0, thumbY, sbW, thumbH, 3, 3);
        _scrollbarThumb.graphics.endFill();
    }

    // =========================================================================
    // ITEM ROW RENDERERS
    // =========================================================================

    private function clearContent():Void {
        while (_contentContainer.numChildren > 0) {
            _contentContainer.removeChildAt(0);
        }
        _totalContentHeight = 0;
        _contentContainer.y = 0;
        updateScrollbar();
    }

    private function getTotalContentHeight():Float {
        return _totalContentHeight > 6 ? (_totalContentHeight - 6) : _totalContentHeight;
    }

    private function addSectionHeader(title:String):Void {
        var rowW:Float = CONTENT_WIDTH - 20;
        var header = new Sprite();

        var lbl = new TextField();
        var fmt = new TextFormat("_sans", 11, 0xCC4444, true);
        lbl.defaultTextFormat = fmt;
        lbl.text = title.toUpperCase();
        lbl.x = 2;
        lbl.y = 0;
        lbl.autoSize = TextFieldAutoSize.LEFT;
        lbl.selectable = false;
        lbl.mouseEnabled = false;
        header.addChild(lbl);

        var lineX:Float = lbl.x + lbl.width + 8;
        if (lineX < rowW) {
            header.graphics.lineStyle(1, 0x2A2A2A);
            header.graphics.moveTo(lineX, 7);
            header.graphics.lineTo(rowW, 7);
        }

        header.x = 0;
        header.y = _totalContentHeight + 4;
        _contentContainer.addChild(header);

        _totalContentHeight += 22;
        updateScrollbar();
    }

    private function addInfoBanner(text:String):Void {
        var rowW:Float = CONTENT_WIDTH - 20;
        var banner = new Sprite();

        var descTxt = new TextField();
        var fmt = new TextFormat("_sans", 11, 0x999999, false);
        descTxt.defaultTextFormat = fmt;
        descTxt.text = text;
        descTxt.x = 10;
        descTxt.y = 8;
        descTxt.width = rowW - 20;
        descTxt.wordWrap = true;
        descTxt.multiline = true;
        descTxt.autoSize = TextFieldAutoSize.LEFT;
        descTxt.selectable = false;
        descTxt.mouseEnabled = false;
        banner.addChild(descTxt);

        var bannerH:Float = descTxt.height + 16;
        banner.graphics.beginFill(0x161616, 0.85);
        banner.graphics.lineStyle(1, 0x282828);
        banner.graphics.drawRoundRect(0, 0, rowW, bannerH, 6, 6);
        banner.graphics.endFill();

        banner.x = 0;
        banner.y = _totalContentHeight;
        _contentContainer.addChild(banner);

        _totalContentHeight += bannerH + 8;
        updateScrollbar();
    }

    private function addItemRow(
        title:String,
        description:String,
        actionType:String,
        actionLabel:String,
        isPrimary:Bool,
        onClick:Void->Void,
        getToggleState:Void->Bool = null,
        getCycleLabel:Void->String = null
    ):Void {
        var rowW:Float = CONTENT_WIDTH - 20;
        var btnW:Float = (actionType == "cycle") ? 144.0 : 116.0;
        var btnH:Float = 32;
        var padX:Float = 14;
        var gapBtn:Float = 12;
        var textW:Float = rowW - padX - btnW - gapBtn - 6;

        var card = new Sprite();

        // Title
        var titleTxt = new TextField();
        var titleFmt = new TextFormat("_sans", 13, 0xFFFFFF, true);
        titleTxt.defaultTextFormat = titleFmt;
        titleTxt.text = title;
        titleTxt.x = padX;
        titleTxt.y = 10;
        titleTxt.width = textW;
        titleTxt.wordWrap = true;
        titleTxt.multiline = true;
        titleTxt.autoSize = TextFieldAutoSize.LEFT;
        titleTxt.selectable = false;
        titleTxt.mouseEnabled = false;
        card.addChild(titleTxt);

        // Description (Word wrapped & autoSize so text scales dynamically without clipping!)
        var descTxt = new TextField();
        var descFmt = new TextFormat("_sans", 11, 0x888888, false);
        descTxt.defaultTextFormat = descFmt;
        descTxt.text = description;
        descTxt.x = padX;
        descTxt.y = titleTxt.y + titleTxt.height + 3;
        descTxt.width = textW;
        descTxt.wordWrap = true;
        descTxt.multiline = true;
        descTxt.autoSize = TextFieldAutoSize.LEFT;
        descTxt.selectable = false;
        descTxt.mouseEnabled = false;
        card.addChild(descTxt);

        // Dynamic height calculation based on actual content
        var textBottom:Float = descTxt.y + descTxt.height + 10;
        var minCardH:Float = btnH + 18; // 50px
        var cardH:Float = Math.max(minCardH, textBottom);

        // Action button / toggle vertically centered within dynamic card height
        var actionX:Float = rowW - padX - btnW;
        var actionY:Float = (cardH - btnH) / 2;

        var actionControl:Sprite = null;
        if (actionType == "toggle") {
            var toggleBtn = createToggleControl(btnW, btnH, getToggleState, onClick);
            toggleBtn.x = actionX;
            toggleBtn.y = actionY;
            card.addChild(toggleBtn);
            actionControl = toggleBtn;
        } else if (actionType == "cycle") {
            var cycleBtn = createCycleControl(btnW, btnH, getCycleLabel, onClick);
            cycleBtn.x = actionX;
            cycleBtn.y = actionY;
            card.addChild(cycleBtn);
            actionControl = cycleBtn;
        } else {
            var btn = createActionButton(actionLabel, btnW, btnH, isPrimary, onClick);
            btn.x = actionX;
            btn.y = actionY;
            card.addChild(btn);
            actionControl = btn;
        }

        if (actionType == "toggle") {
            card.buttonMode = true;
            card.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
                if (_isDraggingScroll || _hasDraggedScroll) return;
                if (actionControl != null && (e.target == actionControl || actionControl.contains(cast e.target))) {
                    return;
                }
                if (onClick != null) onClick();
            });
        }

        // Draw card background with hover responsiveness
        var renderCardBg = function(isHover:Bool):Void {
            card.graphics.clear();
            card.graphics.beginFill(isHover ? 0x1C1C1C : 0x181818, 1);
            card.graphics.lineStyle(1, isHover ? 0x2E2E2E : 0x242424);
            card.graphics.drawRoundRect(0, 0, rowW, cardH, 6, 6);
            card.graphics.endFill();
        };
        renderCardBg(false);

        card.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):Void {
            renderCardBg(true);
        });
        card.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
            renderCardBg(false);
        });

        // Snap vertically directly below previous card
        card.x = 0;
        card.y = _totalContentHeight;
        _contentContainer.addChild(card);

        // Advance vertical anchor snapping to the next card with 6px gap
        _totalContentHeight += cardH + 6;

        updateScrollbar();
    }

    private function createActionButton(label:String, w:Float, h:Float, isPrimary:Bool, onClick:Void->Void):Sprite {
        var btn = new Sprite();
        btn.buttonMode = true;

        var bg = isPrimary ? 0x880000 : 0x1E1E1E;
        var border = isPrimary ? 0xAA0000 : 0x333333;
        var hoverBg = isPrimary ? 0xAA0000 : 0x2A2A2A;
        var hoverBorder = isPrimary ? 0xDD0000 : 0x555555;
        var textColor = isPrimary ? 0xFFFFFF : 0xCCCCCC;

        btn.graphics.beginFill(bg, 1);
        btn.graphics.lineStyle(1, border);
        btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
        btn.graphics.endFill();

        var txt = new TextField();
        var fmt = new TextFormat("_sans", 12, textColor, true);
        fmt.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = fmt;
        txt.text = label;
        txt.width = w;
        txt.height = 20;
        txt.y = (h - 20) / 2;
        txt.selectable = false;
        txt.mouseEnabled = false;
        btn.addChild(txt);

        btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):Void {
            btn.graphics.clear();
            btn.graphics.beginFill(hoverBg, 1);
            btn.graphics.lineStyle(1, hoverBorder);
            btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
            btn.graphics.endFill();
            txt.textColor = 0xFFFFFF;
        });

        btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
            btn.graphics.clear();
            btn.graphics.beginFill(bg, 1);
            btn.graphics.lineStyle(1, border);
            btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
            btn.graphics.endFill();
            txt.textColor = textColor;
        });

        btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            if (_isDraggingScroll || _hasDraggedScroll) return;
            if (onClick != null) onClick();
        });
        btn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            if (_isDraggingScroll || _hasDraggedScroll) return;
            if (onClick != null) onClick();
        });

        return btn;
    }

    private function createCycleControl(w:Float, h:Float, getLabel:Void->String, onCycle:Void->Void):Sprite {
        var btn = new Sprite();
        btn.buttonMode = true;

        var txt = new TextField();
        var fmt = new TextFormat("_sans", 11, 0xFFFFFF, true);
        fmt.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = fmt;
        txt.width = w;
        txt.height = 20;
        txt.y = (h - 20) / 2;
        txt.selectable = false;
        txt.mouseEnabled = false;
        btn.addChild(txt);

        var updateVisual = function(isHover:Bool = false):Void {
            btn.graphics.clear();
            var bg = isHover ? 0x2A2A2A : 0x1E1E1E;
            var border = isHover ? 0x4A4A4A : 0x333333;
            btn.graphics.beginFill(bg, 1);
            btn.graphics.lineStyle(1, border);
            btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
            btn.graphics.endFill();
            txt.text = (getLabel != null) ? getLabel() : "";
        };

        btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):Void {
            updateVisual(true);
        });
        btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
            updateVisual(false);
        });
        btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            if (_isDraggingScroll || _hasDraggedScroll) return;
            if (onCycle != null) onCycle();
            updateVisual(false);
        });
        btn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            if (_isDraggingScroll || _hasDraggedScroll) return;
            if (onCycle != null) onCycle();
            updateVisual(false);
        });

        updateVisual(false);
        return btn;
    }

    private function createToggleControl(w:Float, h:Float, getState:Void->Bool, onToggle:Void->Void):Sprite {
        var btn = new Sprite();
        btn.buttonMode = true;

        var txt = new TextField();
        var fmt = new TextFormat("_sans", 11, 0xFFFFFF, true);
        fmt.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = fmt;
        txt.width = w;
        txt.height = 20;
        txt.y = (h - 20) / 2;
        txt.selectable = false;
        txt.mouseEnabled = false;
        btn.addChild(txt);

        var updateVisual = function():Void {
            var active = (getState != null) ? getState() : false;
            btn.graphics.clear();
            if (active) {
                btn.graphics.beginFill(0x103318, 1);
                btn.graphics.lineStyle(1, 0x2D7A3E);
                btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
                btn.graphics.endFill();
                txt.textColor = 0x44EE77;
                txt.text = "ON";
            } else {
                btn.graphics.beginFill(0x1A1A1A, 1);
                btn.graphics.lineStyle(1, 0x383838);
                btn.graphics.drawRoundRect(0, 0, w, h, 5, 5);
                btn.graphics.endFill();
                txt.textColor = 0x777777;
                txt.text = "OFF";
            }
        };

        btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            if (_isDraggingScroll || _hasDraggedScroll) return;
            if (onToggle != null) onToggle();
            updateVisual();
        });
        btn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            if (_isDraggingScroll || _hasDraggedScroll) return;
            if (onToggle != null) onToggle();
            updateVisual();
        });

        btn.addEventListener(Event.ENTER_FRAME, function(e:Event):Void {
            updateVisual();
        });

        updateVisual();
        return btn;
    }

    // =========================================================================
    // TAB CONTENTS
    // =========================================================================

    private function renderTabContent(tabId:DashboardTab):Void {
        clearContent();

        switch (tabId) {
            case TabScripts:
                renderScriptsTab();
            case TabAutomation:
                renderAutomationTab();
            case TabEnhancements:
                renderEnhancementsTab();
            case TabHud:
                renderHudTab();
            case TabApiSettings:
                renderApiSettingsTab();
            case TabSettings:
                renderSettingsTab();
            case TabGeneral:
                renderGeneralTab();
            case TabGameplay:
                renderGameplayTab();
            case TabGraphics:
                renderGraphicsTab();
            case TabControls:
                renderControlsTab();
            case TabShortcuts:
                renderShortcutsTab();
        }
    }

    private function renderScriptsTab():Void {
        addSectionHeader("Script Execution");

        // 1. Script Manager
        addItemRow(
            "Script Manager",
            "Manage, edit, create, save, and run automation scripts.",
            "button",
            "Open",
            true, // Primary red button!
            function():Void {
                close();
                ApiPrompts.showScriptManager(_overlay);
            }
        );

        // 2. Script Engine State (Run/Stop toggle)
        addItemRow(
            "Script Runner",
            "Controls active script execution. Turn off to immediately abort any running script.",
            "toggle",
            "",
            false,
            function():Void {
                if (ScriptManager.SINGLETON.isRunning) {
                    ScriptManager.SINGLETON.stop();
                    ApiNotificationManager.notify("Script stopped.");
                } else {
                    ScriptManager.SINGLETON.start();
                    if (ScriptManager.SINGLETON.isRunning) {
                        ApiNotificationManager.notify("Script started.");
                    } else {
                        ApiNotificationManager.notify("No script loaded! Open Script Manager to select one.");
                    }
                }
            },
            function():Bool {
                return ScriptManager.SINGLETON.isRunning;
            }
        );

        // 3. Load Script from file
        #if air
        addItemRow(
            "Load Script File",
            "Browse and load an .hscript or text file directly from your local filesystem.",
            "button",
            "Load",
            false,
            function():Void {
                try {
                    var fileCls:Dynamic = untyped __global__["flash.filesystem.File"];
                    var fsCls:Dynamic = untyped __global__["flash.filesystem.FileStream"];
                    var fmCls:Dynamic = untyped __global__["flash.filesystem.FileMode"];
                    var ffCls:Dynamic = untyped __global__["flash.net.FileFilter"];

                    var file = fileCls.desktopDirectory;
                    file.addEventListener("select", function(ev:Dynamic):Void {
                        var stream = Type.createInstance(fsCls, []);
                        stream.open(file, fmCls.READ);
                        var content:String = stream.readUTFBytes(stream.bytesAvailable);
                        stream.close();

                        close();
                        ScriptManager.SINGLETON.loadScript(content);
                        ScriptManager.SINGLETON.start();
                        ApiNotificationManager.notify("Loaded: " + file.name);
                    });
                    file.browseForOpen("Select Script", [Type.createInstance(ffCls, ["HScript / Text (*.hscript, *.txt)", "*.hscript;*.txt"])]);
                } catch (e:Dynamic) {
                    ApiNotificationManager.notify("File error: " + e);
                }
            }
        );
        #end

        // 4. Paste Script
        addItemRow(
            "Paste Script",
            "Paste raw HScript code and execute it immediately in the runtime engine.",
            "button",
            "Paste",
            false,
            function():Void {
                close();
                ApiPrompts.showPastePrompt(_overlay);
            }
        );

        addSectionHeader("Automation & Logging");

        // 5. Class Loadouts (For Scripts)
        addItemRow(
            "Class Loadouts (Scripting)",
            "Configure default Farm, Solo, Boss, and Dodge classes for script auto-swapping.",
            "button",
            "Setup",
            false,
            function():Void {
                close();
                ApiPrompts.showLoadoutsPrompt(_overlay);
            }
        );

        // 6. Chat Logger (Toggle)
        addItemRow(
            "Chat Logger",
            "Display API and script actions in the in-game chat box. Turn off to silence blue text messages.",
            "toggle",
            "",
            false,
            function():Void {
                var next = !ApiLogger.printToChat;
                ApiLogger.setChatLogging(next);
                ApiNotificationManager.notify("Chat Logger: " + (next ? "Enabled" : "Muted"));
            },
            function():Bool {
                return ApiLogger.printToChat;
            }
        );

        // 7. Clear API Log
        addItemRow(
            "Clear API Log",
            "Truncates assets/api.log to start fresh for monitoring and debugging sessions.",
            "button",
            "Clear Log",
            false,
            function():Void {
                ApiLogger.clearLog();
                ApiNotificationManager.notify("api.log cleared!");
            }
        );

        // 8. Copy API Log
        addItemRow(
            "Copy API Log",
            "Copies contents of assets/api.log to the system clipboard for sharing and bug reporting.",
            "button",
            "Copy Log",
            false,
            function():Void {
                if (ApiLogger.copyToClipboard()) {
                    ApiNotificationManager.notify("API log copied to clipboard!");
                } else {
                    ApiNotificationManager.notify("API log is empty or could not be read.");
                }
            }
        );
    }

    private function renderAutomationTab():Void {
        addSectionHeader("Smart Combat");

        // 1. Smart Combat Toggle
        addItemRow(
            "Smart Combat",
            "Auto-detects equipped class and executes optimal skill combos and priority rotations.",
            "toggle",
            "",
            false,
            function():Void {
                var current = (Api.combat != null && Api.combat.isRunning());
                var next = !current;
                HelperSetting.setBool("api_smart_combat_active", next);
                if (Api.combat != null) {
                    if (next) {
                        var confClass = HelperSetting.getString("api_smart_class", "Current");
                        var confMode = HelperSetting.getString("api_smart_mode", "Auto");
                        Api.combat.startSmartStandalone(confClass, confMode);
                    } else {
                        Api.combat.stop();
                    }
                }
                ApiNotificationManager.notify("Smart Combat: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.combat != null && Api.combat.isRunning());
            }
        );

        // 2. Smart Combat Setup (Standalone)
        addItemRow(
            "Smart Combat Setup",
            "Standalone Smart Combat setup. Choose target class and mode (or set to 'Current').",
            "button",
            "Configure",
            false,
            function():Void {
                close();
                ApiPrompts.showSmartCombatPrompt(_overlay);
            }
        );

        // 3. Combat Modes Editor
        addItemRow(
            "Combat Modes",
            "Create, edit, and save skill rotations directly to userSkills.json.",
            "button",
            "Editor",
            false,
            function():Void {
                close();
                ApiPrompts.showCombatModeEditorPrompt(_overlay);
            }
        );

        addSectionHeader("Custom Combos & Quests");

        // 4. Custom Auto-Combat
        addItemRow(
            "Custom Combat",
            "Setup custom skill combo sequences and targeting rules.",
            "button",
            "Configure",
            false,
            function():Void {
                close();
                ApiPrompts.showCombatPrompt(_overlay);
            }
        );

        // 5. Auto-Quest
        var isQuestAuto = (Api.quest != null && Api.quest.isAutoRunning);
        var qStr = (Api.quest != null) ? Api.quest.autoQuestString : "";
        var questDesc = isQuestAuto
            ? ("Active: Safe looping accept & turn-in (" + (qStr != "" ? qStr : "Running") + ")")
            : "Automatically accept and turn in quests by IDs in the background using safe queue pacing.";
        addItemRow(
            "Auto-Quest",
            questDesc,
            "button",
            isQuestAuto ? "Running" : "Configure",
            isQuestAuto,
            function():Void {
                close();
                ApiPrompts.showQuestPrompt(_overlay);
            }
        );
    }

    private function renderEnhancementsTab():Void {
        var curClass = (Api.player != null && Api.player.className != null && Api.player.className != "") ? Api.player.className : "Equipped Class";

        addSectionHeader("Auto-Enhance");

        // 1. One-Click Smart Enhance (Equipped)
        addItemRow(
            "Smart Enhance (Equipped)",
            "Auto-detects " + curClass + " & unlocks, then enhances equipped weapon, class, helm, and cape to the optimal build.",
            "button",
            "Enhance",
            true, // Primary red button!
            function():Void {
                if (Api.enhancement != null) {
                    if (Api.enhancement.isBusy) {
                        ApiNotificationManager.notify("Enhancement queue is currently busy!");
                        return;
                    }
                    ApiNotificationManager.notify("SmartEnhancing " + curClass + "...");
                    Api.enhancement.smartEnhance(null, function():Void {
                        ApiNotificationManager.notify("SmartEnhance finished!");
                    });
                }
            }
        );

        // 2. Custom Enhance Gear (Modal)
        addItemRow(
            "Custom Enhance Gear...",
            "Choose custom base enhancement types and Awe/Forge special traits for equipped gear.",
            "button",
            "Configure",
            false,
            function():Void {
                close();
                ApiPrompts.showCustomEnhancePrompt(_overlay);
            }
        );

        addSectionHeader("Enhancement Shops");

        // 3. Lvl 50+ Enhancements
        var lvl50Shops = [
            { name: "Healer Enh", id: 762 },
            { name: "Lucky Enh", id: 763 },
            { name: "Spellbreaker Enh", id: 764 },
            { name: "Wizard Enh", id: 765 },
            { name: "Hybrid Enh", id: 766 },
            { name: "Thief Enh", id: 767 },
            { name: "Fighter Enh", id: 768 }
        ];
        addItemRow(
            "Lvl 50+ Enhancements",
            "Browse and load level 50+ normal enhancement shops.",
            "button",
            "Open Shop",
            false,
            function():Void {
                close();
                ApiPrompts.showEnhancementPrompt(_overlay, "Lvl 50+ Enhancements", lvl50Shops, false);
            }
        );

        // 4. Awe Enhancements
        var aweShops = [
            { name: "Fighter Awe", id: 635 },
            { name: "Wizard Awe", id: 636 },
            { name: "Thief Awe", id: 637 },
            { name: "Healer Awe", id: 638 },
            { name: "Lucky Awe", id: 639 },
            { name: "Hybrid Awe", id: 633 }
        ];
        addItemRow(
            "Awe Enhancements",
            "Browse and load Blade of Awe enhancement shops.",
            "button",
            "Open Shop",
            false,
            function():Void {
                close();
                ApiPrompts.showEnhancementPrompt(_overlay, "Awe Enhancements", aweShops, false);
            }
        );

        // 5. Forge Enhancements
        var forgeShops = [
            { name: "Weapon Enh", id: 2142 },
            { name: "Cape Enh", id: 2143 },
            { name: "Helmet Enh", id: 2164 }
        ];
        addItemRow(
            "Forge Enhancements",
            "Browse and load Forge enhancement shops (auto-joins /forge).",
            "button",
            "Open Shop",
            false,
            function():Void {
                close();
                ApiPrompts.showEnhancementPrompt(_overlay, "Forge Enhancements", forgeShops, true);
            }
        );
    }

    private function renderHudTab():Void {
        addInfoBanner("Configure floating on-screen HUD buttons. Each button can be toggled on or off and freely dragged anywhere on your screen. Positions are saved automatically.");

        addSectionHeader("Combat & Scripts");

        // 1. HUD: Smart Combat Button
        addItemRow(
            "HUD: Smart Combat Button",
            "Places an on-screen toggle button with live ON/OFF indicator to enable/disable Smart Combat directly.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = ApiHudManager.isButtonEnabled("smart_combat");
                var next = !cur;
                ApiHudManager.setButtonEnabled("smart_combat", next);
                ApiNotificationManager.notify("HUD Smart Combat: " + (next ? "Visible" : "Hidden"));
            },
            function():Bool {
                return ApiHudManager.isButtonEnabled("smart_combat");
            }
        );

        // 2. HUD: Script Runner Button
        addItemRow(
            "HUD: Script Runner Button",
            "Places an on-screen Start/Stop button to quickly control running scripts without opening the menu.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = ApiHudManager.isButtonEnabled("script_runner");
                var next = !cur;
                ApiHudManager.setButtonEnabled("script_runner", next);
                ApiNotificationManager.notify("HUD Script Runner: " + (next ? "Visible" : "Hidden"));
            },
            function():Bool {
                return ApiHudManager.isButtonEnabled("script_runner");
            }
        );

        addSectionHeader("Gear & Loot");

        // 3. HUD: Smart Enhance Button
        addItemRow(
            "HUD: Smart Enhance Button",
            "Places a 1-tap quick enhancement button on screen to enhance equipped gear for your active class.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = ApiHudManager.isButtonEnabled("smart_enhance");
                var next = !cur;
                ApiHudManager.setButtonEnabled("smart_enhance", next);
                ApiNotificationManager.notify("HUD Smart Enhance: " + (next ? "Visible" : "Hidden"));
            },
            function():Bool {
                return ApiHudManager.isButtonEnabled("smart_enhance");
            }
        );

        // 4. HUD: Infinite Range Button
        addItemRow(
            "HUD: Infinite Range Button",
            "Places an on-screen toggle button to toggle Infinite Range attack capabilities on the fly.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = ApiHudManager.isButtonEnabled("infinite_range");
                var next = !cur;
                ApiHudManager.setButtonEnabled("infinite_range", next);
                ApiNotificationManager.notify("HUD Infinite Range: " + (next ? "Visible" : "Hidden"));
            },
            function():Bool {
                return ApiHudManager.isButtonEnabled("infinite_range");
            }
        );

        // 5. HUD: Bank Button
        addItemRow(
            "HUD: Bank Button",
            "Places an on-screen button to open or close your bank storage at any time with a single tap.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = ApiHudManager.isButtonEnabled("toggle_bank");
                var next = !cur;
                ApiHudManager.setButtonEnabled("toggle_bank", next);
                ApiNotificationManager.notify("HUD Bank: " + (next ? "Visible" : "Hidden"));
            },
            function():Bool {
                return ApiHudManager.isButtonEnabled("toggle_bank");
            }
        );

        // 6. HUD: Accept Loot Button
        addItemRow(
            "HUD: Accept Loot Button",
            "Places an on-screen toggle button to toggle automatic loot drop pickup.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = ApiHudManager.isButtonEnabled("accept_loot");
                var next = !cur;
                ApiHudManager.setButtonEnabled("accept_loot", next);
                ApiNotificationManager.notify("HUD Accept Loot: " + (next ? "Visible" : "Hidden"));
            },
            function():Bool {
                return ApiHudManager.isButtonEnabled("accept_loot");
            }
        );

        addSectionHeader("Layout Controls");

        // 7. Reset HUD Button Positions
        addItemRow(
            "Reset HUD Button Positions",
            "Resets all on-screen draggable HUD buttons and the floating Menu button to default layout.",
            "button",
            "Reset",
            false,
            function():Void {
                ApiHudManager.resetAllPositions();
                ApiNotificationManager.notify("HUD button positions reset to defaults!");
            }
        );
    }

    private function renderApiSettingsTab():Void {
        addSectionHeader("Combat & Movement");

        // 1. Infinite Range
        addItemRow(
            "Infinite Range",
            "Attack and use skills across the entire screen without range limits.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool("api_infinite_range", false);
                var next = !cur;
                HelperSetting.setBool("api_infinite_range", next);
                if (Api.combat != null) {
                    Api.combat.infiniteRange = next;
                    if (next) Api.combat.applyInfiniteRange();
                }
                ApiNotificationManager.notify("Infinite Range: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.combat != null) ? Api.combat.infiniteRange : HelperSetting.getBool("api_infinite_range", false);
            }
        );

        // 2. Death Spawn
        addItemRow(
            "Death Spawn (Same Room)",
            "Automatically sets your respawn point to your current room so you never walk back on death.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool("api_death_spawn", false);
                var next = !cur;
                HelperSetting.setBool("api_death_spawn", next);
                if (Api.map != null) Api.map.autoDeathSpawn = next;
                ApiNotificationManager.notify("Death Spawn: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.map != null) ? Api.map.autoDeathSpawn : HelperSetting.getBool("api_death_spawn", false);
            }
        );

        // 3. Skip Cutscenes
        addItemRow(
            "Skip Cutscenes",
            "Automatically cancel cutscene animations whenever they appear.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool("api_skip_cutscenes", false);
                var next = !cur;
                HelperSetting.setBool("api_skip_cutscenes", next);
                if (Api.map != null) Api.map.skipCutscenes = next;
                ApiNotificationManager.notify("Skip Cutscenes: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.map != null) ? Api.map.skipCutscenes : HelperSetting.getBool("api_skip_cutscenes", false);
            }
        );

        // 4. Private Rooms
        addItemRow(
            "Private Rooms",
            "Automatically join private rooms (e.g. map-100000). Turn off to join public rooms.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool("api_private_rooms", true);
                var next = !cur;
                HelperSetting.setBool("api_private_rooms", next);
                if (Api.map != null) Api.map.usePrivateRoom = next;
                ApiNotificationManager.notify("Private Rooms: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.map != null) ? Api.map.usePrivateRoom : HelperSetting.getBool("api_private_rooms", true);
            }
        );

        addSectionHeader("Loot & Inventory");

        // 5. Accept All Loot
        addItemRow(
            "Accept All Loot",
            "Automatically accept and pick up all dropped items.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool("api_accept_loot", false);
                var next = !cur;
                HelperSetting.setBool("api_accept_loot", next);
                if (Api.drop != null) {
                    Api.drop.acceptAll = next;
                    if (next) {
                        Api.drop.scanScreenDrops();
                        Api.drop.acceptAllDrops();
                    }
                }
                ApiNotificationManager.notify("Accept All Loot: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.drop != null) ? Api.drop.acceptAll : HelperSetting.getBool("api_accept_loot", false);
            }
        );

        // 6. Accept AC Drops
        addItemRow(
            "Accept AC Drops",
            "Automatically accept all AC-tagged (free storage) items.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool("api_accept_ac_drops", false);
                var next = !cur;
                HelperSetting.setBool("api_accept_ac_drops", next);
                if (Api.drop != null) {
                    Api.drop.acceptACs = next;
                    if (next) {
                        Api.drop.scanScreenDrops();
                        Api.drop.acceptACDrops();
                    }
                }
                ApiNotificationManager.notify("Accept AC Drops: " + (next ? "Enabled" : "Disabled"));
            },
            function():Bool {
                return (Api.drop != null) ? Api.drop.acceptACs : HelperSetting.getBool("api_accept_ac_drops", false);
            }
        );

        // 7. Manage Blacklist
        addItemRow(
            "Manage Blacklist",
            "Add or remove items from the blacklist. Blacklisted items are never looted and can be mass-sold.",
            "button",
            "Manage",
            false,
            function():Void {
                close();
                ApiPrompts.showBlacklistPrompt(_overlay);
            }
        );

        // 8. Sell Blacklisted Items
        addItemRow(
            "Sell Blacklisted Items",
            "Sell all unequipped inventory items that are on your blacklist.",
            "button",
            "Sell",
            false,
            function():Void {
                if (Api.blacklist != null) {
                    Api.blacklist.sellBlacklist();
                    ApiNotificationManager.notify("Selling blacklisted items...");
                }
            }
        );

        addSectionHeader("Game Utilities");

        // 9. Toggle Bank
        addItemRow(
            "Open / Close Bank",
            "Open or close your bank storage from anywhere without needing a bank pet.",
            "button",
            "Toggle Bank",
            false,
            function():Void {
                if (Api.inventory != null) Api.inventory.toggleBank();
            }
        );

        // 10. Load Shop by ID
        addItemRow(
            "Load Shop by ID",
            "Load any game shop directly by entering its numeric Shop ID.",
            "button",
            "Load Shop",
            false,
            function():Void {
                close();
                ApiPrompts.showShopPrompt(_overlay);
            }
        );
    }

    // =========================================================================
    // CLIENT SETTINGS TAB CONTENTS
    // =========================================================================

    private function getPocket():Dynamic {
        if (_pocket != null) return _pocket;
        return _overlay != null ? _overlay.pocket : null;
    }

    private function getGameUI(pkt:Dynamic):Dynamic {
        if (pkt != null && pkt.gameUI != null) return pkt.gameUI;
        var pocket = getPocket();
        return pocket != null ? pocket.gameUI : null;
    }

    private function getStage():flash.display.Stage {
        if (this.stage != null) return this.stage;
        if (_overlay != null && _overlay.stage != null) return _overlay.stage;
        var pkt:Dynamic = getPocket();
        if (pkt != null) {
            if (pkt.game != null && pkt.game.stage != null) return pkt.game.stage;
            if (pkt.stage != null) return pkt.stage;
        }
        return null;
    }

    private function renderGeneralTab():Void {
        addSectionHeader("Display & Engine");

        var fpsValues = [24, 30, 60, 75, 120];
        addItemRow(
            "Target Frame Rate",
            "Set the maximum game rendering frame rate (FPS). Higher FPS produces smoother gameplay.",
            "cycle",
            "",
            false,
            function():Void {
                var curIdx = HelperSetting.getFrameRateIndex();
                var nextIdx = (curIdx + 1) % fpsValues.length;
                HelperSetting.setInt(HelperSetting.OPTION_FPS, nextIdx);
                var fps = HelperSetting.applyFrameRate(getStage());
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_fps = fps;
            },
            null,
            function():String {
                return fpsValues[HelperSetting.getFrameRateIndex()] + " FPS";
            }
        );

        var orientations = ["Landscape", "Portrait", "Landscape Left", "Landscape Right", "Portrait Flipped"];
        addItemRow(
            "Screen Orientation",
            "Controls device orientation lock for mobile and tablet devices.",
            "cycle",
            "",
            false,
            function():Void {
                var curIdx = HelperSetting.getOrientationIndex();
                var nextIdx = (curIdx + 1) % orientations.length;
                HelperSetting.setInt(HelperSetting.OPTION_LOCK_ORIENTATION, nextIdx);
                HelperSetting.applyOrientation(getStage());
            },
            null,
            function():String {
                return orientations[HelperSetting.getOrientationIndex()];
            }
        );

        // 3. Maintain Aspect Ratio
        addItemRow(
            "Maintain Aspect Ratio",
            "Keep classic 96:55 proportions with letterboxing when resizing window instead of stretching.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_RESOLUTION_LETTERBOX, true);
                HelperSetting.setBool(HelperSetting.OPTION_RESOLUTION_LETTERBOX, !cur);
                controller.ViewportController.instance.apply();
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_RESOLUTION_LETTERBOX, true);
            }
        );

        var languages = ["English", "Português", "Tagalog", "Español", "Bahasa Indonesia", "Cebuano"];
        var langCodes = ["en", "pt", "tl", "es", "id", "ceb"];
        addItemRow(
            "Quest Language",
            "Translate quest text.",
            "cycle",
            "",
            false,
            function():Void {
                var curIdx = HelperSetting.getInt(HelperSetting.OPTION_LANGUAGE, 0);
                if (curIdx < 0 || curIdx >= languages.length) curIdx = 0;
                var nextIdx = (curIdx + 1) % languages.length;
                HelperSetting.setInt(HelperSetting.OPTION_LANGUAGE, nextIdx);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_language = langCodes[nextIdx];
            },
            null,
            function():String {
                var curIdx = HelperSetting.getInt(HelperSetting.OPTION_LANGUAGE, 0);
                if (curIdx < 0 || curIdx >= languages.length) curIdx = 0;
                return languages[curIdx];
            }
        );

    }

    private function renderSettingsTab():Void {
        addSectionHeader("Asset Cache");

        addItemRow(
            "Persistent SWF Caching",
            "Cache weapons, armors, and monsters locally in NVMe/SSD storage. Eliminates re-downloading and cuts map transition lag.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SWF_CACHE, true);
                HelperSetting.setBool(HelperSetting.OPTION_SWF_CACHE, !cur);
                SWFCache.setEnabled(!cur);
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SWF_CACHE, true);
            }
        );

        addItemRow(
            "Clear Local SWF Cache",
            "Delete all cached weapon, armor, and monster SWF assets stored on disk.",
            "button",
            "Clear (" + SWFCache.getDiskSizeFormatted() + ")",
            false,
            function():Void {
                SWFCache.clear();
                ApiNotificationManager.notify("SWF disk and RAM cache cleared!");
                switchTab(_currentTab);
            }
        );

        addItemRow(
            "Hide Pocket Overlay",
            "Temporarily hide the Pocket UI button and overlay elements from the screen.",
            "button",
            "Hide",
            false,
            function():Void {
                close();
                var pkt:Dynamic = getPocket();
                if (pkt != null) {
                    if (pkt.gameUI != null && pkt.gameUI.parent != null) pkt.gameUI.parent.removeChild(pkt.gameUI);
                    if (pkt.overlay != null && pkt.overlay.parent != null) pkt.overlay.parent.removeChild(pkt.overlay);
                }
            }
        );
    }

    private function renderGameplayTab():Void {
        addSectionHeader("Game Mechanics");

        // 1. Show Skill Tooltips
        addItemRow(
            "Show Skill Tooltips",
            "Display ability descriptions, damage stats, and mana costs when hovering over skills.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SKILL_TOOLTIPS, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SKILL_TOOLTIPS, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_skill_tooltips = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SKILL_TOOLTIPS, true);
            }
        );

        // 2. Skip Cutscenes
        addItemRow(
            "Skip Cutscenes",
            "Automatically skip and fast-forward map cutscenes during gameplay and quests.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_DISABLE_CUTSCENES, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_DISABLE_CUTSCENES, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_disable_cutscenes = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_DISABLE_CUTSCENES, false);
            }
        );

        // 3. Slow Walk
        addItemRow(
            "Analog Joystick Slow Walk",
            "Move slower when tilting the joystick lightly, and at full run speed when pushed further.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SLOW_WALK, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SLOW_WALK, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_slow_walk = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SLOW_WALK, false);
            }
        );

        addSectionHeader("Inventory & Bags");

        addItemRow(
            "Inventory Pagination",
            "Show page controls in inventory, bank, and house storage.",
            "toggle",
            "",
            false,
            function():Void {
                var next = !HelperSetting.getBool(HelperSetting.OPTION_PAGINATION, true);
                HelperSetting.setBool(HelperSetting.OPTION_PAGINATION, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_pagination = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_PAGINATION, true);
            }
        );

        addItemRow(
            "Equipped Items On Top",
            "Keep equipped items at the top of inventory and bank lists.",
            "toggle",
            "",
            false,
            function():Void {
                var next = !HelperSetting.getBool(HelperSetting.OPTION_EQUIPPED_ON_TOP, true);
                HelperSetting.setBool(HelperSetting.OPTION_EQUIPPED_ON_TOP, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_equipped_on_top = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_EQUIPPED_ON_TOP, true);
            }
        );

        addSectionHeader("Skill & Aura Visual Effects");

        // 4. Other Players Skills
        addItemRow(
            "Player Skill Animations",
            "Show skill cast animations from other players in the room.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_PLAYER_ANIMATION_SKILL, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_PLAYER_ANIMATION_SKILL, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_player_animation_skill = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_PLAYER_ANIMATION_SKILL, true);
            }
        );

        // 5. Other Players Auras
        addItemRow(
            "Player Aura Animations",
            "Show aura and buff visual rings from other players in the room.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_PLAYER_ANIMATION_AURA, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_PLAYER_ANIMATION_AURA, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_player_animation_aura = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_PLAYER_ANIMATION_AURA, true);
            }
        );

        // 6. Monster Skills
        addItemRow(
            "Monster Skill Animations",
            "Show monster attack spell animations.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_MONSTER_ANIMATION_SKILL, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_MONSTER_ANIMATION_SKILL, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_monster_animation_skill = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_MONSTER_ANIMATION_SKILL, true);
            }
        );

        // 7. Monster Auras
        addItemRow(
            "Monster Aura Animations",
            "Show monster and boss aura effect rings.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_MONSTER_ANIMATION_AURA, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_MONSTER_ANIMATION_AURA, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_monster_animation_aura = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_MONSTER_ANIMATION_AURA, true);
            }
        );

        // 8. Self Skills
        addItemRow(
            "Self Skill Animations",
            "Show your own character's skill cast animations.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SELF_ANIMATION_SKILL, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SELF_ANIMATION_SKILL, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_self_animation_skill = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SELF_ANIMATION_SKILL, true);
            }
        );

        // 9. Self Auras
        addItemRow(
            "Self Aura Animations",
            "Show your own character's aura and buff visual rings.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SELF_ANIMATION_AURA, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SELF_ANIMATION_AURA, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_self_animation_aura = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SELF_ANIMATION_AURA, true);
            }
        );
    }

    private function renderGraphicsTab():Void {
        addSectionHeader("Visual Optimization & Filters");

        // 1. Disable Filters
        addItemRow(
            "Disable Glow & Shadow Filters",
            "Removes all software drop-shadow and glow filters from characters and maps to maximize FPS.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_FILTER, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_FILTER, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_filter_off = next;
                ApiNotificationManager.notify("Filter setting saved. Join a new map or relog to apply it.");
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_FILTER, false);
            }
        );

        addItemRow(
            "Strip Embedded SWF Sounds",
            "Removes embedded sound tags from SWFs as they load. Relog or reload affected assets to apply.",
            "toggle",
            "",
            false,
            function():Void {
                var next = !HelperSetting.getBool(HelperSetting.OPTION_SOUND, false);
                HelperSetting.setBool(HelperSetting.OPTION_SOUND, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_sound_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SOUND, false);
            }
        );

        addSectionHeader("Freeze Entity & Gear Animations");

        // 2. Monster Animations
        addItemRow(
            "Freeze Monster Animations",
            "Freezes monster timeline animations to drastically improve frame rates in crowded rooms.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MONSTER, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_MONSTER, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_monster_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MONSTER, false);
            }
        );

        // 3. Helm Animations
        addItemRow(
            "Freeze Helm Animations",
            "Freezes helmet particles, animated visors, and glowing eyes.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_HELM, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_HELM, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_helm_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_HELM, false);
            }
        );

        // 4. Armor Animations
        addItemRow(
            "Freeze Armor Animations",
            "Freezes armor glow pulses and moving cloth/chain effects.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_ARMOR, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_ARMOR, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_armor_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_ARMOR, false);
            }
        );

        // 5. Cape Animations
        addItemRow(
            "Freeze Cape & Wing Animations",
            "Freezes flowing cape physics, animated wings, and back items.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_CAPE, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_CAPE, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_cape_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_CAPE, false);
            }
        );

        // 6. Hair Animations
        addItemRow(
            "Freeze Hair Animations",
            "Freezes animated hairstyles and braids.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_HAIR, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_HAIR, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_hair_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_HAIR, false);
            }
        );

        // 7. Weapon Animations
        addItemRow(
            "Freeze Weapon Animations",
            "Freezes revolving weapon blades, sparks, and electrical glows.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_WEAPON, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_WEAPON, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_weapon_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_WEAPON, false);
            }
        );

        // 8. Pet Animations
        addItemRow(
            "Freeze Pet & Minion Animations",
            "Freezes pet idle movements and hovering minions.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_PET, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_PET, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_pet_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_PET, false);
            }
        );

        // 9. Ground / Misc Animations
        addItemRow(
            "Freeze Ground & Misc Animations",
            "Freezes ground runes, floating orbs, and miscellaneous accessories.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MISC, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_MISC, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_misc_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MISC, false);
            }
        );

        addItemRow(
            "Freeze Map Animations",
            "Keeps map SWFs on their first frame when loaded. Join a new map or relog to apply.",
            "toggle",
            "",
            false,
            function():Void {
                var next = !HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MAP, false);
                HelperSetting.setBool(HelperSetting.OPTION_ANIMATION_MAP, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_map_off = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MAP, false);
            }
        );
    }

    private function renderControlsTab():Void {
        addSectionHeader("Touch & Mobile Input");

        // 1. Show Virtual Joystick
        addItemRow(
            "Virtual Analog Joystick",
            "Display an on-screen analog joystick for touch/mouse movement control.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    if (next) pkt.gameUI.showJoystickMouseSimulator();
                    else pkt.gameUI.hideJoystickMouseSimulator();
                }
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE, true);
            }
        );

        // 2. Show Arrow Keys (Keyboard walk)
        addItemRow(
            "Virtual Arrow Keys",
            "Display on-screen directional arrow pads for WASD movement.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SHOW_JOYSTICK_KEYBOARD, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SHOW_JOYSTICK_KEYBOARD, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    if (next) pkt.gameUI.showJoystickKeyboardSimulator();
                    else pkt.gameUI.hideJoystickKeyboardSimulator();
                }
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SHOW_JOYSTICK_KEYBOARD, false);
            }
        );

        // 3. Show Skill Bar
        addItemRow(
            "On-Screen Skill Bar",
            "Display floating touch buttons for Skills 1-5 and Auto-Attack.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SHOW_SKILL_BAR, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SHOW_SKILL_BAR, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    if (next) pkt.gameUI.showSkillBar();
                    else pkt.gameUI.hideSkillBar();
                }
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SHOW_SKILL_BAR, true);
            }
        );

        addItemRow(
            "Infinity Skill Bar Style",
            "Use numbered teal frames to distinguish each skill on the action bar.",
            "toggle",
            "",
            false,
            function():Void {
                var current = HelperSetting.getInt(HelperSetting.OPTION_SKILL_BAR_STYLE, HelperSetting.SKILL_BAR_STYLE_CLASSIC);
                var next = current == HelperSetting.SKILL_BAR_STYLE_INFINITY
                    ? HelperSetting.SKILL_BAR_STYLE_CLASSIC
                    : HelperSetting.SKILL_BAR_STYLE_INFINITY;
                HelperSetting.setInt(HelperSetting.OPTION_SKILL_BAR_STYLE, next);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    pkt.gameUI.applySkillBarStyle();
                }
            },
            function():Bool {
                return HelperSetting.getInt(HelperSetting.OPTION_SKILL_BAR_STYLE, HelperSetting.SKILL_BAR_STYLE_CLASSIC)
                    == HelperSetting.SKILL_BAR_STYLE_INFINITY;
            }
        );

        // 4. Joystick Dash
        addItemRow(
            "Joystick Dash Ability",
            "Double-flick the joystick to dash in the movement direction (requires stamina).",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_JOYSTICK_DASH, false);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_JOYSTICK_DASH, next);
                MouseWalkSimulatorController.IS_DASHING_ON = next;
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_JOYSTICK_DASH, false);
            }
        );

        addSectionHeader("Layout Customization");

        // 5. Snap to Grid
        addItemRow(
            "Snap To Grid",
            "Snap UI elements to grid alignment lines when dragging in edit mode.",
            "toggle",
            "",
            false,
            function():Void {
                var cur = HelperSetting.getBool(HelperSetting.OPTION_SNAP_TO_GRID, true);
                var next = !cur;
                HelperSetting.setBool(HelperSetting.OPTION_SNAP_TO_GRID, next);
            },
            function():Bool {
                return HelperSetting.getBool(HelperSetting.OPTION_SNAP_TO_GRID, true);
            }
        );

        // 6. Edit Layout
        addItemRow(
            "Edit UI Layout Mode",
            "Enter draggable layout edit mode to move and resize joystick and skill bars.",
            "button",
            "Edit",
            true,
            function():Void {
                var pkt:Dynamic = getPocket();
                if (!isInGame(pkt)) {
                    ApiNotificationManager.notify("Layout editor is only available while in-game.");
                    return;
                }
                close();
                var gameUI:Dynamic = getGameUI(pkt);
                if (pkt != null && pkt.gameCore != null) {
                    pkt.gameCore.setWorldFilters([util.Helper.GRAYSCALE]);
                }
                if (gameUI != null) {
                    gameUI.showEditLayout();
                }
            }
        );

        // 7. Reset Layout
        addItemRow(
            "Reset Controls Layout",
            "Restore default positions and sizes for on-screen joystick and controls.",
            "button",
            "Reset",
            false,
            function():Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    pkt.gameUI.resetLayout();
                }
                ApiNotificationManager.notify("Controls layout restored to default!");
            }
        );
    }

    private function isInGame(?pkt:Dynamic):Bool {
        if (pkt == null) pkt = getPocket();
        return pkt != null && pkt.game != null && pkt.gameUI != null;
    }

    private function renderShortcutsTab():Void {
        addSectionHeader("In-Game Shortcuts");

        // 1. Add Shortcut Button
        addItemRow(
            "Add Quick Shortcut Button",
            "Place an on-screen shortcut action button (Auto Attack, Skills, Inventory, Bank, Travel, etc.).",
            "button",
            "Add",
            true,
            function():Void {
                var pkt:Dynamic = getPocket();
                if (!isInGame(pkt)) {
                    ApiNotificationManager.notify("Shortcuts are only available while in-game.");
                    return;
                }
                var stg = getStage();
                if (stg == null) return;
                close();
                var picker:DisplayObject = stg.getChildByName("ShortcutPicker");
                if (picker != null && picker.parent != null) {
                    picker.parent.removeChild(picker);
                }
                stg.addChild(new ShortcutPicker(pkt, function(actionName:String):Void {
                    if (pkt.gameUI != null) pkt.gameUI.addShortcutButton(actionName);
                }));
            }
        );

        // 2. Remove Shortcut Button
        addItemRow(
            "Remove Shortcut Button",
            "Select an on-screen shortcut button to remove from the display.",
            "button",
            "Remove",
            false,
            function():Void {
                var pkt:Dynamic = getPocket();
                if (!isInGame(pkt)) {
                    ApiNotificationManager.notify("Shortcuts are only available while in-game.");
                    return;
                }
                var stg = getStage();
                if (stg == null) return;
                close();
                var picker:DisplayObject = stg.getChildByName("ShortcutPicker");
                if (picker != null && picker.parent != null) {
                    picker.parent.removeChild(picker);
                }
                stg.addChild(new ShortcutPicker(pkt, function(actionName:String):Void {
                    if (pkt.gameUI != null) pkt.gameUI.removeShortcutButton(actionName);
                }));
            }
        );

        // 3. Reset Shortcuts
        addItemRow(
            "Reset All Shortcuts",
            "Remove all custom shortcut buttons and restore default layout.",
            "button",
            "Reset",
            false,
            function():Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    pkt.gameUI.resetShortcuts();
                }
                ApiNotificationManager.notify("Shortcuts reset to default!");
            }
        );
    }
}
#else
class ApiDashboardModal {
    public static function show(overlay:Dynamic, pocket:Dynamic = null):Void {}
    public static function close():Void {}
}
#end
