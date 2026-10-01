package ui.util;

import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

/**
 * Pagination bar drawn entirely in vector code.
 * Renders as:  [◄]  Page X of Y  [►]
 *
 * Matches the dark-glass aesthetic of our other modern UI components.
 * Width: 180px  Height: 30px  (same visual footprint as Anthony's FLA version)
 */
class Pagination extends MovieClip {

    // ── Layout constants ──────────────────────────────────────────────────────
    private static inline var W:Float         = 180;   // total width
    private static inline var H:Float         = 30;    // total height
    private static inline var BTN_W:Float     = 30;    // arrow button width
    private static inline var BTN_H:Float     = 30;    // arrow button height
    private static inline var CORNER:Float    = 6;     // rounded-rect radius

    // ── Colours (match ShortcutButton / Joystick dark-glass palette) ──────────
    private static inline var C_BG_TOP:Int    = 0x1A1A2E;
    private static inline var C_BG_BOT:Int    = 0x0D0D1A;
    private static inline var C_BTN_NORM:Int  = 0xCC2200;   // red  (matches AQW arrow style)
    private static inline var C_BTN_HOV:Int   = 0xFF4422;
    private static inline var C_BTN_DIS:Int   = 0x553311;
    private static inline var C_BORDER:Int    = 0x553311;
    private static inline var C_TEXT:Int      = 0xEEEEEE;
    private static inline var ALPHA_DIS:Float = 0.45;

    // ── State ─────────────────────────────────────────────────────────────────
    public var fData:Dynamic;

    private var _prevBtn:Sprite;
    private var _nextBtn:Sprite;
    private var _pageLabel:TextField;

    // ─────────────────────────────────────────────────────────────────────────

    public function new() {
        super();
        _build();
    }

    // ── Build ─────────────────────────────────────────────────────────────────

    private function _build():Void {
        // background bar
        var bg:Shape = new Shape();
        _fillRoundRect(bg.graphics, 0, 0, W, H, CORNER, C_BG_TOP, C_BG_BOT, 0.92);
        bg.graphics.lineStyle(1, C_BORDER, 0.6);
        bg.graphics.drawRoundRect(0, 0, W, H, CORNER, CORNER);
        bg.graphics.endFill();
        addChild(bg);

        // prev button (left side)
        _prevBtn = _makeArrow("◄", 0, 0);
        addChild(_prevBtn);
        _prevBtn.addEventListener(MouseEvent.ROLL_OVER, _onBtnOver, false, 0, true);
        _prevBtn.addEventListener(MouseEvent.ROLL_OUT,  _onBtnOut,  false, 0, true);

        // next button (right side)
        _nextBtn = _makeArrow("►", W - BTN_W, 0);
        addChild(_nextBtn);
        _nextBtn.addEventListener(MouseEvent.ROLL_OVER, _onBtnOver, false, 0, true);
        _nextBtn.addEventListener(MouseEvent.ROLL_OUT,  _onBtnOut,  false, 0, true);

        // page label (centred between the two buttons)
        _pageLabel = new TextField();
        _pageLabel.defaultTextFormat = new TextFormat("_sans", 11, C_TEXT, true, false, false, null, null, TextFormatAlign.CENTER);
        _pageLabel.selectable    = false;
        _pageLabel.mouseEnabled  = false;
        _pageLabel.autoSize      = TextFieldAutoSize.NONE;
        _pageLabel.width         = W - BTN_W * 2;
        _pageLabel.height        = H;
        _pageLabel.x             = BTN_W;
        _pageLabel.y             = 0;
        _pageLabel.text          = "Page 1 of 1";
        addChild(_pageLabel);
        // vertically centre
        _pageLabel.y = (H - _pageLabel.textHeight) / 2 - 1;
    }

    private function _makeArrow(label:String, bx:Float, by:Float):Sprite {
        var sp:Sprite = new Sprite();
        sp.x = bx;
        sp.y = by;
        _drawBtn(sp, C_BTN_NORM);

        // arrow glyph
        var tf:TextField = new TextField();
        tf.defaultTextFormat = new TextFormat("_sans", 14, 0xFFFFFF, true, false, false, null, null, TextFormatAlign.CENTER);
        tf.selectable   = false;
        tf.mouseEnabled = false;
        tf.autoSize     = TextFieldAutoSize.NONE;
        tf.width        = BTN_W;
        tf.height       = BTN_H;
        tf.text         = label;
        tf.y            = (BTN_H - tf.textHeight) / 2 - 2;
        sp.addChild(tf);

        sp.buttonMode   = true;
        sp.useHandCursor = true;
        return sp;
    }

    private function _drawBtn(sp:Sprite, col:Int, ?alpha:Float = 1.0):Void {
        sp.graphics.clear();
        _fillRoundRect(sp.graphics, 0, 0, BTN_W, BTN_H, CORNER, col, col, alpha);
        sp.graphics.lineStyle(1, 0x000000, 0.3);
        sp.graphics.drawRoundRect(0, 0, BTN_W, BTN_H, CORNER, CORNER);
        sp.graphics.endFill();
    }

    private function _fillRoundRect(g:Graphics, x:Float, y:Float, w:Float, h:Float,
                                    r:Float, colTop:Int, colBot:Int, alpha:Float):Void {
        g.beginGradientFill(
            flash.display.GradientType.LINEAR,
            [colTop, colBot],
            [alpha, alpha],
            [0, 255],
            _verticalMatrix(x, y, w, h)
        );
        g.drawRoundRect(x, y, w, h, r, r);
        g.endFill();
    }

    private function _verticalMatrix(x:Float, y:Float, w:Float, h:Float):flash.geom.Matrix {
        var m:flash.geom.Matrix = new flash.geom.Matrix();
        m.createGradientBox(w, h, Math.PI / 2, x, y);
        return m;
    }

    // ── Event handlers ────────────────────────────────────────────────────────

    private function _onBtnOver(e:MouseEvent):Void {
        var sp:Sprite = cast e.currentTarget;
        if (sp.mouseEnabled) _drawBtn(sp, C_BTN_HOV);
    }

    private function _onBtnOut(e:MouseEvent):Void {
        var sp:Sprite = cast e.currentTarget;
        if (sp.mouseEnabled) _drawBtn(sp, C_BTN_NORM);
    }

    // ── Public API (matches Anthony's Pagination.as interface) ────────────────

    /**
     * Called once after the pagination is added to the display list.
     * fData = { page, totalPages, canPrev, canNext, state, lpf }
     */
    public function fOpen(data:Dynamic):Void {
        fData = data;
        _refresh();
    }

    public function update(data:Dynamic):Void {
        fData = data;
        _refresh();
    }

    private function _refresh():Void {
        if (fData == null) return;

        var page:Int       = Std.int(fData.page);
        var total:Int      = Std.int(fData.totalPages);
        var canPrev:Bool   = (fData.canPrev == true);
        var canNext:Bool   = (fData.canNext == true);

        _pageLabel.text = "Page " + page + " of " + total;

        _setButtonState(_prevBtn, canPrev);
        _setButtonState(_nextBtn, canNext);
    }

    private function _setButtonState(sp:Sprite, enabled:Bool):Void {
        sp.mouseEnabled  = enabled;
        sp.useHandCursor = enabled;
        sp.alpha         = enabled ? 1.0 : ALPHA_DIS;
        _drawBtn(sp, enabled ? C_BTN_NORM : C_BTN_DIS);
    }

    public function fClose():Void {
        fData = null;
        if (parent != null) parent.removeChild(this);
    }
}
