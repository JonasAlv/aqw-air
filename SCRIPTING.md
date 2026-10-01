# AQW Haxe Scripting API Guide (.hxs)

Welcome to the official scripting guide for the AQW Client Mod. Scripts are written in **HScript** (`.hxs` files) — a lightweight, dynamic scripting language with standard JavaScript/ActionScript 3 syntax executing live inside the client engine.

---

## The Default Scripting Standard (Core Primitives + Namespaces)

Our scripting architecture combines the best of both worlds:
1. **Clean, top-level DSL primitives** for all primary botting actions (`quest`, `hunt`, `mapItem`, `complete`, `ensureMap`, `ensureHouse`, `hasItem`, `equipLoadout`, `stop`, `log`). No unnecessary prefixes needed for 99% of code.
2. **First-class object namespaces** (`player`, `combat`, `map`, `quests`, `inventory`, `bank`, `drop`, `shop`, `monster`, `aura`, `enhancement`, `blacklist`, `api`, `bot`) for advanced state queries and subsystem control.

### Minimalist Example:
```javascript
// Hunt 10 Possessed Armor in ShadowBattleon
function onStart() {
    log("Starting farm routine...");
    acceptAllDrops();
    equipLoadout("farm");
    join("shadowbattleon");
}

function onTick() {
    ensureMap("shadowbattleon");
    hunt("Possessed Armor", 10, stop);
}

function onStop() {
    log("Routine complete.");
    ensureHouse();
}
```

---

## Table of Contents
1. [Script Lifecycle Hooks](#script-lifecycle-hooks)
2. [Safe House Startup Pattern (Crucial for Sagas)](#safe-house-startup-pattern-crucial-for-sagas)
3. [The Deterministic Step-by-Step Quest Pattern](#the-deterministic-step-by-step-quest-pattern)
4. [Top-Level Primitives Quick Reference](#top-level-primitives-quick-reference)
5. [Subsystem Namespaces (`player`, `aura`, `shop`, etc.)](#subsystem-namespaces)
6. [Combat & Hunting](#combat--hunting)
7. [Drops, Inventory & Banking](#drops-inventory--banking)
8. [Blacklist Management](#blacklist-management)
9. [Scripting Architectural Patterns](#scripting-architectural-patterns)
10. [AI Script Generation Guide](#ai-script-generation-guide)

---

## Script Lifecycle Hooks

Every `.hxs` script defines standard lifecycle hooks called by the engine:

| Hook | When it executes | Common Usage |
|---|---|---|
| `onStart()` | Executed **once** when the script starts | Set drop filters (`acceptAllDrops()`), equip loadouts, initialize state flags |
| `onTick()` | Executed **periodically** (~100ms) | Main routine (hunting, checking quests, verifying map position) |
| `onStop()` | Executed **once** when script is stopped | Safe exit (e.g. `ensureHouse()`), final cleanup, logging |
| `onPacket(packet)` | Executed on every incoming server packet | Custom packet sniffing, rare event listening |
| `onZoneEntered(zone)`| Executed on map/cell transfer | Zone buffs or custom cutscene triggers |
| `onQuestUpdated(id)` | Executed when a quest objective updates | Progress logging |
| `onInventoryChanged(item)`| Executed when items are added/removed | Inventory tracking |

---

## Safe House Startup Pattern (Crucial for Sagas)

When running multi-chapter sagas (like the *13 Lords of Chaos*), scripts should **never** check quest completion milestones while standing in hostile monster territory. Monsters will aggro, interrupt map transitions, or cause quest status packets to desync.

**The Solution:** Teleport to your private house on startup, safely load the chapter's quest list from the server, verify your progress, and only then teleport to the active quest.

```javascript
var checkedProgress = false;

function onStart() {
    checkedProgress = false;
    acceptAllDrops();
    setSkipCutscenes(true);
    equipLoadout("farm");
}

function onTick() {
    // 1. Initial safe house check to verify quest milestones
    if (!checkedProgress) {
        if (!isHouse()) {
            ensureHouse();
            return;
        }
        // Load all chapter quest IDs from server
        if (!ensureQuestsLoaded([2376, 2377, 2378, 2379, 2380, 2381])) {
            return;
        }
        checkedProgress = true;
        log("Milestone progress verified at house. Resuming storyline...");
    }

    // 2. Storyline execution begins...
}
```

---

## The Deterministic Step-by-Step Quest Pattern

In earlier botting paradigms, macro functions like `storyKillQuest()` tried to automatically guess which monster dropped which requirement using fuzzy name heuristics. On hybrid quests (requiring **both** map items and monster drops), this caused infinite loops and turn-in errors.

The **Deterministic Step-by-Step Pattern** is 100% reliable, zero-guesswork, and handles single-mob, multi-mob, and hybrid quests seamlessly:

```javascript
// Quest 2379: Bolster the Elements (Hybrid: 2 Map Items + 2 Monster Drops)
// Both mapItem and hunt follow the consistent (Target, Item, Qty) convention!
if (quest(2379, "aqlesson")) {
    if (!mapItem(1470, "Light of Hope Acquired", 3)) return;
    if (!mapItem(1471, "Tears of Joy Acquired", 3)) return;
    if (!hunt("Eternite Ore", "TimeSpark Acquired", 3)) return;
    if (!hunt("Water Elemental", "Shadows Acquired", 3)) return;
    complete(2379);
}
```

### Why this pattern never breaks:
1. `quest(questId, mapName)`:
   - If the quest was already completed in the past (`isCompletedBefore(questId)`), it returns `false` immediately (skipping the entire block in under 1 millisecond).
   - If not completed, it automatically joins `mapName`, accepts the quest, and returns `true` to enter the step block.
2. `mapItem(itemId, item, qty)` / `getMapItem(...)`:
   - Checks your inventory directly for `item` $\ge$ `qty`.
   - If not satisfied, gathers the map item respecting safety server cooldowns (1500ms delay). Returns `true` once acquired.
3. `hunt(monster, item, qty)`:
   - Automatically navigates to the monster, engages combat, and checks inventory for `item` $\ge$ `qty`. Returns `true` once acquired.
4. `complete(questId)`:
   - Safely stops combat, turns in the quest, clears temporary grab data, and verifies server completion.

---

## Top-Level Primitives Quick Reference

These functions are available everywhere in `.hxs` files without any object prefix.

### Navigation & Maps
- `ensureMap(mapName, cell?, pad?)` *(Bool)*: Ensures you are on `mapName` and cell. Drops combat stealthily before transferring if in combat. Automatically routes `"house"` to your personal house.
- `ensureHouse()` *(Bool)*: Safely drops combat and teleports to your private house. Returns `true` once loaded.
- `join(mapName, cell?, pad?)`: Direct map transfer.
- `joinHouse(username?)`: Direct house transfer.
- `ensureCell(cell, pad?)` *(Bool)*: Ensures avatar is in the specified cell on current map.
- `jump(cell, pad?)`: Jumps to specified cell and pad.
- `cell()` *(String)* / `pad()` *(String)*: Current avatar cell and pad.
- `mapName()` *(String)*: Current map name.
- `isHouse()` *(Bool)*: Returns `true` if currently in your personal house.
- `isMap(name)` *(Bool)*: Returns `true` if on the specified map.
- `isCell(name)` *(Bool)*: Returns `true` if in the specified cell.
- `isLoaded()` *(Bool)*: Returns `true` if map is fully loaded.
- `setSkipCutscenes(enabled? = true)`: Enables/disables auto-skipping cutscenes on map joins.

### Map Items (`mapItem` & `getMapItem`)
Both `mapItem` and `getMapItem` are aliases and flexibly accept either order:
- **`mapItem(itemId, item, qty = 1, map?)`** *(Bool)*: **Recommended.** Follows the consistent `(Target, Item, Quantity)` structure identical to `hunt(mob, item, qty)`. Gathers map item until inventory contains `qty` of `item`.
- **`mapItem(itemId, qty = 1, item?, map?)`** *(Bool)*: Quantity-first overload (e.g. `mapItem(42, 5, "Dew Drop")`).
- **`mapItem(itemId, qty = 1)`** *(Bool)*: When quest requirements do not produce an inventory item (e.g. `mapItem(42, 5)` to click 5 times).
- **`getMapItem(itemId)`** *(Bool)*: Interacts with a map item once (rate-limited to 1500ms). Also accepts multi-arguments forwarding to `mapItem`.
- **`ensureMapItem(itemId, ...)`** *(Bool)*: Alias for `mapItem`.

### Combat & Hunting (`hunt`)
The `hunt()` function automatically resolves which cell the monster spawns in, transfers there, locks onto the target, and runs your combat rotation. It automatically detects the signature:
- **By Item Drop:**
  - `hunt(monster, item, qty = 1, callback?)` *(Bool)*: **Recommended.** Hunts monster until backpack or temporary inventory holds `qty` of `item` (e.g. `hunt("Frogzard", "Tooth", 6)`). Returns `true` when acquired.
  - `hunt(monster, item, qty, mmid, callback?)` *(Bool)*: Hunts a specific Map Monster ID (MMID) spawn until inventory holds `qty` of `item` (e.g. `hunt("Gorillaphant", "Gorillaphant Tusks", 6, 2)`). Ensures the bot navigates to that monster's cell and strictly locks onto that specific MMID.
- **By Kill Count:**
  - `hunt(monster, count, callback?)` *(Bool)*: Hunts monster by total kill count (e.g. `hunt("Frogzard", 10)` kills 10 Frogzards). Automatically counts monster deaths. Returns `true` when reached.
  - `hunt(monster, count, mmid, callback?)` *(Bool)*: Hunts a specific Map Monster ID (MMID) count (e.g. `hunt("Frogzard", 5, 2)`).
- **By Multi-Item Array:**
  - `hunt(monster, itemsArray, callback?)` *(Bool)*: Hunts monster until all requirements in array are collected:
    - String items with count: `hunt("Mob", ["Item A:10", "Item B:5"])`
    - Array pairs: `hunt("Mob", [["Item A", 10], ["Item B", 5]])`
- **Continuous / Unbounded:**
  - `hunt(monster)` *(Bool)*: Hunts monster indefinitely without count constraints.
- **Wildcard Targeting:**
  - `hunt("*", 5)`: Kills any 5 monsters in the current cell.
  - `hunt("*", "Item", 3)`: Attacks any monster until 3 items are acquired.
- **Aliases & Helpers:**
  - `kill(...)` *(Bool)*: Direct alias for `hunt(...)` supporting all the same overloads.
  - `huntItem(monster, item, qty = 1, map?)` *(Bool)*: Navigates to `map`, checks inventory, and hunts for item.
  - `huntMonster(monster, kills = 1, map?)` *(Bool)*: Navigates to `map` and hunts by kill count.
- `stopCombat()`: Drops target, halts auto-attack, and stealthily drops aggro in-place.
- `ensureCombat(smart? = true)`: Ensures combat engine is active.
- `equipLoadout("farm" | "solo" | "support")` *(Bool)*: Equips predefined class, gear, and combat rules.
- `attack(monster)`: Targets and attacks monster.

> [!NOTE]
> **What is a `callback`?**
> A callback is an optional function (e.g. `function() { log("Done!"); }`) passed at the end of `hunt(...)` or `kill(...)` that executes once when the hunt condition is satisfied (all requested items are gathered or kill count is met).
>
> In typical `.hxs` scripts using the `onTick()` loop, **callbacks are usually unnecessary** because `hunt()` returns `false` while fighting and `true` when finished:
> ```haxe
> if (!hunt("Frogzard", "Frogzard Tooth", 6)) return;
> // Code below runs automatically on the tick the hunt finishes:
> complete(1234);
> ```
> Use a callback when you want to trigger one-time event logic or specialized notifications at the moment of completion:
> ```haxe
> hunt("Gorillaphant", "Gorillaphant Tusks", 6, 2, function() {
>     log("Tusks completed from MMID 2!");
> });
> ```

### Quests & Storyline
- `quest(questId, mapName?)` *(Bool)*: Skips block if quest is already completed; otherwise ensures map, accepts quest, and returns `true`.
- `mapItem(itemId, item, qty? = 1, mapName?)` *(Bool)*: Gathers map item until quantity is in inventory (also accepts `(itemId, qty, item)`).
- `complete(questId, choice?)` *(Bool)*: Turns in quest (with optional choice reward ID or name). Returns `true` on completion.
- `isDone(questId)` / `isCompletedBefore(questId)` *(Bool)*: Returns `true` if quest has already been finished.
- `canComplete(questId)` / `isQuestComplete(questId)` *(Bool)*: Returns `true` if all turn-in requirements are satisfied.
- `isQuestUnlocked(questId)` / `isUnlocked(questId)` *(Bool)*: Returns `true` if quest is unlocked for your character.
- `ensureQuestsLoaded(questIds)` *(Bool)*: Pre-loads an array of quest definitions from the server.
- `ensureAccept(questId)` *(Bool)*: Ensures quest is loaded and accepted.
- `storyKillQuest(id, map, monster)` *(Bool)*: Macro kill quest helper (supports string or array of monsters).
- `storyMapItemQuest(id, map, itemIds, amount? = 1)` *(Bool)*: Macro map item quest helper.
- `storyChainQuest(id, map?)` *(Bool)*: Chain turn-in quest helper (dialogs, cutscene quests).
- `autoQuest([ids])`: Runs background auto-questing (acceptance, requirement checking, turn-in).
- `stopAutoQuest()`: Stops background auto-questing.

### Inventory, Drops & Banking
- `hasItem(itemName, qty? = 1)` *(Bool)*: Checks regular and temporary inventory for item quantity.
- `getItemCount(itemName)` *(Int)*: Returns regular inventory count.
- `getQuestQuantity(itemName)` *(Int)*: Returns count checking backpack, temp inventory, and quest tree.
- `equip(itemName)`: Equips weapon, armor, helm, cape, class, or pet.
- `acceptAllDrops(enabled? = true)`: Automatically accepts all item drops as they appear.
- `acceptAcDrops(enabled? = true)`: Automatically accepts AC-tagged items only.
- `getDrop(itemName)`: Picks up a specific drop.
- `buyItem(shopId, itemName, qty? = 1)`: Loads shop and buys item.
- `bankAll(exclude?)`: Deposits all unequipped, non-temporary items into Bank.
- `bankAllAcItems(exclude?)`: Deposits all unequipped AC items into free bank storage.
- `unbankPreset(name)`: Unbanks all items from a hardfarm preset (e.g. `"vhl"`, `"lr"`, `"nulgath"`).
- `unbankAllNonAcItems(exclude?)`: Withdraws non-AC items back into backpack.
- `bankAcAndUnbankNonAc(exclude?)`: Banks AC items first, then withdraws non-AC items.
- `isBanking()` / `isUnbanking()` *(Bool)*: Returns `true` while bank transfer queue is active.

### Execution Control & Logging
- `log(message)`: Timestamped message in `assets/api.log`, console, and game chat (if enabled).
- `msg(message)`: Displays both a console log and in-game notification popup.
- `warn(message)` / `error(message)`: Warning and error console logs.
- `clearLog()`: Truncates `assets/api.log` to start fresh.
- `copyLog()`: Copies `assets/api.log` content to system clipboard.
- `readLog()`: Reads string content of `assets/api.log`.
- `setChatLogging(enabled)`: Globally toggles API and script blue messages in game chat.
- `isChatLogging()` *(Bool)*: Returns whether game chat logging is currently active.
- `sleep(ms)`: Pauses script execution for specified milliseconds.
- `stop()`: Halts script, drops combat, and invokes `onStop()`.
- `sendPacket(packet)`: Sends raw game packet to server.
- `addBlacklist(itemName)`: Blocks item from drop queue.
- `sellBlacklist()`: Sells all owned blacklisted items.

---

## Subsystem Namespaces

Specialized queries, deep player metrics, and manager controls are accessible via first-class namespaces:

### `player.*`
- `player.hp` / `player.maxHp` *(Int)*: Current and maximum health.
- `player.mp` / `player.maxMp` *(Int)*: Current and maximum mana.
- `player.gold` / `player.coins` *(Int)*: Current character gold.
- `player.ac` *(Int)*: Current AdventureCoins.
- `player.level` *(Int)*: Current character level.
- `player.isAlive` *(Bool)*: Character alive status.
- `player.isInCombat` *(Bool)*: Engaged in combat status.
- `player.isMember` *(Bool)*: Upgrade/membership status.
- `player.className` *(String)*: Equipped class name.
- `player.rest()`: Rests to recover HP and MP.
- `player.hasAura(auraName)` *(Bool)*: Returns `true` if player has aura.

### `aura.*`
- `aura.has(auraName, target? = "player")` *(Bool)*: Checks if player or target has aura.
- `aura.getStacks(auraName, target? = "player")` *(Float)*: Returns current stack count.
- `aura.getRemaining(auraName, target? = "player")` *(Float)*: Returns remaining seconds.

### `shop.*`
- `shop.loadShop(shopId)`: Loads shop from server.
- `shop.isShopLoaded` *(Bool)*: Shop loaded status.
- `shop.loadedShopId` *(Int)*: Currently active shop ID.
- `shop.buyItem(itemName, qty? = 1)`: Purchases item.
- `shop.sellItem(itemName, qty? = 1)`: Sells item.

### `monster.*`
- `monster.getByCell(cellName)` *(Array)*: Returns all monsters spawned in cell.
- `monster.isMonsterAliveInCell(cellName)` *(Bool)*: Checks for living monsters in room.
- `monster.getMapMonsterNames()` *(Array<String>)*: Returns all monster names on the map.

### `combat.*`
- `combat.startAuto()`: Starts auto combat rotation.
- `combat.startSmart()`: Starts smart class-aware combat.
- `combat.startCustom(rotation)`: Starts custom rotation (e.g. `"1,2,3,4"`).
- `combat.useSkill(index)` *(Bool)*: Activates skill 1..4.
- `combat.canUseSkill(index)` *(Bool)*: Checks if skill is off cooldown and has sufficient mana.

### `enhancement.*`
- `enhancement.smartEnhance(pattern, level?)`: Enhances gear automatically.
- `enhancement.isForgeUnlocked(enhancementName)` *(Bool)*: Checks Forge quest unlocks.
- `enhancement.isAweUnlocked()` *(Bool)*: Checks Blade of Awe unlocks.

### `api.*` / `bot.*`
Direct root reference to the full underlying AQW engine:
- `api.player`, `api.combat`, `api.map`, `api.quest`, `api.inventory`, `api.drop`, `api.shop`, `api.monster`, `api.aura`, `api.enhancement`, `api.transport`

---

## Drops, Inventory & Banking

### Hardfarm Item Presets (`unbankPreset`)
AQW routes newly dropped items directly into your Bank if any quantity exists in your Bank. This stalls bots indefinitely because turn-ins only check backpack inventory.

Always unbank your farm reagents in `onStart()` using built-in presets:
```javascript
function onStart() {
    acceptAllDrops();
    equipLoadout("farm");

    // 1. Bank all junk while preserving VHL materials:
    bankAll("vhl");

    // 2. Unbank all 32 VHL reagents so drops land in backpack:
    unbankPreset("vhl");

    join("tercessuinotlim");
}

function onTick() {
    // Wait until paced unbank queue finishes before fighting:
    if (isUnbanking()) return;

    // Farming continues...
}
```

#### Available Built-in Presets:
- `"nulgath"`: 27 core Nation materials (Diamonds, Gems, Vouchers, Blood Gems, Totems, Unidentified items).
- `"vhl"`: 32 Void Highlord reagents (Roentgeniums, Crystals A & B, Elders' Blood, Totems).
- `"lr"`: 24 Legion Revenant reagents (LF1, LF2 cohorts, LF3, Spellscrolls, Legion Tokens).
- `"dot"`: 49 Dragon of Time artifacts and boss drops.
- `"ynr"`: 28 Yami no Ronin materials.
- `"vdk"`: 44 Verus DoomKnight traces and souls.
- `"cav"`: 10 Chaos Avenger fragments and insignias.
- `"archmage"`: 27 ArchMage books, tomes, and scribing materials.
- `"nsod"`: 29 Necrotic Sword of Doom void auras, hilts, and blades.
- `"sdka"`: 40 Sepulchure's DoomKnight Armor dark spirit orbs and doom auras.

---

## Scripting Architectural Patterns

### Pattern 1: Complete Saga Chapter (House Safe Start + Step-by-Step)
```javascript
// Script: 10_Iadoa_TheSpan.hxs
var checkedProgress = false;

function onStart() {
    checkedProgress = false;
    if (isCompletedBefore(2519)) {
        log("Chapter already completed!");
        stop();
        return;
    }
    acceptAllDrops();
    setSkipCutscenes(true);
    equipLoadout("farm");
}

function onTick() {
    if (isCompletedBefore(2519)) {
        log("Chapter finished!");
        stop();
        return;
    }

    // Safe house milestone check
    if (!checkedProgress) {
        if (!isHouse()) {
            ensureHouse();
            return;
        }
        if (!ensureQuestsLoaded([2239, 2240, 2241, 2379, 2519])) {
            return;
        }
        checkedProgress = true;
        log("Progress verified. Resuming saga...");
    }

    // Step-by-step quest blocks:
    if (quest(2239, "thespan")) {
        if (!mapItem(1358, "Tek's Notes", 1)) return;
        if (!mapItem(1359, "Warlic's Notes", 1)) return;
        complete(2239);
    }

    if (quest(2240, "timelibrary")) {
        if (!hunt("Sneak", "AQ Dimension Key", 1)) return;
        if (!hunt("Tog", "DF Dimension Key", 1)) return;
        complete(2240);
    }

    // Boss fight with solo class switch:
    if (quest(2519, "timespace")) {
        equipLoadout("solo");
        if (!hunt("Chaos Lord Iadoa", "Iadoa Defeated", 1)) return;
        complete(2519);
    }
}
```

---

### Pattern 2: Continuous Background Auto-Quest Farm
For repetitive gold, EXP, or reputation farming in a single zone:
```javascript
function onStart() {
    acceptAllDrops();
    equipLoadout("farm");
    join("shadowbattleon");
    autoQuest([9421, 9422, 9423]); // Runs in background
}

function onTick() {
    ensureMap("shadowbattleon");
    ensureCombat();
}

function onStop() {
    stopAutoQuest();
    stopCombat();
    ensureHouse();
}
```

---

## AI Script Generation Guide

When using an AI assistant to generate new `.hxs` scripts, provide these rules:

> **System Prompt for Script Generation:**
> 1. Always implement `function onStart()`, `function onTick()`, and `function onStop()`.
> 2. Use direct top-level methods (`quest`, `mapItem`, `hunt`, `complete`, `ensureMap`, `ensureHouse`, `hasItem`, `stop`, `log`). Do NOT use `bot.` or `map.` prefixes.
> 3. For storyline/saga quests, use the step-by-step pattern:
>    ```haxe
>    if (quest(QUEST_ID, "mapname")) {
>        if (!mapItem(ITEM_ID, "Item Name", QTY)) return;
>        if (!hunt("Monster Name", "Drop Name", QTY)) return;
>        complete(QUEST_ID);
>    }
>    ```
> 4. For multi-quest storylines, add the safe house milestone check on startup:
>    ```haxe
>    if (!checkedProgress) {
>        if (!isHouse()) { ensureHouse(); return; }
>        if (!ensureQuestsLoaded([ID1, ID2, ...])) return;
>        checkedProgress = true;
>    }
>    ```
> 5. If the quest requires items that might be in the bank, call `unbankPreset("name")` or `unbankItem([...])` in `onStart()`.
> 6. On script completion or `onStop()`, always finish safely with `ensureHouse();`.
