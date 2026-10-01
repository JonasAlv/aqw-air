package ui.shortcut;

import data.Action;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.text.TextField;

class ShortcutButton extends Sprite {
    public var shortcutBtn:SimpleButton;
    public var shortcutTxt:TextField;

    private var pocket:Dynamic;
    private var actionName:String;

    public function new(pocket:Dynamic, actionName:String) {
        super();
        this.pocket = pocket;
        this.actionName = actionName;

        if (this.shortcutTxt != null) {
            this.shortcutTxt.text = actionName;
            this.shortcutTxt.wordWrap = true;
            this.shortcutTxt.selectable = false;
            this.shortcutTxt.mouseEnabled = false;
            this.shortcutTxt.tabEnabled = false;
        }

        this.mouseChildren = true;
        this.mouseEnabled = false;

        if (this.shortcutBtn != null) {
            try {
                this.shortcutBtn.addEventListener(TouchEvent.TOUCH_TAP, onClick, false, 0, true);
            } catch (e:Dynamic) {}
            this.shortcutBtn.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
        }
    }

    private function onClick(e:Dynamic):Void {
        if (this.pocket == null || this.pocket.game == null) {
            return;
        }

        for (action in ShortcutPicker.ACTIONS) {
            if (action.name == this.actionName) {
                if (action.onClick != null) {
                    action.onClick(this.pocket);
                    return;
                }
                break;
            }
        }

        try {
            this.pocket.game.triggerGameAction(this.actionName);
        } catch (e:Dynamic) {}
    }
}
