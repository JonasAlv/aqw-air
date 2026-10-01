package ui.util;

import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

/**
 * Modern vector Pagination control for Inventory, Bank, and MergeShop.
 *
 * Visually matches the AQW UI style:
 *  - Left/Right square rounded-corner buttons with crimson red glowing borders
 *  - Pure vector-drawn chevrons (< / >) - zero font dependencies, never missing glyphs
 *  - Clean centered "Page X of Y" label
 *  - Transparent row background (fits seamlessly inside listMask)
 */
class Pagination extends MovieClip {

    public static inline var ROW_WIDTH:Float   = 264.0;
    public static inline var ROW_HEIGHT:Float  = 34.0;
    public static inline var BTN_SIZE:Float    = 32.0;
    public static inline var BTN_RADIUS:Float  = 6.0;

    // Colours
    private static inline var C_RED_BORDER:Int     = 0xCC1A1A;
    private static inline var C_RED_HOVER:Int      = 0xFF3333;
    private static inline var C_RED_PRESS:Int      = 0x990E0E;
    private static inline var C_DIS_BORDER:Int     = 0x442222;

    private static inline var C_BG_TOP:Int         = 0x221414;
    private static inline var C_BG_BOT:Int         = 0x0E0808;

    private static inline var C_TEXT_WHITE:Int     = 0xFFFFFF;
    private static inline var C_TEXT_DISABLED:Int  = 0x666666;

    // Public API expected by callers / game
    public var btnPrev:Sprite;
    public var btnNext:Sprite;
    public var tPage:TextField;
    public var fData:Dynamic;
    public var sel:Dynamic;

    private var _prevEnabled:Bool = false;
    private var _nextEnabled:Bool = false;

    public function new() {
        super();
        _initUI();
    }

    private function _initUI():Void {
        // Prev Button (<) on the left
        btnPrev = new Sprite();
        btnPrev.x = 4.0;
        btnPrev.y = 1.0;
        btnPrev.buttonMode = true;
        btnPrev.useHandCursor = true;
        addChild(btnPrev);

        btnPrev.addEventListener(MouseEvent.ROLL_OVER, _onPrevOver, false, 0, true);
        btnPrev.addEventListener(MouseEvent.ROLL_OUT,  _onPrevOut,  false, 0, true);

        // Next Button (>) on the right
        btnNext = new Sprite();
        btnNext.x = ROW_WIDTH - BTN_SIZE - 4.0;
        btnNext.y = 1.0;
        btnNext.buttonMode = true;
        btnNext.useHandCursor = true;
        addChild(btnNext);

        btnNext.addEventListener(MouseEvent.ROLL_OVER, _onNextOver, false, 0, true);
        btnNext.addEventListener(MouseEvent.ROLL_OUT,  _onNextOut,  false, 0, true);

        // Center "Page X of Y" TextField
        tPage = new TextField();
        tPage.defaultTextFormat = new TextFormat("_sans", 13, C_TEXT_WHITE, true, false, false, null, null, TextFormatAlign.CENTER);
        tPage.selectable   = false;
        tPage.mouseEnabled = false;
        tPage.autoSize     = TextFieldAutoSize.NONE;
        tPage.width        = ROW_WIDTH - (BTN_SIZE * 2) - 16.0;
        tPage.height       = 24.0;
        tPage.x            = BTN_SIZE + 8.0;
        tPage.y            = (BTN_SIZE - 20.0) / 2.0;
        tPage.text         = "Page 1 of 1";
        addChild(tPage);

        // Initial draw in disabled state
        _drawButton(btnPrev, false, false, false);
        _drawButton(btnNext, true, false, false);
    }

    private function _drawButton(btn:Sprite, isNext:Bool, enabled:Bool, hovered:Bool):Void {
        var g:Graphics = btn.graphics;
        g.clear();

        var borderColor:Int = enabled ? (hovered ? C_RED_HOVER : C_RED_BORDER) : C_DIS_BORDER;
        var borderAlpha:Float = enabled ? 0.95 : 0.35;
        var bgAlpha:Float = enabled ? (hovered ? 0.95 : 0.85) : 0.5;

        // Subtle gradient background
        var m:Matrix = new Matrix();
        m.createGradientBox(BTN_SIZE, BTN_SIZE, Math.PI / 2, 0, 0);
        g.beginGradientFill(
            flash.display.GradientType.LINEAR,
            [hovered && enabled ? 0x331C1C : C_BG_TOP, C_BG_BOT],
            [bgAlpha, bgAlpha],
            [0, 255],
            m
        );

        // Crimson glowing outer border
        g.lineStyle(enabled ? 1.6 : 1.0, borderColor, borderAlpha, true);
        g.drawRoundRect(0, 0, BTN_SIZE, BTN_SIZE, BTN_RADIUS, BTN_RADIUS);
        g.endFill();

        // Optional inner top highlight for 3D bevel effect
        if (enabled) {
            g.lineStyle(1.0, 0xFF6666, hovered ? 0.3 : 0.15);
            g.moveTo(BTN_RADIUS, 1.0);
            g.lineTo(BTN_SIZE - BTN_RADIUS, 1.0);
        }

        // Pure vector chevron (< or >) — 100% vector drawn, zero fonts, zero missing glyphs
        var chevronColor:Int = enabled ? C_TEXT_WHITE : C_TEXT_DISABLED;
        var chevronAlpha:Float = enabled ? 1.0 : 0.35;
        g.lineStyle(2.5, chevronColor, chevronAlpha, true, flash.display.LineScaleMode.NORMAL, flash.display.CapsStyle.ROUND, flash.display.JointStyle.ROUND);

        var midY:Float = BTN_SIZE / 2.0;
        if (!isNext) {
            // Left Chevron (<)
            var tipX:Float = (BTN_SIZE / 2.0) - 3.0;
            var armX:Float = (BTN_SIZE / 2.0) + 3.0;
            g.moveTo(armX, midY - 6.0);
            g.lineTo(tipX, midY);
            g.lineTo(armX, midY + 6.0);
        } else {
            // Right Chevron (>)
            var tipX:Float = (BTN_SIZE / 2.0) + 3.0;
            var armX:Float = (BTN_SIZE / 2.0) - 3.0;
            g.moveTo(armX, midY - 6.0);
            g.lineTo(tipX, midY);
            g.lineTo(armX, midY + 6.0);
        }
    }

    private function _onPrevOver(e:MouseEvent):Void {
        if (_prevEnabled) _drawButton(btnPrev, false, true, true);
    }

    private function _onPrevOut(e:MouseEvent):Void {
        _drawButton(btnPrev, false, _prevEnabled, false);
    }

    private function _onNextOver(e:MouseEvent):Void {
        if (_nextEnabled) _drawButton(btnNext, true, true, true);
    }

    private function _onNextOut(e:MouseEvent):Void {
        _drawButton(btnNext, true, _nextEnabled, false);
    }

    public function fOpen(data:Dynamic):Void {
        this.fData = data;
        refresh();
    }

    public function update(data:Dynamic):Void {
        this.fData = data;
        refresh();
    }

    public function refresh():Void {
        if (fData == null) return;

        var page:Int      = Std.int(fData.page);
        var total:Int     = Std.int(fData.totalPages);
        _prevEnabled      = (fData.canPrev == true);
        _nextEnabled      = (fData.canNext == true);

        if (tPage != null) {
            tPage.text = "Page " + page + " of " + total;
        }

        // Prev button state
        btnPrev.mouseEnabled  = _prevEnabled;
        btnPrev.useHandCursor = _prevEnabled;
        btnPrev.alpha         = _prevEnabled ? 1.0 : 0.45;
        _drawButton(btnPrev, false, _prevEnabled, false);

        // Next button state
        btnNext.mouseEnabled  = _nextEnabled;
        btnNext.useHandCursor = _nextEnabled;
        btnNext.alpha         = _nextEnabled ? 1.0 : 0.45;
        _drawButton(btnNext, true, _nextEnabled, false);
    }

    public function fClose():Void {
        fData = null;
        if (parent != null) {
            parent.removeChild(this);
        }
    }
}
