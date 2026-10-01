package game;

import flash.events.Event;
import ui.option.Menu;
import ui.option.Option;

class Core {
    private static inline var TICK_DISCORD_RPC:Int = 150;

    private var pocket:Dynamic;
    public var itemPagination:ItemPagination;
    public var itemFavorite:ItemFavorite;

    private var _tickDiscordRPC:Int = 0;
    public var currentFrame:String = "Game";

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
        this.itemPagination = new ItemPagination(this.pocket);
        this.itemFavorite = new ItemFavorite(this.pocket);

        if (this.pocket != null && this.pocket.addEventListener != null) {
            this.pocket.addEventListener(Event.ENTER_FRAME, this.onEnterFrame, false, 0, true);
        }
    }

    public function setWorldFilters(filters:Array<Dynamic>):Void {
        if (this.pocket != null && this.pocket.game != null && this.pocket.game.world != null) {
            try {
                this.pocket.game.world.map.filters = filters;
                this.pocket.game.world.CHARS.filters = filters;
            } catch (e:Dynamic) {}
        }
    }

    /**
     * Called by Game & Pocket
     * @param frame
     */
    public function onFrameChange(frame:String):Void {
        this.currentFrame = frame;

        if (this.pocket != null && this.pocket.overlay != null && this.pocket.overlay.menus != null) {
            var menus:Dynamic = this.pocket.overlay.menus;
            var mLen:Int = untyped menus.length;
            for (i in 0...mLen) {
                var menu:Dynamic = untyped menus[i];
                if (menu != null && menu.options != null) {
                    var opts:Dynamic = menu.options;
                    var oLen:Int = untyped opts.length;
                    for (j in 0...oLen) {
                        var option:Dynamic = untyped opts[j];
                        if (option != null && option.onFrameChange != null) {
                            option.onFrameChange(frame);
                        }
                    }
                }
            }
        }

        if (this.pocket != null && this.pocket.overlay != null && this.pocket.overlay.setOverlayButtonTransform != null) {
            this.pocket.overlay.setOverlayButtonTransform();
        }

        if (this.pocket != null && this.pocket.game != null) {
            try {
                if (this.pocket.overlay != null && this.pocket.overlay.parent == this.pocket.game) {
                    this.pocket.game.setChildIndex(this.pocket.overlay, this.pocket.game.numChildren - 1);
                }
                if (this.pocket.gameUI != null && this.pocket.gameUI.parent == this.pocket.game) {
                    this.pocket.game.setChildIndex(this.pocket.gameUI, this.pocket.game.numChildren - 1);
                }
            } catch (e:Dynamic) {}
        }
    }

    public function onEnterFrame(event:Event):Void {
        if (++_tickDiscordRPC >= TICK_DISCORD_RPC) {
            _tickDiscordRPC = 0;
            if (this.pocket != null && untyped this.pocket.discordRichPresence != null) {
                try {
                    untyped this.pocket.discordRichPresence.refreshPresence();
                } catch (e:Dynamic) {}
            }
        }
    }
}
