package game;

import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import ui.util.Pagination;

class ItemPagination {
    private var pocket:Dynamic;
    private var itemsPerPage:Int = 9;

    private static inline var FAVORITE_ALPHA:Float = 0.3;
    private static var FAVORITE_CT:ColorTransform = new ColorTransform(0, 0, 0, 1, 255, 215, 0, 0);

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
    }

    public function fDraw(state:Dynamic, lpf:Dynamic, reset:Bool):Dynamic {
        var listA:Array<Dynamic> = [];
        var sortedGroup:Array<Dynamic> = [];
        var filteredItems:Array<Dynamic> = [];
        var i:Int;

        var tSel:Dynamic = state.tSel;
        var iSel:Dynamic = state.iSel;
        var filterMap:Dynamic = state.filterMap;
        var itemList:Array<Dynamic> = state.itemList != null ? cast state.itemList : [];
        var sortOrder:Array<Dynamic> = state.sortOrder != null ? cast state.sortOrder : [];
        var onDemand:Bool = state.onDemand == true;
        var bLimited:Bool = state.bLimited == true;
        var itemEventType:String = state.itemEventType;
        var allowDesel:Bool = state.allowDesel == true;
        var multiSelect:Bool = state.multiSelect == true;

        var iList:MovieClip = cast untyped lpf.iList;
        var bgTabs:MovieClip = cast untyped lpf.bgTabs;
        var listMask:MovieClip = cast untyped lpf.listMask;
        var scr:Dynamic = untyped lpf.scr;
        var layout:Dynamic = untyped state.getLayout();

        try {
            var popupLabel:String = Std.string(this.pocket.game.ui.mcPopup.currentLabel);
            if (popupLabel == "Bank" || popupLabel == "MergeShop") {
                itemsPerPage = 7;
            } else {
                itemsPerPage = 9;
            }
        } catch (e:Dynamic) {
            itemsPerPage = 9;
        }

        var lpfElementListItemItemCls:Dynamic = null;
        try {
            lpfElementListItemItemCls = this.pocket.game.world.getClass("LPFElementListItemItem");
        } catch (e:Dynamic) {}

        if (iList != null) {
            while (iList.numChildren > 0) {
                var child:Dynamic = iList.getChildAt(0);
                if (child != null && child.fClose != null) {
                    child.fClose();
                } else if (child != null && child.parent != null) {
                    child.parent.removeChild(child);
                }
            }

            if (reset || untyped iList.curPage == null) {
                untyped iList.curPage = 0;
            }

            if (reset && bgTabs != null) {
                iList.y = bgTabs.height - 1;
            }
        }

        if (tSel == null) {
            state.setMessage("No Tab Selected");
            if (scr != null) {
                scr.fOpen({
                    "subject": iList,
                    "subjectMask": listMask,
                    "reset": reset
                });
            }
            return {listA: listA};
        }

        state.setMessage("");

        if (tSel.filter != "*") {
            for (itemData in itemList) {
                var filterKey:String = Std.string(tSel.filter);
                var filterList:Dynamic = filterMap != null ? Reflect.field(filterMap, filterKey) : null;
                var matchesFilter:Bool = false;

                var sTypeStr:String = Std.string(itemData.sType);
                if (filterList != null) {
                    matchesFilter = (Std.string(filterList).indexOf(sTypeStr) > -1);
                }
                if (!matchesFilter && itemData.sType == "Enhancement" && itemData.sES != null) {
                    matchesFilter = (Std.string(itemData.sES).indexOf(filterKey) > -1);
                }

                var isExcludedPot:Bool = (filterKey == "pots" &&
                    itemData.sLink != "potion" &&
                    itemData.sLink != "elixir" &&
                    itemData.sLink != "tonic" &&
                    itemData.sLink != "scroll");

                if (matchesFilter && !isExcludedPot) {
                    filteredItems.push(itemData);
                }
            }
        } else {
            filteredItems = itemList;
        }

        if (onDemand && filteredItems.length == 0) {
            state.setMessage("No items of this type");
            if (scr != null) {
                scr.fOpen({
                    "subject": iList,
                    "subjectMask": listMask,
                    "reset": reset
                });
            }
            return {listA: listA};
        }

        var sortedItemIds = new Map<String, Bool>();

        for (ord in sortOrder) {
            sortedGroup = [];
            for (itemData in filteredItems) {
                if (itemData.sType == ord) {
                    sortedGroup.push(itemData);
                    sortedItemIds.set(Std.string(itemData.ItemID), true);
                }
            }

            if (sortedGroup.length > 0) {
                #if flash
                untyped sortedGroup.sortOn(["sName", "iLvl"], [null, 2 | 16]); // Array.DESCENDING | Array.NUMERIC
                #end
                listA = listA.concat(sortedGroup);
            }
        }

        sortedGroup = [];
        for (itemData in filteredItems) {
            if (!sortedItemIds.exists(Std.string(itemData.ItemID))) {
                sortedGroup.push(itemData);
            }
        }

        if (sortedGroup.length > 0) {
            #if flash
            untyped sortedGroup.sortOn(["sType", "sName"]);
            #end
            listA = listA.concat(sortedGroup);
        }

        var optEquippedOnTop:Bool = (this.pocket.config != null) ? this.pocket.config.option_equipped_on_top == true : true;
        if (layout != null && layout.sMode != "bank" && optEquippedOnTop) {
            var pinnedItems:Array<Dynamic> = [];
            var unpinnedItems:Array<Dynamic> = [];

            for (itemData in listA) {
                if (itemData.bEquip == 1 || itemData.bEquip == true) {
                    pinnedItems.push(itemData);
                } else {
                    unpinnedItems.push(itemData);
                }
            }
            listA = pinnedItems.concat(unpinnedItems);
        }

        var itemFavorite:ItemFavorite = (this.pocket.gameCore != null) ? this.pocket.gameCore.itemFavorite : null;
        if (itemFavorite != null) {
            var favoritedItems:Array<Dynamic> = [];
            var unfavoritedItems:Array<Dynamic> = [];

            for (itemData in listA) {
                if (itemFavorite.isFavorite(itemData)) {
                    favoritedItems.push(itemData);
                } else {
                    unfavoritedItems.push(itemData);
                }
            }
            listA = favoritedItems.concat(unfavoritedItems);
        }

        var itemConfig:Dynamic = {};
        itemConfig.eventType = itemEventType;
        itemConfig.allowDesel = allowDesel;
        itemConfig.multiSelect = multiSelect;
        itemConfig.bLimited = bLimited && (layout != null && layout.sMode == "shopBuy");

        var listLength:Int = listA.length;
        var totalPages:Int = 1;
        var curPage:Int = 0;
        var startIndex:Int = 0;
        var endIndex:Int = listLength;

        var optPagination:Bool = (this.pocket.config != null) ? this.pocket.config.option_pagination == true : true;
        if (optPagination) {
            totalPages = Std.int(Math.max(1, Math.ceil(listLength / itemsPerPage)));

            var curP:Int = (iList != null && untyped iList.curPage != null) ? untyped iList.curPage : 0;
            if (curP >= totalPages) {
                curP = totalPages - 1;
            }
            if (curP < 0) {
                curP = 0;
            }
            if (iList != null) untyped iList.curPage = curP;

            curPage = curP;
            startIndex = curPage * itemsPerPage;
            endIndex = Std.int(Math.min(startIndex + itemsPerPage, listLength));
        } else {
            if (iList != null) untyped iList.curPage = 0;
        }

        if (iList != null && lpfElementListItemItemCls != null) {
            for (idx in startIndex...endIndex) {
                addListItem(iList, lpf, lpfElementListItemItemCls, itemConfig, listA, iSel, idx - startIndex);
            }

            if (optPagination && totalPages > 1) {
                var pagination = new Pagination();
                iList.addChild(pagination);
                pagination.y = iList.height + 6.5;

                pagination.fOpen({
                    "page": curPage + 1,
                    "totalPages": totalPages,
                    "canPrev": curPage > 0,
                    "canNext": curPage < totalPages - 1,
                    "state": state,
                    "lpf": lpf
                });

                if (pagination.btnPrev != null) {
                    pagination.btnPrev.addEventListener(MouseEvent.CLICK, this.onPrevClick, false, 0, false);
                }
                if (pagination.btnNext != null) {
                    pagination.btnNext.addEventListener(MouseEvent.CLICK, this.onNextClick, false, 0, false);
                }
            }
        }

        if (scr != null) {
            scr.fOpen({
                "subject": iList,
                "subjectMask": listMask,
                "reset": true
            });
        }

        return {listA: listA};
    }

    private function onPrevClick(e:MouseEvent):Void {
        var btn:SimpleButton = cast e.currentTarget;
        var pagination:Pagination = cast btn.parent;
        if (pagination == null || pagination.fData == null) return;

        var data = pagination.fData;
        var iList:MovieClip = cast data.lpf.iList;

        if (iList != null && untyped iList.curPage > 0) {
            untyped iList.curPage--;
            fDraw(data.state, data.lpf, false);
        }
    }

    private function onNextClick(e:MouseEvent):Void {
        var btn:SimpleButton = cast e.currentTarget;
        var pagination:Pagination = cast btn.parent;
        if (pagination == null || pagination.fData == null) return;

        var data = pagination.fData;
        var iList:MovieClip = cast data.lpf.iList;

        if (iList != null && untyped iList.curPage < data.totalPages - 1) {
            untyped iList.curPage++;
            fDraw(data.state, data.lpf, false);
        }
    }

    private function addListItem(iList:Dynamic, lpf:Dynamic, cls:Dynamic, itemConfig:Dynamic, listA:Array<Dynamic>, iSel:Dynamic, key:Int):Void {
        var curPage:Int = (iList != null && untyped iList.curPage != null) ? untyped iList.curPage : 0;
        var itemData = listA[key + curPage * itemsPerPage];
        itemConfig.fData = itemData;

        #if flash
        var listItem:Dynamic = untyped __new__(cls);
        iList.addChild(listItem);

        if (listItem.subscribeTo != null) listItem.subscribeTo(lpf);
        if (listItem.fOpen != null) listItem.fOpen(itemConfig);

        if (listItem.fData == iSel && listItem.select != null) {
            listItem.select();
        }

        if (key != 0) {
            listItem.y = iList.height;
        }

        var itemFavorite:ItemFavorite = (this.pocket.gameCore != null) ? this.pocket.gameCore.itemFavorite : null;
        if (itemFavorite != null && itemFavorite.isFavorite(itemConfig.fData) && listItem.selBG != null) {
            listItem.selBG.transform.colorTransform = FAVORITE_CT;
            listItem.selBG.alpha = FAVORITE_ALPHA;

            listItem.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
                if (!(listItem.sel == true)) {
                    listItem.selBG.alpha = FAVORITE_ALPHA;
                }
            }, false, -2147483648, true);
        }
        #end
    }
}
