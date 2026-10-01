package game;

class Core {
    private var pocket:Dynamic;
    public var itemPagination:ItemPagination;
    public var itemFavorite:ItemFavorite;

    public var currentFrame:String = "Game";

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
        this.itemPagination = new ItemPagination(this.pocket);
        this.itemFavorite = new ItemFavorite(this.pocket);
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
}
