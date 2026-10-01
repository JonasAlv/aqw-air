package game;

import flash.display.MovieClip;
import ui.util.Favorite;
import util.HelperSetting;

class ItemFavorite {
    private var pocket:Dynamic;
    private var favoriteIds:Array<Dynamic>;
    private var favoriteLookup:Map<String, Bool>;
    private var favoriteButton:Favorite;

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
        this.favoriteIds = HelperSetting.getArray(HelperSetting.OPTION_FAVORITE_ITEMS);
        this.favoriteLookup = new Map<String, Bool>();

        for (itemId in this.favoriteIds) {
            this.favoriteLookup.set(Std.string(itemId), true);
        }
    }

    public function isFavorite(itemData:Dynamic):Bool {
        if (itemData == null || itemData.ItemID == null) return false;
        return this.favoriteLookup.exists(Std.string(itemData.ItemID));
    }

    public function toggleFavorite(itemData:Dynamic):Bool {
        if (itemData == null || itemData.ItemID == null) return false;
        var key:String = Std.string(itemData.ItemID);
        var index:Int = -1;
        for (i in 0...this.favoriteIds.length) {
            if (Std.string(this.favoriteIds[i]) == key) {
                index = i;
                break;
            }
        }

        var nowFavorited:Bool = (index == -1);

        if (nowFavorited) {
            this.favoriteIds.push(itemData.ItemID);
            this.favoriteLookup.set(key, true);
        } else {
            this.favoriteIds.splice(index, 1);
            this.favoriteLookup.remove(key);
        }

        HelperSetting.setArray(HelperSetting.OPTION_FAVORITE_ITEMS, this.favoriteIds);
        return nowFavorited;
    }

    public function fDraw(state:Dynamic, lpf:MovieClip):Void {
        if (this.favoriteButton != null) {
            this.favoriteButton.fClose();
            this.favoriteButton = null;
        }

        if (lpf == null) return;

        var btnDelete:Dynamic = untyped lpf.btnDelete;
        var tInfo:Dynamic = untyped lpf.tInfo;
        var mcUpgrade:Dynamic = untyped lpf.mcUpgrade;
        var mcCoin:Dynamic = untyped lpf.mcCoin;
        var mcPreview:Dynamic = untyped lpf.mcPreview;
        var btnTry:Dynamic = untyped lpf.btnTry;
        var btnFGender:Dynamic = untyped lpf.btnFGender;
        var btnMGender:Dynamic = untyped lpf.btnMGender;
        var btnWiki:Dynamic = untyped lpf.btnWiki;

        if (btnDelete != null) btnDelete.visible = false;

        if (state != null && state.iSel != null) {
            if (btnDelete != null) btnDelete.visible = true;

            if (tInfo != null && this.pocket != null && this.pocket.game != null) {
                tInfo.htmlText = this.pocket.game.getItemInfoStringB(state.iSel);
                if (btnDelete != null) {
                    tInfo.y = (tInfo.textHeight >= 109.8)
                        ? Std.int(((btnDelete.y + btnDelete.height) - tInfo.height) + 10)
                        : Std.int((btnDelete.y + btnDelete.height) - tInfo.textHeight - 3);
                }
            }

            if (mcUpgrade != null) mcUpgrade.visible = (state.iSel.bUpg == 1);
            if (mcCoin != null) mcCoin.visible = (state.iSel.bCoins == 1);
            if (mcUpgrade != null && state.iSel.bCoins == 1) mcUpgrade.visible = false;

            if (state.loadPreview != null) {
                state.loadPreview(state.iSel);
            }
        } else {
            if (tInfo != null) {
                tInfo.htmlText = "Please select an item to preview.";
            }

            if (mcPreview != null) {
                while (mcPreview.numChildren > 0) {
                    mcPreview.removeChildAt(0);
                }
            }

            if (state != null && state.clearPreview != null) {
                state.clearPreview();
            }
        }

        var isShop:Bool = false;
        try {
            var layout:Dynamic = (lpf != null && untyped lpf.getLayout != null) ? untyped lpf.getLayout() : null;
            if (layout != null && layout.sMode != null) {
                isShop = (Std.string(layout.sMode).toLowerCase().indexOf("shop") > -1);
            }
        } catch (e:Dynamic) {}

        if (btnDelete != null) {
            btnDelete.visible = !isShop;
        }

        if (state != null && state.iSel != null) {
            var item = state.iSel;
            if (btnTry != null && item.sType != "Enhancement") {
                switch (Std.string(item.sES)) {
                    case "Weapon", "he", "ba", "pe", "ar", "co", "mi":
                        var isUpgMember:Bool = true;
                        try {
                            isUpgMember = this.pocket.game.world.myAvatar.isUpgraded();
                        } catch (e:Dynamic) {}
                        if (item.bUpg == 1 && !isUpgMember) {
                            btnTry.visible = false;
                        } else {
                            btnTry.visible = true;
                        }
                    default:
                        btnTry.visible = false;
                }
            }

            if (item.sType != "Enhancement") {
                switch (Std.string(item.sES)) {
                    case "ar", "co":
                        var gender:String = "M";
                        try {
                            gender = this.pocket.game.world.myAvatar.objData.strGender;
                        } catch (e:Dynamic) {}
                        if (gender == "M") {
                            if (btnFGender != null) btnFGender.visible = false;
                            if (btnMGender != null) btnMGender.visible = true;
                        } else {
                            if (btnFGender != null) btnFGender.visible = true;
                            if (btnMGender != null) btnMGender.visible = false;
                        }
                    default:
                        if (btnFGender != null) btnFGender.visible = false;
                        if (btnMGender != null) btnMGender.visible = false;
                }
            }

            if (btnWiki != null) {
                var fVis:Bool = (btnFGender != null && btnFGender.visible == true);
                var mVis:Bool = (btnMGender != null && btnMGender.visible == true);
                btnWiki.y = (!fVis && !mVis && btnMGender != null) ? btnMGender.y : 121;

                if (btnTry != null && btnDelete != null && !btnTry.visible && !btnDelete.visible) {
                    btnWiki.y = btnTry.y;
                }
                btnWiki.visible = true;
            }

            var favorite = new Favorite();
            lpf.addChild(favorite);
            favorite.x += 5;
            favorite.y += 5;

            var self = this;
            favorite.fOpen({
                "favorited": this.isFavorite(item),
                "onToggle": function():Bool {
                    var result:Bool = self.toggleFavorite(item);
                    try {
                        untyped lpf.getLayout().update({"eventType": "refreshItems"});
                    } catch (e:Dynamic) {}
                    return result;
                }
            });

            this.favoriteButton = favorite;
        }
    }
}
