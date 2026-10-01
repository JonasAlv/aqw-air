package worker;

class SearchIndexWorker {
    private static var _cachedIndexes:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

    /**
     * Stores an item list in the worker memory cache under key (e.g. "bank", "inventory").
     */
    public static function indexItems(key:String, items:Array<Dynamic>):Int {
        if (key == null || items == null) return 0;
        _cachedIndexes.set(key, items);
        return items.length;
    }

    public static function clearIndex(key:String):Void {
        _cachedIndexes.remove(key);
    }

    public static function clearAll():Void {
        _cachedIndexes = new Map<String, Array<Dynamic>>();
    }

    /**
     * Multi-field fuzzy search, categorization filter, and sorting.
     */
    public static function search(query:String, ?items:Array<Dynamic>, ?cacheKey:String, ?options:Dynamic):Dynamic {
        var sourceItems:Array<Dynamic> = (items != null) ? items : ((cacheKey != null) ? _cachedIndexes.get(cacheKey) : null);
        if (sourceItems == null) {
            return { totalMatches: 0, page: 0, totalPages: 0, items: [] };
        }

        var filterCategory:String = (options != null && options.category != null) ? Std.string(options.category).toLowerCase() : null;
        var acOnly:Bool = (options != null && options.acOnly == true);
        var memberOnly:Bool = (options != null && options.memberOnly == true);
        var favoriteMap:Dynamic = (options != null && options.favoriteMap != null) ? options.favoriteMap : null;
        var tokens:Array<String> = [];
        if (query != null && query.length > 0) {
            for (t in query.toLowerCase().split(" ")) {
                var trimmed = StringTools.trim(t);
                if (trimmed.length > 0) tokens.push(trimmed);
            }
        }

        var sortKey:String = (options != null && options.sortKey != null) ? 
            Std.string(options.sortKey).toLowerCase() : 
            (tokens.length > 0 ? "relevance" : "name");
        var sortAsc:Bool = (options != null && options.sortAsc != null) ? (options.sortAsc == true) : true;
        var page:Int = (options != null && options.page != null) ? Std.int(options.page) : 0;
        var pageSize:Int = (options != null && options.pageSize != null) ? Std.int(options.pageSize) : 9;

        var matchedItems:Array<{ item:Dynamic, score:Int }> = [];

        for (item in sourceItems) {
            if (item == null) continue;

            // 1. AC / Coins filter
            if (acOnly) {
                var bCoins:Dynamic = Reflect.field(item, "bCoins");
                if (bCoins != 1 && bCoins != true && bCoins != "1") continue;
            }

            // 2. Member / Upgrade filter
            if (memberOnly) {
                var bUpg:Dynamic = Reflect.field(item, "bUpg");
                if (bUpg != 1 && bUpg != true && bUpg != "1") continue;
            }

            // 3. Category / sType filter
            var sType:String = (item.sType != null) ? Std.string(item.sType).toLowerCase() : "";
            if (filterCategory != null && filterCategory.length > 0 && filterCategory != "*") {
                if (sType.indexOf(filterCategory) == -1) continue;
            }

            // 4. Favorite filter if enabled
            if (favoriteMap != null) {
                var itemIdStr:String = Std.string(item.ItemID != null ? item.ItemID : item.id);
                if (!Reflect.hasField(favoriteMap, itemIdStr)) continue;
            }

            // 5. Query matching & scoring
            var score:Int = 0;
            if (tokens.length > 0) {
                var sName:String = (item.sName != null) ? Std.string(item.sName).toLowerCase() : "";
                var sDesc:String = (item.sDesc != null) ? Std.string(item.sDesc).toLowerCase() : "";
                var idStr:String = (item.ItemID != null) ? Std.string(item.ItemID) : "";
                var allMatched:Bool = true;

                for (token in tokens) {
                    var inName:Int = sName.indexOf(token);
                    var inDesc:Int = sDesc.indexOf(token);
                    var inId:Int = idStr.indexOf(token);
                    var inType:Int = sType.indexOf(token);

                    if (inName == -1 && inDesc == -1 && inId == -1 && inType == -1) {
                        allMatched = false;
                        break;
                    }

                    if (inName == 0) score += 100; // Exact prefix match in name
                    else if (inName > 0) score += 50; // Substring in name
                    else if (inId == 0) score += 40;  // Matches ID
                    else if (inType > -1) score += 20; // Matches category / sType
                    else if (inDesc > -1) score += 10; // Found in description
                }

                if (!allMatched) continue;
            } else {
                score = 1;
            }

            matchedItems.push({ item: item, score: score });
        }

        // 6. Sorting
        matchedItems.sort(function(a, b):Int {
            if (tokens.length > 0 && sortKey == "relevance") {
                return (b.score - a.score);
            }

            var res:Int = 0;
            switch (sortKey) {
                case "name":
                    var nameA:String = (a.item.sName != null) ? Std.string(a.item.sName).toLowerCase() : "";
                    var nameB:String = (b.item.sName != null) ? Std.string(b.item.sName).toLowerCase() : "";
                    res = (nameA < nameB) ? -1 : ((nameA > nameB) ? 1 : 0);

                case "level":
                    var lvlA:Int = (a.item.iLvl != null) ? Std.parseInt(Std.string(a.item.iLvl)) : 0;
                    var lvlB:Int = (b.item.iLvl != null) ? Std.parseInt(Std.string(b.item.iLvl)) : 0;
                    res = lvlA - lvlB;

                case "id":
                    var idA:Int = (a.item.ItemID != null) ? Std.parseInt(Std.string(a.item.ItemID)) : 0;
                    var idB:Int = (b.item.ItemID != null) ? Std.parseInt(Std.string(b.item.ItemID)) : 0;
                    res = idA - idB;

                default:
                    res = b.score - a.score;
            }

            return sortAsc ? res : -res;
        });

        // 7. Pagination
        var totalMatches:Int = matchedItems.length;
        var totalPages:Int = (pageSize > 0) ? Math.ceil(totalMatches / pageSize) : 1;
        if (page < 0) page = 0;
        if (page >= totalPages && totalPages > 0) page = totalPages - 1;

        var startIdx:Int = page * pageSize;
        var endIdx:Int = (startIdx + pageSize < totalMatches) ? (startIdx + pageSize) : totalMatches;

        var paginatedResults:Array<Dynamic> = [];
        if (startIdx < totalMatches) {
            for (i in startIdx...endIdx) {
                paginatedResults.push(matchedItems[i].item);
            }
        }

        return {
            totalMatches: totalMatches,
            page: page,
            pageSize: pageSize,
            totalPages: totalPages,
            items: paginatedResults
        };
    }
}
