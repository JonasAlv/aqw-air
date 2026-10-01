package test;

import worker.PacketParserWorker;
import worker.SearchIndexWorker;
import worker.CombatSolverWorker;

class TestWorkerSystems {
    public static function main() {
        var passed:Int = 0;
        var failed:Int = 0;

        function assert(cond:Bool, msg:String) {
            if (cond) {
                passed++;
            } else {
                failed++;
                Sys.println("FAIL: " + msg);
            }
        }

        // Test 1: SmartFox XT Packet Parser
        var xtRaw = "%xt%zm%moveToCell%1%Enter%Spawn%";
        var p1:Dynamic = PacketParserWorker.parse(xtRaw);
        assert(p1.success == true, "XT packet success");
        assert(p1.cmd == "moveToCell", "XT cmd correct");
        assert(p1.roomId == 1, "XT roomId correct");
        assert(p1.args[0] == "Enter" && p1.args[1] == "Spawn", "XT args correct");

        // Test 2: JSON SmartFox Packet Parser
        var jsonRaw = '{"t":"xt","b":{"r":-1,"o":{"cmd":"loadShop","sName":"BattleonWeapons"}}}';
        var p2:Dynamic = PacketParserWorker.parse(jsonRaw);
        assert(p2.success == true, "JSON packet success");
        assert(p2.cmd == "loadShop", "JSON cmd correct");
        assert(p2.data.sName == "BattleonWeapons", "JSON data payload correct");

        // Test 3: SearchIndexWorker Fuzzy Search & Category Filter
        var items:Array<Dynamic> = [
            { ItemID: 101, sName: "Necrotic Sword of Doom", sType: "Sword", iLvl: 100, bCoins: 1 },
            { ItemID: 102, sName: "Unarmed", sType: "Item", iLvl: 1, bCoins: 1 },
            { ItemID: 103, sName: "Default Sword", sType: "Sword", iLvl: 1, bCoins: 0 },
            { ItemID: 104, sName: "Void Highlord", sType: "Class", iLvl: 100, bCoins: 0 },
            { ItemID: 105, sName: "Doom Blade", sType: "Sword", iLvl: 50, bCoins: 1 }
        ];

        // Search for "sword doom" with acOnly, sorted by level descending
        var res1:Dynamic = SearchIndexWorker.search("sword doom", items, null, { acOnly: true, category: "Sword", sortKey: "level", sortAsc: false });
        assert(res1.totalMatches == 2, "Found 2 matching AC Doom Swords");
        assert(res1.items[0].sName == "Necrotic Sword of Doom", "Highest level item first (Lv 100 > Lv 50)");

        // Test 4: SearchIndexWorker Index Caching
        SearchIndexWorker.indexItems("bankCache", items);
        var res2:Dynamic = SearchIndexWorker.search("void", null, "bankCache", null);
        assert(res2.totalMatches == 1, "Cached search found 1 item");
        assert(res2.items[0].sName == "Void Highlord", "Found Void Highlord from cache");

        // Test 5: CombatSolverWorker Rotation Evaluation
        var combatState = {
            playerHp: 300,
            playerMaxHp: 1000, // 30% HP (under 50% threshold)
            playerMp: 100,
            targetAlive: true,
            targetHp: 5000,
            healThreshold: 50.0,
            skills: [
                { index: 1, name: "Auto Attack", cd: 2000, lastCast: 0, mana: 0, isHeal: false, priority: 1 },
                { index: 2, name: "Nuke", cd: 5000, lastCast: 0, mana: 30, isHeal: false, priority: 10 },
                { index: 3, name: "Heal", cd: 6000, lastCast: 0, mana: 25, isHeal: true, priority: 5 }
            ]
        };

        var decision:Dynamic = CombatSolverWorker.solve(combatState);
        assert(decision.castSkillIndex == 3, "Emergency heal prioritized when under 50% HP");
        assert(decision.action == "heal", "Action is heal");

        // Now test normal DPS priority when HP is healthy
        combatState.playerHp = 900; // 90% HP
        var decision2:Dynamic = CombatSolverWorker.solve(combatState);
        assert(decision2.castSkillIndex == 2, "Nuke prioritized when healthy (Index 2)");
        assert(decision2.action == "cast", "Action is cast");

        Sys.println("=== TEST SUMMARY: " + passed + " passed, " + failed + " failed ===");
        if (failed > 0) Sys.exit(1);
    }
}
