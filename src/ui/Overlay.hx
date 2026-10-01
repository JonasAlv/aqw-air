package ui;

import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import ui.api.ApiDashboardModal;
import ui.api.ApiNotificationManager;

class Overlay extends MovieClip {
    public var showPanelBtn:SimpleButton;
    public var hidePanelBtn:SimpleButton;
    public var reportBugBtn:SimpleButton;
    public var updateBtn:SimpleButton;
    public var discordBtn:SimpleButton;

    public var contentMenu:Sprite;
    public var contentOptions:Sprite;

    public var debug:Debug;
    public var notifications:Sprite;

    public var pocket:Dynamic;
    public var menus:Dynamic = null;

    public function getPocket():Dynamic {
        if (this.pocket != null) return this.pocket;
        if (this.parent != null) return this.parent;
        try {
            var g:Dynamic = untyped __global__["Pocket"];
            if (g != null && g.SINGLETON != null) return g.SINGLETON;
        } catch (e:Dynamic) {}
        return null;
    }

    public function new(pocket:Dynamic) {
        super();
        this.pocket = pocket;
        this.debug = new Debug();

        #if flash
        untyped this.addFrameScript(0, initFrame);
        #end

        if (this.pocket != null && this.pocket.addChild != null) {
            this.pocket.addChild(this);
        }

        this.notifications = new Sprite();
        addChild(this.notifications);
    }

    private function initFrame():Void {
        if (this.showPanelBtn != null) {
            this.showPanelBtn.addEventListener(MouseEvent.CLICK, onShowPanel);
        }

        if (this.reportBugBtn != null) this.reportBugBtn.visible = false;
        if (this.updateBtn != null) this.updateBtn.visible = false;
        if (this.discordBtn != null) this.discordBtn.visible = false;

        setOverlayButtonTransform();

        if (this.pocket != null && this.pocket.gameUI != null) {
            this.pocket.gameUI.loadPersistedShortcuts();
        }

        this.visible = true;
        stop();
    }

    public function onShowPanel(?mouseEvent:MouseEvent):Void {
        ApiDashboardModal.show(this, this.pocket);
    }

    public function onHidePanel(?mouseEvent:MouseEvent):Void {
        ApiDashboardModal.close();
    }

    public function notification(message:String):Void {
        ApiNotificationManager.notify(message);
    }

    public function setOverlayButtonTransform():Void {
        if (this.pocket == null || this.pocket.game == null || this.showPanelBtn == null) {
            return;
        }

        var curFrame:String = (this.pocket.gameCore != null) ? this.pocket.gameCore.currentFrame : "";
        switch (curFrame) {
            case "Game":
                this.showPanelBtn.width = this.showPanelBtn.height = 24;
                this.showPanelBtn.x = this.showPanelBtn.y = 2;
            default:
                this.showPanelBtn.width = this.showPanelBtn.height = 37.3;
                this.showPanelBtn.x = 7.1;
                this.showPanelBtn.y = 264.9;
        }
    }
}
