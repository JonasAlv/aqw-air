package game;

import flash.display.Sprite;

@:native("game.Network")
class Network {
    private var pocket:Dynamic;

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
        try {
            if (this.pocket != null && this.pocket.game != null && this.pocket.game.sfc != null) {
                this.pocket.game.sfc.addEventListener("onExtensionResponse", onExtensionResponseHandler, false, 0, true);
            }
        } catch (_:Dynamic) {}
    }

    private function onExtensionResponseHandler(event:Dynamic):Void {
        try {
            if (event == null || event.params == null) return;
            switch (event.params.type) {
                case "json":
                    if (event.params.dataObj != null && event.params.dataObj.cmd == "sAct") {
                        sAct();
                    }
                default:
            }
        } catch (_:Dynamic) {}
    }

    private function sAct():Void {
        try {
            if (this.pocket == null || this.pocket.game == null || this.pocket.game.ui == null || this.pocket.game.ui.mcInterface == null) return;
            var actBar:Sprite = cast(this.pocket.game.ui.mcInterface.actBar, Sprite);
            if (actBar == null) return;

            if (this.pocket.gameUI != null) {
                this.pocket.gameUI.registerSkillBarWidgets(actBar);
                this.pocket.gameUI.applySkillBarStyle();
            }
        } catch (_:Dynamic) {}
    }
}
