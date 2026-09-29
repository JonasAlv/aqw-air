package ui.prompts;

#if flash
import com.aqwapi.Api;
import com.aqwapi.modules.CombatEngine;
import com.aqwapi.modules.ScriptManager;
import com.aqwapi.managers.SkillManager;
import com.aqwapi.utils.ApiLogger;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFieldType;
import ui.ApiNotificationManager;
import ui.Dropdown;
import util.HelperSetting;

class ApiPrompts {
    private static var _lastQuests:String = "";
    private static var _lastCombat:String = "";

    public static function showQuestPrompt(overlay:Dynamic):Void {
        var isRunning:Bool = (Api.quest != null && Api.quest.isAutoRunning);
        var dlg = ApiPromptModal.createDialog(340, 200, "Auto-Quest (Safe Loop)");

        var lblInstruction = ApiPromptModal.createLabel("Enter Quest IDs (comma separated):", 300, 12, true);
        lblInstruction.x = 20;
        lblInstruction.y = 38;
        dlg.addChild(lblInstruction);

        var savedQuests = HelperSetting.getString("api_auto_quest_ids", "");
        if (savedQuests == "" && _lastQuests != "") savedQuests = _lastQuests;
        if (isRunning && Api.quest != null && Api.quest.autoQuestString != "") {
            savedQuests = Api.quest.autoQuestString;
        }

        var input = ApiPromptModal.createInput(300, 26, savedQuests);
        input.x = 20;
        input.y = 62;
        dlg.addChild(input);

        var statusColor = isRunning ? 0x00FF88 : 0x888888;
        var statusMsg = isRunning ? "Status: Active (Safe looping accept & turn-in)" : "Status: Inactive (Stopped)";
        var lblStatus = ApiPromptModal.createLabel(statusMsg, 300, 11, false);
        lblStatus.x = 20;
        lblStatus.y = 96;
        lblStatus.textColor = statusColor;
        dlg.addChild(lblStatus);

        var btnY = 145;

        if (isRunning) {
            var stopBtn = ApiPromptModal.createButton("Stop Auto-Quest", 140, 32, function():Void {
                if (Api.quest != null) Api.quest.stopAuto();
                ApiNotificationManager.notify("Auto-Quest stopped.");
                ApiPromptModal.close();
            }, true);
            stopBtn.x = 20;
            stopBtn.y = btnY;
            dlg.addChild(stopBtn);

            var updateBtn = ApiPromptModal.createButton("Update IDs", 140, 32, function():Void {
                var txt = StringTools.trim(input.text);
                HelperSetting.setString("api_auto_quest_ids", txt);
                _lastQuests = txt;
                var ids = txt.split(",");
                var validIds:Array<Int> = [];
                for (idStr in ids) {
                    var pQid:Null<Int> = Std.parseInt(StringTools.trim(idStr));
                    var qid = (pQid != null) ? pQid : 0;
                    if (qid > 0) validIds.push(qid);
                }
                if (validIds.length > 0 && Api.quest != null) {
                    Api.quest.startAuto(validIds.join(","));
                    ApiNotificationManager.notify("Auto-Quest updated: " + validIds.join(", "));
                }
                ApiPromptModal.close();
            }, false);
            updateBtn.x = 180;
            updateBtn.y = btnY;
            dlg.addChild(updateBtn);
        } else {
            var startBtn = ApiPromptModal.createButton("Start Loop", 140, 32, function():Void {
                var txt = StringTools.trim(input.text);
                HelperSetting.setString("api_auto_quest_ids", txt);
                _lastQuests = txt;
                var ids = txt.split(",");
                var validIds:Array<Int> = [];
                for (idStr in ids) {
                    var pQid:Null<Int> = Std.parseInt(StringTools.trim(idStr));
                    var qid = (pQid != null) ? pQid : 0;
                    if (qid > 0) validIds.push(qid);
                }
                if (validIds.length > 0 && Api.quest != null) {
                    Api.quest.startAuto(validIds.join(","));
                    ApiNotificationManager.notify("Auto-Quest started: " + validIds.join(", "));
                } else {
                    ApiNotificationManager.notify("Please enter at least one valid Quest ID.");
                }
                ApiPromptModal.close();
            }, true);
            startBtn.x = 20;
            startBtn.y = btnY;
            dlg.addChild(startBtn);

            var cancelBtn = ApiPromptModal.createButton("Cancel", 140, 32, function():Void {
                ApiPromptModal.close();
            }, false);
            cancelBtn.x = 180;
            cancelBtn.y = btnY;
            dlg.addChild(cancelBtn);
        }

        ApiPromptModal.show(overlay, dlg);
    }

    private static var _lastCombatMode:String = "sequence";

    public static function showCombatPrompt(overlay:Dynamic):Void {
        var dlg = ApiPromptModal.createDialog(300, 210, "AutoCombat (Custom)");

        var lblSkills = ApiPromptModal.createLabel("Skills (e.g. 3,1,2,1,2,4):", 200);
        lblSkills.x = 20;
        lblSkills.y = 38;
        dlg.addChild(lblSkills);

        var input = ApiPromptModal.createInput(260, 25, _lastCombat);
        input.x = 20;
        input.y = 58;
        dlg.addChild(input);

        var lblMode = ApiPromptModal.createLabel("Mode:", 60);
        lblMode.x = 20;
        lblMode.y = 98;
        dlg.addChild(lblMode);

        var modeOptions = ["Sequence (ordered)", "Priority (first ready)"];
        var selectedMode = _lastCombatMode;

        var ddMode = new Dropdown(220, 25, modeOptions, function(sel:String):Void {
            selectedMode = (sel.indexOf("Sequence") != -1) ? "sequence" : "priority";
        });
        ddMode.x = 20;
        ddMode.y = 118;
        ddMode.setSelectedItem(selectedMode == "sequence" ? "Sequence (ordered)" : "Priority (first ready)");
        dlg.addChild(ddMode);

        var startBtn = ApiPromptModal.createButton("Start", 120, 30, function():Void {
            _lastCombat = input.text;
            _lastCombatMode = selectedMode;
            var seq = _lastCombat.split(",");
            var validSeq:Array<String> = [];
            for (s in seq) {
                var trimmed = StringTools.trim(s);
                if (trimmed.length > 0) validSeq.push(trimmed);
            }
            if (validSeq.length > 0 && Api.combat != null) {
                Api.combat.startCustom(validSeq.join(","), selectedMode);
            }
            ApiPromptModal.close();
        }, false);
        startBtn.x = 20;
        startBtn.y = 162;
        dlg.addChild(startBtn);

        var cancelBtn = ApiPromptModal.createButton("Cancel", 120, 30, function():Void {
            ApiPromptModal.close();
        }, false);
        cancelBtn.x = 160;
        cancelBtn.y = 162;
        dlg.addChild(cancelBtn);

        ApiPromptModal.show(overlay, dlg);
    }

    public static function showBlacklistPrompt(overlay:Dynamic):Void {
        _renderBlacklistPrompt(overlay);
    }

    private static function _renderBlacklistPrompt(overlay:Dynamic):Void {
        var dlgW:Int = 360;
        var dlgH:Int = 450;
        var dlg = ApiPromptModal.createDialog(dlgW, dlgH, "Item Blacklist");

        // Subtitle / Description
        var desc = ApiPromptModal.createLabel("Items here are never looted and can be mass-sold via 'Sell Blacklisted Items'.", dlgW - 40, 11, false);
        desc.x = 20;
        desc.y = 30;
        desc.wordWrap = true;
        desc.height = 32;
        dlg.addChild(desc);

        // List area
        var listY:Int = 68;
        var listH:Int = 240;
        var listW:Int = dlgW - 40;
        var listContainer = new Sprite();
        listContainer.x = 20;
        listContainer.y = listY;
        listContainer.graphics.beginFill(0x161616, 0.95);
        listContainer.graphics.lineStyle(1, 0x333333);
        listContainer.graphics.drawRoundRect(0, 0, listW, listH, 6, 6);
        listContainer.graphics.endFill();
        dlg.addChild(listContainer);

        var items = (Api.blacklist != null) ? Api.blacklist.getList() : [];
        var rowH:Int = 28;
        var maxRows:Int = Std.int((listH - 8) / rowH);

        if (items.length == 0) {
            var emptyLbl = ApiPromptModal.createLabel("No items blacklisted yet.", listW - 20, 12, false);
            emptyLbl.x = 14;
            emptyLbl.y = 14;
            listContainer.addChild(emptyLbl);
        } else {
            var displayCount = items.length < maxRows ? items.length : maxRows;
            for (i in 0...displayCount) {
                var itemName:String = items[i];
                var row = new Sprite();
                row.x = 8;
                row.y = i * rowH + 6;

                if (i % 2 == 1) {
                    row.graphics.beginFill(0x222222, 0.4);
                    row.graphics.drawRoundRect(0, 0, listW - 16, rowH - 4, 4, 4);
                    row.graphics.endFill();
                }

                var lbl = ApiPromptModal.createLabel(itemName, listW - 70, 12, false);
                lbl.x = 8;
                lbl.y = 3;
                lbl.height = 20;
                row.addChild(lbl);

                var removeBtn = ApiPromptModal.createButton("X", 28, 20, function():Void {
                    if (Api.blacklist != null) Api.blacklist.remove(itemName);
                    _renderBlacklistPrompt(overlay);
                }, false);
                removeBtn.x = listW - 54;
                removeBtn.y = 1;
                row.addChild(removeBtn);

                listContainer.addChild(row);
            }

            if (items.length > maxRows) {
                var moreLbl = ApiPromptModal.createLabel("+ " + (items.length - maxRows) + " more items", listW - 20, 10, false);
                moreLbl.x = 14;
                moreLbl.y = listH - 20;
                listContainer.addChild(moreLbl);
            }
        }

        // Add section
        var addY:Int = listY + listH + 12;
        var addLabel = ApiPromptModal.createLabel("Add item by name:", 200, 11, true);
        addLabel.x = 20;
        addLabel.y = addY;
        addLabel.height = 18;
        dlg.addChild(addLabel);

        var inputW:Int = dlgW - 40 - 74;
        var input = ApiPromptModal.createInput(inputW, 26, "");
        input.x = 20;
        input.y = addY + 18;
        dlg.addChild(input);

        var addBtn = ApiPromptModal.createButton("Add", 66, 26, function():Void {
            var name = StringTools.trim(input.text);
            if (name != "" && Api.blacklist != null) {
                Api.blacklist.add(name);
                _renderBlacklistPrompt(overlay);
            }
        }, false);
        addBtn.x = 20 + inputW + 8;
        addBtn.y = addY + 18;
        dlg.addChild(addBtn);

        // Close button
        var closeBtn = ApiPromptModal.createButton("Close", 120, 30, function():Void {
            ApiPromptModal.close();
        }, false);
        closeBtn.x = (dlgW - 120) / 2;
        closeBtn.y = dlgH - 42;
        dlg.addChild(closeBtn);

        ApiPromptModal.show(overlay, dlg);
    }

    public static function showShopPrompt(overlay:Dynamic):Void {
        var dlg = ApiPromptModal.createDialog(300, 160, "Enter Shop ID:");

        var input = ApiPromptModal.createInput(260, 25, "");
        input.x = 20;
        input.y = 40;
        dlg.addChild(input);

        var loadBtn = ApiPromptModal.createButton("Load", 120, 30, function():Void {
            var pShopId:Null<Int> = Std.parseInt(StringTools.trim(input.text));
            var shopId = (pShopId != null) ? pShopId : 0;
            ApiPromptModal.close();
            if (shopId > 0 && Api.shop != null) {
                Api.shop.loadShop(shopId);
                ApiNotificationManager.notify("Loading Shop: " + shopId);
            }
        }, false);
        loadBtn.x = 20;
        loadBtn.y = 80;
        dlg.addChild(loadBtn);

        var cancelBtn = ApiPromptModal.createButton("Cancel", 120, 30, function():Void {
            ApiPromptModal.close();
        }, false);
        cancelBtn.x = 160;
        cancelBtn.y = 80;
        dlg.addChild(cancelBtn);

        ApiPromptModal.show(overlay, dlg);
    }

    public static function showPastePrompt(overlay:Dynamic):Void {
        var dlg = ApiPromptModal.createDialog(600, 400, "Paste Script Below");

        var input = ApiPromptModal.createInput(560, 300, "", true);
        input.x = 20;
        input.y = 40;
        dlg.addChild(input);

        var loadBtn = ApiPromptModal.createButton("Load Script", 120, 30, function():Void {
            var txt = input.text;
            ApiPromptModal.close();
            ScriptManager.SINGLETON.loadScript(txt);
            ApiNotificationManager.notify("Script loaded successfully!");
        }, false);
        loadBtn.x = 160;
        loadBtn.y = 350;
        dlg.addChild(loadBtn);

        var cancelBtn = ApiPromptModal.createButton("Cancel", 120, 30, function():Void {
            ApiPromptModal.close();
        }, false);
        cancelBtn.x = 320;
        cancelBtn.y = 350;
        dlg.addChild(cancelBtn);

        ApiPromptModal.show(overlay, dlg);
    }

    public static function showEnhancementPrompt(
        overlay:Dynamic,
        promptTitle:String,
        shops:Array<{ name:String, id:Int }>,
        requireForge:Bool = false
    ):Void {
        var dlg = ApiPromptModal.createDialog(340, 180, promptTitle);

        var shopNames:Array<String> = [];
        for (s in shops) shopNames.push(s.name);

        var selectedId:Int = shops.length > 0 ? shops[0].id : 0;
        var selectedName:String = shops.length > 0 ? shops[0].name : "";

        var ddShop = new Dropdown(260, 30, shopNames, function(sel:String):Void {
            selectedName = sel;
            for (s in shops) {
                if (s.name == sel) {
                    selectedId = s.id;
                    break;
                }
            }
        });
        ddShop.x = 40;
        ddShop.y = 55;
        dlg.addChild(ddShop);

        var loadBtn = ApiPromptModal.createButton("Load Shop", 120, 35, function():Void {
            ApiPromptModal.close();
            if (requireForge) {
                if (Api.map != null && Api.map.name != null && Api.map.name.toLowerCase() != "forge") {
                    Api.map.join("forge", "Enter", "Spawn");
                    ApiNotificationManager.notify("Joining forge map...");
                    haxe.Timer.delay(function():Void {
                        if (Api.shop != null) Api.shop.loadShop(selectedId);
                        ApiNotificationManager.notify("Loading Shop: " + selectedName);
                    }, 3500);
                    return;
                }
            }
            if (Api.shop != null) Api.shop.loadShop(selectedId);
            ApiNotificationManager.notify("Loading Shop: " + selectedName);
        }, true);
        loadBtn.x = 40;
        loadBtn.y = 120;
        dlg.addChild(loadBtn);

        var cancelBtn = ApiPromptModal.createButton("Cancel", 100, 35, function():Void {
            ApiPromptModal.close();
        }, false);
        cancelBtn.x = 180;
        cancelBtn.y = 120;
        dlg.addChild(cancelBtn);

        ApiPromptModal.show(overlay, dlg);
    }

    public static function showCustomEnhancePrompt(overlay:Dynamic):Void {
        try {
            var dlg = ApiPromptModal.createDialog(460, 320, "Custom Enhancement Setup");

            var curClass:String = (Api.player != null && Api.player.className != null && Api.player.className != "") ? Api.player.className : "Equipped Class";
            var rec = (Api.enhancement != null) ? Api.enhancement.getRecommendation(curClass) : null;

            var recSummary:String = "Equipped: " + curClass;
            if (rec != null) {
                recSummary += "  (Optimal: " + rec.type;
                if (rec.weapon != null && rec.weapon != "" && rec.weapon != "None") recSummary += " + " + rec.weapon;
                if (rec.helm != null && rec.helm != "" && rec.helm != "None") recSummary += " | " + rec.helm;
                if (rec.cape != null && rec.cape != "" && rec.cape != "None") recSummary += " | " + rec.cape;
                recSummary += ")";
            }

            var lblSummary = ApiPromptModal.createLabel(recSummary, 420, 11, false);
            lblSummary.x = 20;
            lblSummary.y = 38;
            dlg.addChild(lblSummary);

            // Row 1: Base Type & Weapon Trait
            var lblBase = ApiPromptModal.createLabel("Base Type (All Gear):", 190, 12, true);
            lblBase.x = 25;
            lblBase.y = 65;
            dlg.addChild(lblBase);

            var lblWeapon = ApiPromptModal.createLabel("Weapon Special Trait:", 190, 12, true);
            lblWeapon.x = 245;
            lblWeapon.y = 65;
            dlg.addChild(lblWeapon);

            var baseOptions = ["Lucky", "Wizard", "Fighter", "Thief", "Healer", "Hybrid", "Spellbreaker"];
            var weaponOptions = ["None", "Spiral Carve", "Awe Blast", "Health Vamp", "Mana Vamp", "Powerword Die", "Smite", "Valiance", "Arcana's Concerto", "Elysium", "Acheron", "Dauntless", "Praxis"];
            var helmOptions = ["None", "Forge", "Vim", "Examen", "Anima", "Pneuma"];
            var capeOptions = ["None", "Forge", "Absolution", "Vainglory", "Avarice", "Penitence", "Lament"];

            var selectedBase:String = (rec != null && rec.type != null) ? rec.type : "Lucky";
            var selectedWeapon:String = (rec != null && rec.weapon != null) ? rec.weapon : "None";
            var selectedHelm:String = (rec != null && rec.helm != null) ? rec.helm : "None";
            var selectedCape:String = (rec != null && rec.cape != null) ? rec.cape : "None";

            var ddBase = new Dropdown(190, 26, baseOptions, function(sel:String):Void {
                selectedBase = sel;
            });
            ddBase.x = 25;
            ddBase.y = 85;
            ddBase.setSelectedItem(selectedBase);

            var ddWeapon = new Dropdown(190, 26, weaponOptions, function(sel:String):Void {
                selectedWeapon = sel;
            });
            ddWeapon.x = 245;
            ddWeapon.y = 85;
            ddWeapon.setSelectedItem(selectedWeapon);

            // Row 2: Helm Trait & Cape Trait
            var lblHelm = ApiPromptModal.createLabel("Helm Special Trait:", 190, 12, true);
            lblHelm.x = 25;
            lblHelm.y = 125;
            dlg.addChild(lblHelm);

            var lblCape = ApiPromptModal.createLabel("Cape Special Trait:", 190, 12, true);
            lblCape.x = 245;
            lblCape.y = 125;
            dlg.addChild(lblCape);

            var ddHelm = new Dropdown(190, 26, helmOptions, function(sel:String):Void {
                selectedHelm = sel;
            });
            ddHelm.x = 25;
            ddHelm.y = 145;
            ddHelm.setSelectedItem(selectedHelm);

            var ddCape = new Dropdown(190, 26, capeOptions, function(sel:String):Void {
                selectedCape = sel;
            });
            ddCape.x = 245;
            ddCape.y = 145;
            ddCape.setSelectedItem(selectedCape);

            dlg.addChild(ddBase);
            dlg.addChild(ddWeapon);
            dlg.addChild(ddHelm);
            dlg.addChild(ddCape);

            // Quick Shortcut: Apply Recommended
            var bestBtn = ApiPromptModal.createButton("Apply Recommended", 140, 26, function():Void {
                var c = (Api.player != null && Api.player.className != null && Api.player.className != "") ? Api.player.className : "";
                var r = (Api.enhancement != null) ? Api.enhancement.getRecommendation(c) : null;
                if (r != null) {
                    selectedBase = r.type;
                    selectedWeapon = r.weapon;
                    selectedHelm = r.helm;
                    selectedCape = r.cape;
                    ddBase.setSelectedItem(selectedBase);
                    ddWeapon.setSelectedItem(selectedWeapon);
                    ddHelm.setSelectedItem(selectedHelm);
                    ddCape.setSelectedItem(selectedCape);
                    ApiNotificationManager.notify("Applied recommendation: " + r.type);
                }
            }, false);
            bestBtn.x = 25;
            bestBtn.y = 195;
            dlg.addChild(bestBtn);

            var resetBtn = ApiPromptModal.createButton("Base Only (No Forge)", 140, 26, function():Void {
                selectedWeapon = "None";
                selectedHelm = "None";
                selectedCape = "None";
                ddWeapon.setSelectedItem("None");
                ddHelm.setSelectedItem("None");
                ddCape.setSelectedItem("None");
                ApiNotificationManager.notify("Cleared special traits (Base only)");
            }, false);
            resetBtn.x = 180;
            resetBtn.y = 195;
            dlg.addChild(resetBtn);

            // Bottom Action Buttons
            var enhanceBtn = ApiPromptModal.createButton("Enhance Equipped", 150, 36, function():Void {
                ApiPromptModal.close();
                if (Api.enhancement != null) {
                    if (Api.enhancement.isBusy) {
                        ApiNotificationManager.notify("Enhancement queue is currently busy!");
                        return;
                    }
                    ApiNotificationManager.notify("Enhancing: " + selectedBase + " (W:" + selectedWeapon + ", H:" + selectedHelm + ", C:" + selectedCape + ")");
                    Api.enhancement.enhanceEquipped(selectedBase, selectedCape, selectedHelm, selectedWeapon, function():Void {
                        ApiNotificationManager.notify("Custom enhancement complete!");
                    });
                }
            }, true);
            enhanceBtn.x = 25;
            enhanceBtn.y = 255;
            dlg.addChild(enhanceBtn);

            var smartBtn = ApiPromptModal.createButton("Smart Auto", 120, 36, function():Void {
                ApiPromptModal.close();
                if (Api.enhancement != null) {
                    if (Api.enhancement.isBusy) {
                        ApiNotificationManager.notify("Enhancement queue is currently busy!");
                        return;
                    }
                    var c = (Api.player != null) ? Api.player.className : "Equipped";
                    ApiNotificationManager.notify("SmartEnhancing " + c + "...");
                    Api.enhancement.smartEnhance(null, function():Void {
                        ApiNotificationManager.notify("SmartEnhance finished!");
                    });
                }
            }, false);
            smartBtn.x = 190;
            smartBtn.y = 255;
            dlg.addChild(smartBtn);

            var cancelBtn = ApiPromptModal.createButton("Cancel", 100, 36, function():Void {
                ApiPromptModal.close();
            }, false);
            cancelBtn.x = 325;
            cancelBtn.y = 255;
            dlg.addChild(cancelBtn);

            ApiPromptModal.show(overlay, dlg);
        } catch (e:Dynamic) {
            ApiLogger.error("Prompt", "Error showing custom enhance prompt: " + e);
            ApiNotificationManager.notify("Error: " + e);
        }
    }

    public static function showSmartCombatPrompt(overlay:Dynamic):Void {
        try {
            var dlg = ApiPromptModal.createDialog(420, 260, "Smart Combat Setup (Standalone)");

            var lblSub = ApiPromptModal.createLabel("Standalone Smart Combat setup. For scripts, use Loadouts in Scripts tab.", 380, 11);
            lblSub.x = 20;
            lblSub.y = 38;
            lblSub.textColor = 0x888888;
            dlg.addChild(lblSub);

            var lblClass = ApiPromptModal.createLabel("Class:", 60);
            lblClass.x = 20;
            lblClass.y = 65;
            dlg.addChild(lblClass);

            var lblMode = ApiPromptModal.createLabel("Mode:", 60);
            lblMode.x = 220;
            lblMode.y = 65;
            dlg.addChild(lblMode);

            var availableClasses = getAvailableClasses();
            if (availableClasses == null || availableClasses.length == 0) availableClasses = ["Current"];

            var selectedClassStr = HelperSetting.getString("api_smart_class", "Current");
            if (selectedClassStr == "" || availableClasses.indexOf(selectedClassStr) == -1) {
                selectedClassStr = "Current";
            }

            var getModesForClass = function(cName:String):Array<String> {
                var modes:Array<String> = [];
                var isCurrent = (cName == null || cName == "" || cName.toLowerCase() == "current");
                if (isCurrent) {
                    modes.push("Auto (First Available)");
                    var curName = CombatEngine.getCurrentClassName();
                    if (curName != "") {
                        try {
                            var detectedModes = CombatEngine.getAvailableModes(curName);
                            if (detectedModes != null) {
                                for (m in detectedModes) if (modes.indexOf(m) == -1) modes.push(m);
                            }
                        } catch (_:Dynamic) {}
                    }
                } else {
                    try {
                        modes = CombatEngine.getAvailableModes(cName);
                    } catch (_:Dynamic) {}
                }
                if (modes == null || modes.length == 0) modes = ["Base"];
                return modes;
            };

            var availableModes:Array<String> = getModesForClass(selectedClassStr);
            var selectedModeStr = HelperSetting.getString("api_smart_mode", "Auto");
            if (selectedClassStr == "Current" && (selectedModeStr == "" || selectedModeStr == "Auto")) {
                selectedModeStr = "Auto (First Available)";
            } else if (selectedModeStr == null || selectedModeStr == "" || availableModes.indexOf(selectedModeStr) == -1) {
                selectedModeStr = availableModes.length > 0 ? availableModes[0] : "Base";
            }

            var ddMode:Dropdown = null;
            ddMode = new Dropdown(150, 25, availableModes, function(sel:String):Void {
                selectedModeStr = sel;
            });
            ddMode.x = 220;
            ddMode.y = 95;
            ddMode.setSelectedItem(selectedModeStr);

            var ddClass:Dropdown = null;
            ddClass = new Dropdown(180, 25, availableClasses, function(sel:String):Void {
                selectedClassStr = sel;
                var modes = getModesForClass(selectedClassStr);
                ddMode.setOptions(modes);
                if (modes.indexOf(selectedModeStr) == -1) {
                    selectedModeStr = (selectedClassStr == "Current") ? "Auto (First Available)" : (modes.length > 0 ? modes[0] : "Base");
                }
                ddMode.setSelectedItem(selectedModeStr);
            });
            ddClass.x = 20;
            ddClass.y = 95;
            ddClass.setSelectedItem(selectedClassStr);

            dlg.addChild(ddMode);
            dlg.addChild(ddClass);

            var saveBtn = ApiPromptModal.createButton("Save & Apply", 130, 35, function():Void {
                var saveModeVal = (selectedModeStr == "Auto (First Available)") ? "Auto" : selectedModeStr;
                HelperSetting.setString("api_smart_class", selectedClassStr);
                HelperSetting.setString("api_smart_mode", saveModeVal);
                CombatEngine.smartClass = selectedClassStr;
                CombatEngine.skillMode = saveModeVal;
                if (selectedClassStr != "" && selectedClassStr != "Current" && Api.inventory != null) {
                    Api.inventory.equip(selectedClassStr);
                }
                if (Api.combat != null) {
                    Api.combat.mode = saveModeVal;
                }
                ApiNotificationManager.notify("Smart Combat: " + selectedClassStr + " [" + saveModeVal + "]");
                ApiPromptModal.close();
            }, true);
            saveBtn.x = 20;
            saveBtn.y = 200;
            dlg.addChild(saveBtn);

            var editModesBtn = ApiPromptModal.createButton("Edit Modes", 120, 35, function():Void {
                ApiPromptModal.close();
                showCombatModeEditorPrompt(overlay, selectedClassStr, selectedModeStr);
            }, false);
            editModesBtn.x = 160;
            editModesBtn.y = 200;
            dlg.addChild(editModesBtn);

            var cancelBtn = ApiPromptModal.createButton("Cancel", 100, 35, function():Void {
                ApiPromptModal.close();
            }, false);
            cancelBtn.x = 295;
            cancelBtn.y = 200;
            dlg.addChild(cancelBtn);

            ApiPromptModal.show(overlay, dlg);
        } catch (e:Dynamic) {
            var stackTrace:String = "";
            #if flash
            if (Std.isOfType(e, flash.errors.Error)) {
                stackTrace = "\n" + (cast e : flash.errors.Error).getStackTrace();
            }
            #end
            ApiLogger.error("Prompt", "Failed to show AutoCombat setup prompt: " + e + stackTrace);
            ApiNotificationManager.notify("Error opening setup: " + e);
        }
    }

    public static function showCombatModeEditorPrompt(overlay:Dynamic, initialClass:String = null, initialMode:String = null):Void {
        try {
            try { SkillManager.ensureStorageInitialized(); } catch (_:Dynamic) {}
            var dlg = ApiPromptModal.createDialog(560, 475, "Combat Mode Editor");

            // Gather class options (Strictly classes currently in inventory + Current)
            var classOptions:Array<String> = getAvailableClasses();
            var curEquipped = CombatEngine.getCurrentClassName();
            var selectedClass = (initialClass != null && initialClass != "" && classOptions.indexOf(initialClass) != -1)
                ? initialClass
                : "Current";
            if (selectedClass == null || selectedClass == "" || classOptions.indexOf(selectedClass) == -1) {
                selectedClass = classOptions.length > 0 ? classOptions[0] : "Current";
            }

            var initialInputClass = selectedClass;
            if (selectedClass.toLowerCase() == "current" && curEquipped != null && curEquipped != "" && curEquipped.toLowerCase() != "current") {
                initialInputClass = curEquipped;
            }

            var lblClass = ApiPromptModal.createLabel("Select Class:", 120);
            lblClass.x = 25;
            lblClass.y = 40;
            dlg.addChild(lblClass);

            var lblCustomClass = ApiPromptModal.createLabel("Class Name:", 120);
            lblCustomClass.x = 265;
            lblCustomClass.y = 40;
            dlg.addChild(lblCustomClass);

            var inputClass = ApiPromptModal.createInput(270, 24, initialInputClass);
            inputClass.x = 265;
            inputClass.y = 60;
            dlg.addChild(inputClass);

            var lblMode = ApiPromptModal.createLabel("Select Mode:", 120);
            lblMode.x = 25;
            lblMode.y = 92;
            dlg.addChild(lblMode);

            var lblCustomMode = ApiPromptModal.createLabel("Mode Name:", 120);
            lblCustomMode.x = 265;
            lblCustomMode.y = 92;
            dlg.addChild(lblCustomMode);

            var inputMode = ApiPromptModal.createInput(270, 24, "Base");
            inputMode.x = 265;
            inputMode.y = 112;
            dlg.addChild(inputMode);

            var lblExecMode = ApiPromptModal.createLabel("Execution Mode:", 120);
            lblExecMode.x = 25;
            lblExecMode.y = 144;
            dlg.addChild(lblExecMode);

            var lblTimeout = ApiPromptModal.createLabel("Timeout (ms):", 90);
            lblTimeout.x = 240;
            lblTimeout.y = 144;
            dlg.addChild(lblTimeout);

            var inputTimeout = ApiPromptModal.createInput(80, 24, "0");
            inputTimeout.x = 240;
            inputTimeout.y = 164;
            dlg.addChild(inputTimeout);

            var lblBadge = ApiPromptModal.createLabel("[Bundled Mode]", 200, 13, true);
            lblBadge.x = 340;
            lblBadge.y = 166;
            dlg.addChild(lblBadge);

            var lblStopAuras = ApiPromptModal.createLabel("Stop on Target Auras (Reflect / Shields):", 350);
            lblStopAuras.x = 25;
            lblStopAuras.y = 196;
            dlg.addChild(lblStopAuras);

            var inputStopAuras = ApiPromptModal.createInput(510, 24, "");
            inputStopAuras.x = 25;
            inputStopAuras.y = 216;
            dlg.addChild(inputStopAuras);

            var lblCombo = ApiPromptModal.createLabel("Skill Combo / Rotation (1-Liner DSL):", 300);
            lblCombo.x = 25;
            lblCombo.y = 246;
            dlg.addChild(lblCombo);

            var inputCombo = ApiPromptModal.createInput(510, 44, "", true);
            inputCombo.x = 25;
            inputCombo.y = 266;
            dlg.addChild(inputCombo);

            var ddExecMode:Dropdown = null;
            var ddMode:Dropdown = null;
            var ddClass:Dropdown = null;
            var helperButtons:Array<flash.display.Sprite> = [];
            var saveBtn:flash.display.Sprite = null;
            var applyBtn:flash.display.Sprite = null;
            var delBtn:flash.display.Sprite = null;

            var setInputEnabled = function(tf:TextField, enabled:Bool):Void {
                if (tf == null) return;
                #if flash
                tf.type = enabled ? flash.text.TextFieldType.INPUT : flash.text.TextFieldType.DYNAMIC;
                #end
                tf.selectable = enabled;
                tf.mouseEnabled = enabled;
                tf.backgroundColor = enabled ? 0x222222 : 0x141414;
                tf.borderColor = enabled ? 0x555555 : 0x333333;
                tf.textColor = enabled ? 0xFFFFFF : 0x777777;
                tf.alpha = enabled ? 1.0 : 0.6;
            };

            var setButtonEnabled = function(btn:flash.display.Sprite, enabled:Bool):Void {
                if (btn == null) return;
                btn.mouseEnabled = enabled;
                btn.mouseChildren = false;
                btn.buttonMode = enabled;
                btn.alpha = enabled ? 1.0 : 0.35;
            };

            var setFormEditable = function(isEditable:Bool, isNewMode:Bool):Void {
                setInputEnabled(inputClass, isEditable);
                setInputEnabled(inputMode, isEditable);
                setInputEnabled(inputTimeout, isEditable);
                setInputEnabled(inputStopAuras, isEditable);
                setInputEnabled(inputCombo, isEditable);

                if (ddExecMode != null) {
                    ddExecMode.mouseEnabled = isEditable;
                    ddExecMode.mouseChildren = isEditable;
                    ddExecMode.alpha = isEditable ? 1.0 : 0.4;
                }

                if (helperButtons != null) {
                    for (b in helperButtons) {
                        setButtonEnabled(b, isEditable);
                    }
                }

                setButtonEnabled(saveBtn, isEditable);
                setButtonEnabled(delBtn, isEditable && !isNewMode);
                setButtonEnabled(applyBtn, !isNewMode);
            };

            var loadModeDetails = function(cName:String, mName:String):Void {
                if (mName == null || mName == "" || mName == "[+ New Mode]") {
                    if (inputMode != null) inputMode.text = "CustomMode";
                    if (ddExecMode != null) ddExecMode.setSelectedItem("WaitForCooldown");
                    if (inputTimeout != null) inputTimeout.text = "0";
                    if (inputStopAuras != null) inputStopAuras.text = "";
                    if (inputCombo != null) inputCombo.text = "";
                    if (lblBadge != null) {
                        lblBadge.text = "[New Mode]";
                        lblBadge.textColor = 0x55FF55;
                    }
                    setFormEditable(true, true);
                    return;
                }

                var effectiveClass = cName;
                if (effectiveClass == null || effectiveClass == "" || effectiveClass.toLowerCase() == "current") {
                    var cur = CombatEngine.getCurrentClassName();
                    if (cur != null && cur != "" && cur.toLowerCase() != "current") {
                        effectiveClass = cur;
                    }
                }

                if (inputMode != null) inputMode.text = (mName != null) ? mName : "";
                var details = SkillManager.getModeDetails(effectiveClass, mName);
                if (details == null && effectiveClass != cName) {
                    details = SkillManager.getModeDetails(cName, mName);
                }
                if (details != null) {
                    if (ddExecMode != null) {
                        var eMode:String = (details.skillUseMode != null && details.skillUseMode != "") ? details.skillUseMode : "WaitForCooldown";
                        ddExecMode.setSelectedItem(eMode);
                    }
                    if (inputTimeout != null) {
                        var toVal:Int = (details.timeout != null) ? details.timeout : 0;
                        inputTimeout.text = (toVal > 1500) ? Std.string(toVal) : "0";
                    }
                    if (inputStopAuras != null) inputStopAuras.text = (details.stopOnTargetAuras != null) ? details.stopOnTargetAuras : "";
                    if (inputCombo != null) inputCombo.text = (details.combo != null) ? details.combo : "";

                    var isUser:Bool = (details.isUser == true) || SkillManager.isUserMode(effectiveClass, mName) || SkillManager.isUserMode(cName, mName);
                    if (lblBadge != null) {
                        if (isUser) {
                            lblBadge.text = "[User Mode]";
                            lblBadge.textColor = 0x00D9FF;
                        } else {
                            lblBadge.text = "[Bundled Mode]";
                            lblBadge.textColor = 0x888888;
                        }
                    }
                    setFormEditable(isUser, false);
                } else {
                    if (ddExecMode != null) ddExecMode.setSelectedItem("WaitForCooldown");
                    if (inputTimeout != null) inputTimeout.text = "0";
                    if (inputStopAuras != null) inputStopAuras.text = "";
                    if (inputCombo != null) inputCombo.text = "";
                    if (lblBadge != null) {
                        lblBadge.text = "[New Mode]";
                        lblBadge.textColor = 0x55FF55;
                    }
                    setFormEditable(true, true);
                }
            };

            var getModeListForClass = function(cName:String):Array<String> {
                var list:Array<String> = [];
                try {
                    var modes = CombatEngine.getAvailableModes(cName);
                    if (modes != null) {
                        for (m in modes) {
                            if (m != null && m != "" && list.indexOf(m) == -1) list.push(m);
                        }
                    }
                } catch (_:Dynamic) {}
                if (list.indexOf("Base") == -1) {
                    list.unshift("Base");
                }
                list.push("[+ New Mode]");
                return list;
            };

            ddExecMode = new Dropdown(200, 24, ["WaitForCooldown", "UseIfAvailable"], function(sel:String):Void {});
            ddExecMode.x = 25;
            ddExecMode.y = 164;
            ddExecMode.setSelectedItem("WaitForCooldown");

            var initialModes = getModeListForClass(selectedClass);
            var initialSelMode = (initialMode != null && initialMode != "" && initialModes.indexOf(initialMode) != -1) ? initialMode : (initialModes.length > 0 ? initialModes[0] : "[+ New Mode]");

            ddMode = new Dropdown(220, 24, initialModes, function(selMode:String):Void {
                var currentClass = (inputClass != null && inputClass.text != null) ? StringTools.trim(inputClass.text) : "";
                if (currentClass == "") currentClass = selectedClass;
                loadModeDetails(currentClass, selMode);
            });
            ddMode.x = 25;
            ddMode.y = 112;
            ddMode.setSelectedItem(initialSelMode);

            ddClass = new Dropdown(220, 24, classOptions, function(selClass:String):Void {
                selectedClass = selClass;
                if (inputClass != null) {
                    if (selClass.toLowerCase() == "current") {
                        var cur = CombatEngine.getCurrentClassName();
                        inputClass.text = (cur != null && cur != "" && cur.toLowerCase() != "current") ? cur : "";
                    } else {
                        inputClass.text = selClass;
                    }
                }

                var modes = getModeListForClass(selClass);
                if (ddMode != null) ddMode.setOptions(modes);
                var firstMode = (modes.length > 0 && modes[0] != null) ? modes[0] : "[+ New Mode]";
                if (ddMode != null) ddMode.setSelectedItem(firstMode);
                loadModeDetails(selClass, firstMode);
            });
            ddClass.x = 25;
            ddClass.y = 60;
            ddClass.setSelectedItem(classOptions.indexOf(selectedClass) != -1 ? selectedClass : (classOptions.length > 0 ? classOptions[0] : ""));

            dlg.addChild(ddExecMode);
            dlg.addChild(ddMode);
            dlg.addChild(ddClass);

            var appendSkill = function(sid:String):Void {
                var cur = StringTools.trim(inputCombo.text);
                if (cur.length == 0) {
                    inputCombo.text = sid;
                } else if (StringTools.endsWith(cur, ">")) {
                    inputCombo.text = cur + " " + sid;
                } else {
                    inputCombo.text = cur + " > " + sid;
                }
            };

            var appendRule = function(rule:String):Void {
                var cur = StringTools.trim(inputCombo.text);
                if (cur.length == 0) {
                    inputCombo.text = "1" + rule;
                } else if (StringTools.endsWith(cur, ">")) {
                    inputCombo.text = cur + " 1" + rule;
                } else {
                    if (StringTools.endsWith(cur, "]")) {
                        var innerRule = rule.substring(1, rule.length - 1);
                        inputCombo.text = cur.substring(0, cur.length - 1) + " & " + innerRule + "]";
                    } else {
                        inputCombo.text = cur + rule;
                    }
                }
            };

            // Quick helper row 1: skills and basic operators
            var b1 = ApiPromptModal.createButton("+1", 28, 24, function() appendSkill("1"), false);
            b1.x = 25; b1.y = 318; dlg.addChild(b1); helperButtons.push(b1);

            var b2 = ApiPromptModal.createButton("+2", 28, 24, function() appendSkill("2"), false);
            b2.x = 57; b2.y = 318; dlg.addChild(b2); helperButtons.push(b2);

            var b3 = ApiPromptModal.createButton("+3", 28, 24, function() appendSkill("3"), false);
            b3.x = 89; b3.y = 318; dlg.addChild(b3); helperButtons.push(b3);

            var b4 = ApiPromptModal.createButton("+4", 28, 24, function() appendSkill("4"), false);
            b4.x = 121; b4.y = 318; dlg.addChild(b4); helperButtons.push(b4);

            var b5 = ApiPromptModal.createButton("+5", 28, 24, function() appendSkill("5"), false);
            b5.x = 153; b5.y = 318; dlg.addChild(b5); helperButtons.push(b5);

            var bArrow = ApiPromptModal.createButton("+ >", 32, 24, function():Void {
                var cur = StringTools.trim(inputCombo.text);
                if (cur.length > 0 && !StringTools.endsWith(cur, ">")) {
                    inputCombo.text = cur + " >";
                }
            }, false);
            bArrow.x = 185; bArrow.y = 318; dlg.addChild(bArrow); helperButtons.push(bArrow);

            var b14 = ApiPromptModal.createButton("+ 1-4", 42, 24, function():Void {
                var cur = StringTools.trim(inputCombo.text);
                if (cur.length == 0) {
                    inputCombo.text = "1 > 2 > 3 > 4";
                } else if (StringTools.endsWith(cur, ">")) {
                    inputCombo.text = cur + " 1 > 2 > 3 > 4";
                } else {
                    inputCombo.text = cur + " > 1 > 2 > 3 > 4";
                }
            }, false);
            b14.x = 221; b14.y = 318; dlg.addChild(b14); helperButtons.push(b14);

            var bClear = ApiPromptModal.createButton("Clear", 40, 24, function():Void {
                inputCombo.text = "";
            }, false);
            bClear.x = 267; bClear.y = 318; dlg.addChild(bClear); helperButtons.push(bClear);

            var bHp = ApiPromptModal.createButton("+[hp < 50%]", 74, 24, function() appendRule("[hp < 50%]"), false);
            bHp.x = 311; bHp.y = 318; dlg.addChild(bHp); helperButtons.push(bHp);

            var bTgtHp = ApiPromptModal.createButton("+[tgt:hp < 50%]", 88, 24, function() appendRule("[tgt:hp < 50%]"), false);
            bTgtHp.x = 389; bTgtHp.y = 318; dlg.addChild(bTgtHp); helperButtons.push(bTgtHp);

            var bMp = ApiPromptModal.createButton("+[mp < 20%]", 54, 24, function() appendRule("[mp < 20%]"), false);
            bMp.x = 481; bMp.y = 318; dlg.addChild(bMp); helperButtons.push(bMp);

            // Quick helper row 2: auras and conditions
            var bAuraSelf = ApiPromptModal.createButton("+[!aura(self:Name)]", 108, 24, function() appendRule("[!aura(self:Name)]"), false);
            bAuraSelf.x = 25; bAuraSelf.y = 348; dlg.addChild(bAuraSelf); helperButtons.push(bAuraSelf);

            var bAuraTgt = ApiPromptModal.createButton("+[aura(target:Name)]", 112, 24, function() appendRule("[aura(target:Name)]"), false);
            bAuraTgt.x = 137; bAuraTgt.y = 348; dlg.addChild(bAuraTgt); helperButtons.push(bAuraTgt);

            var bAuraTime = ApiPromptModal.createButton("+[auraTime(self:Name) <= 1.5s]", 152, 24, function() appendRule("[auraTime(self:Name) <= 1.5s]"), false);
            bAuraTime.x = 253; bAuraTime.y = 348; dlg.addChild(bAuraTime); helperButtons.push(bAuraTime);

            var bParty = ApiPromptModal.createButton("+[party:hp < 50%]", 78, 24, function() appendRule("[party:hp < 50%]"), false);
            bParty.x = 409; bParty.y = 348; dlg.addChild(bParty); helperButtons.push(bParty);

            var bWait = ApiPromptModal.createButton("+wait", 44, 24, function() appendRule("[wait(500ms)]"), false);
            bWait.x = 491; bWait.y = 348; dlg.addChild(bWait); helperButtons.push(bWait);

            var lblHint = ApiPromptModal.createLabel("Syntax: 3[auraTime(target:Seal) <= 1.5s] > 4 | 2[tgt:hp < 50%] | 1[hp < 50%]", 510, 11);
            lblHint.x = 25;
            lblHint.y = 378;
            lblHint.textColor = 0x888888;
            dlg.addChild(lblHint);

            saveBtn = ApiPromptModal.createButton("Save Mode", 100, 36, function():Void {
                try {
                    if (lblBadge != null && lblBadge.text == "[Bundled Mode]") {
                        ApiNotificationManager.notify("Cannot overwrite default bundled mode!");
                        return;
                    }

                    var cName = (inputClass != null && inputClass.text != null) ? StringTools.trim(inputClass.text) : "";
                    var mName = (inputMode != null && inputMode.text != null) ? StringTools.trim(inputMode.text) : "";
                    var execMode = (ddExecMode != null && ddExecMode.selectedItem != null && ddExecMode.selectedItem != "") ? ddExecMode.selectedItem : "WaitForCooldown";
                    var timeoutStr = (inputTimeout != null && inputTimeout.text != null) ? StringTools.trim(inputTimeout.text) : "0";
                    var pTimeout:Null<Int> = Std.parseInt(timeoutStr);
                    var rawTimeout = (pTimeout != null) ? pTimeout : 0;
                    var timeout = (rawTimeout > 1500) ? rawTimeout : 0;
                    var stopAuras = (inputStopAuras != null && inputStopAuras.text != null) ? StringTools.trim(inputStopAuras.text) : "";
                    var combo = (inputCombo != null && inputCombo.text != null) ? StringTools.trim(inputCombo.text) : "";

                    if (cName == "" || cName.toLowerCase() == "current") {
                        var cur = CombatEngine.getCurrentClassName();
                        if (cur != null && cur != "" && cur.toLowerCase() != "current") {
                            cName = cur;
                            if (inputClass != null) inputClass.text = cur;
                        } else {
                            ApiNotificationManager.notify("Error: Please provide a specific class name (cannot save under 'Current')!");
                            return;
                        }
                    }
                    if (mName == "" || mName == "[+ New Mode]") {
                        ApiNotificationManager.notify("Error: Please provide a valid mode name!");
                        return;
                    }
                    if (combo == "") {
                        ApiNotificationManager.notify("Error: Skill combo rotation cannot be empty!");
                        return;
                    }

                    var ok = SkillManager.saveMode(cName, mName, execMode, timeout, combo, stopAuras);
                    if (ok) {
                        // Automatically activate for Smart Combat
                        try {
                            HelperSetting.setString("api_smart_class", cName);
                            HelperSetting.setString("api_smart_mode", mName);
                        } catch (se:Dynamic) {}
                        CombatEngine.smartClass = cName;
                        CombatEngine.skillMode = mName;
                        try {
                            if (Api.combat != null) {
                                Api.combat.mode = mName;
                            }
                        } catch (_:Dynamic) {}

                        ApiNotificationManager.notify("Saved & Activated [" + cName + " : " + mName + "]!");

                        try {
                            var freshClassOpts = getAvailableClasses();
                            if (ddClass != null) {
                                ddClass.setOptions(freshClassOpts);
                                ddClass.setSelectedItem(cName);
                            }

                            var freshModes = getModeListForClass(cName);
                            if (ddMode != null) {
                                ddMode.setOptions(freshModes);
                                ddMode.setSelectedItem(mName);
                            }
                            loadModeDetails(cName, mName);
                        } catch (ue:Dynamic) {}
                    } else {
                        ApiNotificationManager.notify("Error: Failed to write to userSkills.json!");
                    }
                } catch (e:Dynamic) {
                    var errDetail:String = Std.string(e);
                    #if flash
                    try {
                        if (Std.isOfType(e, flash.errors.Error)) {
                            var fe:flash.errors.Error = cast e;
                            if (fe.message != null && fe.message != "") errDetail += " (" + fe.message + ")";
                            var st:String = fe.getStackTrace();
                            if (st != null && st != "") {
                                var lines = st.split("\n");
                                if (lines.length > 1) errDetail += " at " + StringTools.trim(lines[1]);
                            }
                        }
                    } catch (_:Dynamic) {}
                    #end
                    ApiLogger.error("Prompt", "Save error: " + errDetail);
                    ApiNotificationManager.notify("Save error: " + errDetail);
                }
            }, true);
            saveBtn.x = 20;
            saveBtn.y = 412;
            dlg.addChild(saveBtn);

            applyBtn = ApiPromptModal.createButton("Apply Mode", 100, 36, function():Void {
                try {
                    var cName = (inputClass != null && inputClass.text != null) ? StringTools.trim(inputClass.text) : "";
                    var mName = (inputMode != null && inputMode.text != null) ? StringTools.trim(inputMode.text) : "";
                    if (cName == "" || mName == "" || mName == "[+ New Mode]") {
                        ApiNotificationManager.notify("Error: Select a valid class and mode to apply!");
                        return;
                    }
                    if (cName.toLowerCase() == "current") {
                        var cur = CombatEngine.getCurrentClassName();
                        if (cur != null && cur != "" && cur.toLowerCase() != "current") {
                            cName = cur;
                        }
                    }
                    try {
                        HelperSetting.setString("api_smart_class", cName);
                        HelperSetting.setString("api_smart_mode", mName);
                    } catch (se:Dynamic) {}
                    CombatEngine.smartClass = cName;
                    CombatEngine.skillMode = mName;
                    try {
                        if (Api.combat != null) {
                            Api.combat.mode = mName;
                        }
                    } catch (_:Dynamic) {}
                    ApiNotificationManager.notify("Activated [" + cName + " : " + mName + "] for Smart Combat!");
                } catch (e:Dynamic) {
                    var errDetail:String = Std.string(e);
                    #if flash
                    try {
                        if (Std.isOfType(e, flash.errors.Error)) {
                            var fe:flash.errors.Error = cast e;
                            if (fe.message != null && fe.message != "") errDetail += " (" + fe.message + ")";
                            var st:String = fe.getStackTrace();
                            if (st != null && st != "") {
                                var lines = st.split("\n");
                                if (lines.length > 1) errDetail += " at " + StringTools.trim(lines[1]);
                            }
                        }
                    } catch (_:Dynamic) {}
                    #end
                    ApiLogger.error("Prompt", "Apply error: " + errDetail);
                    ApiNotificationManager.notify("Apply error: " + errDetail);
                }
            }, true);
            applyBtn.x = 125;
            applyBtn.y = 412;
            dlg.addChild(applyBtn);

            delBtn = ApiPromptModal.createButton("Delete Mode", 95, 36, function():Void {
                try {
                    var cName = (inputClass != null && inputClass.text != null) ? StringTools.trim(inputClass.text) : "";
                    var mName = (inputMode != null && inputMode.text != null) ? StringTools.trim(inputMode.text) : "";

                    if (cName == "" && ddClass != null && ddClass.selectedItem != null) {
                        cName = StringTools.trim(ddClass.selectedItem);
                    }

                    if (cName == "" || cName.toLowerCase() == "current") {
                        var cur = CombatEngine.getCurrentClassName();
                        if (cur != null && cur != "" && cur.toLowerCase() != "current") {
                            cName = cur;
                        } else if (CombatEngine.smartClass != null && CombatEngine.smartClass != "" && CombatEngine.smartClass.toLowerCase() != "current") {
                            cName = CombatEngine.smartClass;
                        }
                    }

                    if ((mName == "" || mName == "[+ New Mode]") && ddMode != null && ddMode.selectedItem != null && ddMode.selectedItem != "[+ New Mode]") {
                        mName = StringTools.trim(ddMode.selectedItem);
                    }

                    if (cName == "" || mName == "" || mName == "[+ New Mode]") {
                        ApiNotificationManager.notify("Error: Select a valid mode to delete!");
                        return;
                    }

                    if (!SkillManager.isUserMode(cName, mName)) {
                        ApiNotificationManager.notify("Cannot delete default bundled mode from skills.json!");
                        return;
                    }

                    var deleted = SkillManager.deleteMode(cName, mName);
                    if (deleted) {
                        ApiNotificationManager.notify("Deleted [" + cName + " : " + mName + "] from userSkills.json!");
                        try {
                            // If active smart mode was the one deleted, fall back
                            if (CombatEngine.skillMode != null && CombatEngine.skillMode.toLowerCase() == mName.toLowerCase()) {
                                var remainingModes = CombatEngine.getAvailableModes(cName);
                                var fallbackMode = (remainingModes.length > 0 && remainingModes[0] != "[+ New Mode]") ? remainingModes[0] : "Base";
                                CombatEngine.skillMode = fallbackMode;
                                try { HelperSetting.setString("api_smart_mode", fallbackMode); } catch (_:Dynamic) {}
                                try { if (Api.combat != null) Api.combat.mode = fallbackMode; } catch (_:Dynamic) {}
                            }

                            var freshClassOpts = getAvailableClasses();
                            var classToSelect = (freshClassOpts.indexOf(cName) != -1) ? cName : (freshClassOpts.length > 0 ? freshClassOpts[0] : "");
                            if (ddClass != null) {
                                ddClass.setOptions(freshClassOpts);
                                ddClass.setSelectedItem(classToSelect);
                            }
                            var modes = getModeListForClass(classToSelect);
                            if (ddMode != null) {
                                ddMode.setOptions(modes);
                                var nextMode = (modes.length > 0 && modes[0] != "[+ New Mode]") ? modes[0] : (modes.length > 1 ? modes[0] : "[+ New Mode]");
                                ddMode.setSelectedItem(nextMode);
                                loadModeDetails(classToSelect, nextMode);
                            }
                        } catch (de:Dynamic) {}
                    } else {
                        ApiNotificationManager.notify("Mode was not found in userSkills.json!");
                    }
                } catch (e:Dynamic) {
                    var errDetail:String = Std.string(e);
                    #if flash
                    try {
                        if (Std.isOfType(e, flash.errors.Error)) {
                            var fe:flash.errors.Error = cast e;
                            if (fe.message != null && fe.message != "") errDetail += " (" + fe.message + ")";
                            var st:String = fe.getStackTrace();
                            if (st != null && st != "") {
                                var lines = st.split("\n");
                                if (lines.length > 1) errDetail += " at " + StringTools.trim(lines[1]);
                            }
                        }
                    } catch (_:Dynamic) {}
                    #end
                    ApiLogger.error("Prompt", "Delete error: " + errDetail);
                    ApiNotificationManager.notify("Delete error: " + errDetail);
                }
            }, false);
            delBtn.x = 230;
            delBtn.y = 412;
            dlg.addChild(delBtn);

            var backBtn = ApiPromptModal.createButton("AutoCombat Setup", 125, 36, function():Void {
                ApiPromptModal.close();
                showSmartCombatPrompt(overlay);
            }, false);
            backBtn.x = 330;
            backBtn.y = 412;
            dlg.addChild(backBtn);

            var closeBtn = ApiPromptModal.createButton("Close", 75, 36, function():Void {
                ApiPromptModal.close();
            }, false);
            closeBtn.x = 460;
            closeBtn.y = 412;
            dlg.addChild(closeBtn);

            // Initial load of selected mode details now that all UI elements and buttons exist
            loadModeDetails(selectedClass, initialSelMode);

            ApiPromptModal.show(overlay, dlg);
        } catch (e:Dynamic) {
            var msg = Std.string(e);
            #if flash
            if (Std.isOfType(e, flash.errors.Error)) {
                msg += "\n" + (cast e : flash.errors.Error).getStackTrace();
            }
            #end
            ApiLogger.error("Prompt", "Failed to show Combat Mode Editor: " + msg);
            ApiNotificationManager.notify("Error opening editor: " + e);
        }
    }

    public static function showLoadoutsPrompt(overlay:Dynamic):Void {
        try {
            var dlg = ApiPromptModal.createDialog(420, 390, "Class Loadouts (For Scripts)");

            var availableClasses = getAvailableClasses();
            if (availableClasses == null || availableClasses.length == 0) availableClasses = ["Current"];

            setupLoadoutRow(dlg, "FARM Loadout:", 45, 70, availableClasses, "api_farm_class", "api_farm_mode", function(c:String, m:String):Void {
                CombatEngine.farmClass = c;
                CombatEngine.farmMode = m;
            });

            setupLoadoutRow(dlg, "SOLO Loadout:", 110, 135, availableClasses, "api_solo_class", "api_solo_mode", function(c:String, m:String):Void {
                CombatEngine.soloClass = c;
                CombatEngine.soloMode = m;
            });

            setupLoadoutRow(dlg, "BOSS Loadout:", 175, 200, availableClasses, "api_boss_class", "api_boss_mode", function(c:String, m:String):Void {
                CombatEngine.bossClass = c;
                CombatEngine.bossMode = m;
            });

            setupLoadoutRow(dlg, "DODGE Loadout:", 240, 265, availableClasses, "api_dodge_class", "api_dodge_mode", function(c:String, m:String):Void {
                CombatEngine.dodgeClass = c;
                CombatEngine.dodgeMode = m;
            });

            var doneBtn = ApiPromptModal.createButton("Done", 140, 35, function():Void {
                ApiPromptModal.close();
                ApiNotificationManager.notify("Class Loadouts Saved!");
            }, true);
            doneBtn.x = 140;
            doneBtn.y = 330;
            dlg.addChild(doneBtn);

            ApiPromptModal.show(overlay, dlg);
        } catch (e:Dynamic) {
            var stackTrace:String = "";
            #if flash
            if (Std.isOfType(e, flash.errors.Error)) {
                stackTrace = "\n" + (cast e : flash.errors.Error).getStackTrace();
            }
            #end
            ApiLogger.error("Prompt", "Failed to show Class Loadouts prompt: " + e + stackTrace);
            ApiNotificationManager.notify("Error opening loadouts: " + e);
        }
    }

    private static function setupLoadoutRow(
        dlg:Sprite,
        title:String,
        lblY:Float,
        ddY:Float,
        classes:Array<String>,
        classKey:String,
        modeKey:String,
        onUpdate:String->String->Void
    ):Void {
        var lbl = ApiPromptModal.createLabel(title, 150, 14, true);
        lbl.x = 20;
        lbl.y = lblY;
        dlg.addChild(lbl);

        var getModesForClass = function(cName:String):Array<String> {
            var modes:Array<String> = [];
            var isCurrent = (cName == null || cName == "" || cName.toLowerCase() == "current");
            if (isCurrent) {
                modes.push("Auto (First Available)");
                var curName = CombatEngine.getCurrentClassName();
                if (curName != "") {
                    try {
                        var detectedModes = CombatEngine.getAvailableModes(curName);
                        if (detectedModes != null) {
                            for (m in detectedModes) if (modes.indexOf(m) == -1) modes.push(m);
                        }
                    } catch (_:Dynamic) {}
                }
            } else {
                try {
                    modes = CombatEngine.getAvailableModes(cName);
                } catch (_:Dynamic) {}
            }
            if (modes == null || modes.length == 0) modes = ["Base"];
            return modes;
        };

        var curClass = HelperSetting.getString(classKey, "Current");
        if (classes.indexOf(curClass) == -1) curClass = classes[0];

        var modes:Array<String> = getModesForClass(curClass);
        var curMode = HelperSetting.getString(modeKey, "Auto");
        if (curClass == "Current" && (curMode == "" || curMode == "Auto")) {
            curMode = "Auto (First Available)";
        } else if (curMode == null || curMode == "" || modes.indexOf(curMode) == -1) {
            curMode = modes.length > 0 ? modes[0] : "Base";
        }

        var ddMode:Dropdown = null;
        ddMode = new Dropdown(120, 25, modes, function(sel:String):Void {
            curMode = sel;
            var saveMode = (sel == "Auto (First Available)") ? "Auto" : sel;
            HelperSetting.setString(modeKey, saveMode);
            if (onUpdate != null) onUpdate(curClass, saveMode);
        });
        ddMode.x = 280;
        ddMode.y = ddY;

        var ddClass:Dropdown = null;
        ddClass = new Dropdown(240, 25, classes, function(sel:String):Void {
            curClass = sel;
            HelperSetting.setString(classKey, sel);
            var nm:Array<String> = getModesForClass(curClass);
            ddMode.setOptions(nm);
            if (curClass == "Current") {
                curMode = "Auto (First Available)";
            } else if (nm.indexOf(curMode) == -1) {
                curMode = nm.length > 0 ? nm[0] : "Base";
            }
            ddMode.setSelectedItem(curMode);
            var saveMode = (curMode == "Auto (First Available)") ? "Auto" : curMode;
            HelperSetting.setString(modeKey, saveMode);
            if (onUpdate != null) onUpdate(curClass, saveMode);
        });
        ddClass.x = 20;
        ddClass.y = ddY;

        ddClass.setSelectedItem(curClass);
        ddMode.setSelectedItem(curMode);
        dlg.addChild(ddMode);
        dlg.addChild(ddClass);
    }

    private static function getAvailableClasses():Array<String> {
        var classMap:Map<String, String> = new Map<String, String>();
        var invClasses:Array<String> = [];

        var addClass = function(name:Dynamic):Void {
            if (name == null) return;
            var str:String = Std.string(name);
            var trimmed:String = StringTools.trim(str);
            if (trimmed == "" || trimmed == "null" || trimmed == "No Classes Found" || trimmed.toLowerCase() == "current") return;
            var key:String = trimmed.toLowerCase();
            if (!classMap.exists(key)) {
                classMap.set(key, trimmed);
                invClasses.push(trimmed);
            }
        };

        // Inventory classes
        if (Api.game != null && Api.game.world != null && Api.game.world.myAvatar != null && Api.game.world.myAvatar.items != null) {
            try {
                var items:Dynamic = Api.game.world.myAvatar.items;
                if (Std.isOfType(items, Array)) {
                    for (item in (cast items : Array<Dynamic>)) {
                        if (item == null || item.sName == null) continue;
                        var isClass:Bool = false;
                        var sTypeStr:String = (item.sType != null) ? Std.string(item.sType).toLowerCase() : "";
                        if (sTypeStr == "class" || item.bClass == 1 || item.bClass == true || item.bClass == "1") {
                            isClass = true;
                        } else if (item.sES != null && Std.string(item.sES).toLowerCase() == "ar" && sTypeStr != "armor") {
                            if (CombatEngine.findClassConfig(item.sName) != null) isClass = true;
                        }
                        if (isClass) addClass(item.sName);
                    }
                }
            } catch (e:Dynamic) {}
        }

        // Currently equipped class
        try {
            var cur:String = getCurrentClass();
            if (cur != "" && cur.toLowerCase() != "current") {
                addClass(cur);
            }
        } catch (e:Dynamic) {}

        try {
            invClasses.sort(function(a, b) {
                var la:String = a.toLowerCase();
                var lb:String = b.toLowerCase();
                if (la < lb) return -1;
                if (la > lb) return 1;
                return 0;
            });
        } catch (e:Dynamic) {}

        var result:Array<String> = ["Current"];
        for (c in invClasses) {
            result.push(c);
        }
        return result;
    }

    private static function getCurrentClass():String {
        try {
            var cur:String = CombatEngine.getCurrentClassName();
            if (cur != "" && cur.toLowerCase() != "current") return cur;
            if (Api.game != null && Api.game.world != null && Api.game.world.myAvatar != null) {
                var av:Dynamic = Api.game.world.myAvatar;
                if (av.objData != null && av.objData.strClassName != null) {
                    var c:String = Std.string(av.objData.strClassName);
                    if (c != "" && c != "null") return c;
                }
            }
        } catch (e:Dynamic) {}
        return "";
    }

    public static function showScriptManager(overlay:Dynamic):Void {
        try {
            var dlg = ApiPromptModal.createDialog(620, 500, "Script Manager & Editor");

            var currentScriptName:String = "";
            var isUser:Bool = false;
            var isBundled:Bool = false;

            // Script Selection Dropdown
            var lblSelect = ApiPromptModal.createLabel("Select Script:", 140);
            lblSelect.x = 20;
            lblSelect.y = 36;
            dlg.addChild(lblSelect);

            // Script Name Input
            var lblName = ApiPromptModal.createLabel("Script Name (.hxs):", 140);
            lblName.x = 300;
            lblName.y = 36;
            dlg.addChild(lblName);

            var inputName = ApiPromptModal.createInput(300, 26, "");
            inputName.x = 300;
            inputName.y = 56;
            dlg.addChild(inputName);

            // Live Status Label
            var lblStatus = ApiPromptModal.createLabel("Status: STOPPED", 580, 13, true);
            lblStatus.x = 20;
            lblStatus.y = 90;
            lblStatus.textColor = 0x888888;
            dlg.addChild(lblStatus);

            // Code Editor
            var lblCode = ApiPromptModal.createLabel("Script Code (HScript / .hxs):", 300);
            lblCode.x = 20;
            lblCode.y = 114;
            dlg.addChild(lblCode);

            var inputCode = ApiPromptModal.createInput(580, 290, "", true);
            inputCode.x = 20;
            inputCode.y = 136;
            dlg.addChild(inputCode);

            // Buttons
            var runBtn:Sprite = null;
            var runBtnTxt:TextField = null;
            var saveBtn:Sprite = null;
            var deleteBtn:Sprite = null;

            var formatScriptOption = function(rawName:String):String {
                if (rawName == "[+ New Script]") return rawName;
                if (ScriptManager.SINGLETON.isBundledScript(rawName)) {
                    return "[Bundled] " + rawName;
                } else {
                    return "[User] " + rawName;
                }
            };

            var getRawScriptName = function(optLabel:String):String {
                if (optLabel == null) return "";
                if (optLabel == "[+ New Script]") return "";
                if (StringTools.startsWith(optLabel, "[User] ")) return optLabel.substring(7);
                if (StringTools.startsWith(optLabel, "[Bundled] ")) return optLabel.substring(10);
                return optLabel;
            };

            var buildOptionsList = function():Array<String> {
                var rawScripts = ScriptManager.SINGLETON.listScripts();
                var opts:Array<String> = [];
                for (s in rawScripts) {
                    opts.push(formatScriptOption(s));
                }
                opts.push("[+ New Script]");
                return opts;
            };

            var updateStatusDisplay = function():Void {
                var running = ScriptManager.SINGLETON.isRunning;
                if (running) {
                    var actName = ScriptManager.SINGLETON.activeScriptName;
                    lblStatus.text = "● RUNNING: " + (actName != null ? actName : "Custom Script");
                    lblStatus.textColor = 0x55FF55;
                    if (runBtnTxt != null) runBtnTxt.text = "Stop Script";
                } else {
                    lblStatus.text = "○ STOPPED";
                    lblStatus.textColor = 0x888888;
                    if (runBtnTxt != null) runBtnTxt.text = "Start Script";
                }
            };

            var ddScript:Dropdown = null;

            var setDeleteEnabled = function(enabled:Bool):Void {
                if (deleteBtn != null) {
                    deleteBtn.mouseEnabled = enabled;
                    deleteBtn.alpha = enabled ? 1.0 : 0.35;
                }
            };

            var loadSelectedScript = function(optLabel:String):Void {
                if (optLabel == "[+ New Script]") {
                    currentScriptName = "MyScript";
                    isUser = true;
                    isBundled = false;
                    lblName.text = "New Script Name (.hxs):";
                    inputName.type = TextFieldType.INPUT;
                    inputName.text = "MyScript";
                    inputName.selectable = true;
                    inputCode.text = "// New HScript\nfunction onStart() {\n    bot.log(\"Started script!\");\n}\n\nfunction onTick() {\n    // Bot logic here\n}\n\nfunction onStop() {\n    bot.log(\"Stopped script!\");\n}\n";
                    setDeleteEnabled(false);
                } else {
                    var raw = getRawScriptName(optLabel);
                    currentScriptName = raw;
                    isBundled = ScriptManager.SINGLETON.isBundledScript(raw);
                    isUser = !isBundled;
                    if (isBundled) {
                        lblName.text = "Save As User Script (.hxs):";
                        inputName.text = raw + "_Edited";
                        setDeleteEnabled(false);
                    } else {
                        lblName.text = "Script Name (.hxs):";
                        inputName.text = raw;
                        setDeleteEnabled(true);
                    }
                    inputName.type = TextFieldType.INPUT;
                    inputName.selectable = true;
                    inputCode.text = ScriptManager.SINGLETON.getScriptContent(raw);
                }
                updateStatusDisplay();
            };

            var scriptOptions = buildOptionsList();
            ddScript = new Dropdown(260, 26, scriptOptions, function(sel:String):Void {
                loadSelectedScript(sel);
            });
            ddScript.x = 20;
            ddScript.y = 56;
            dlg.addChild(ddScript);

            var initialLabel = scriptOptions.length > 0 ? scriptOptions[0] : "[+ New Script]";
            if (ScriptManager.SINGLETON.activeScriptName != null) {
                var candidate = formatScriptOption(ScriptManager.SINGLETON.activeScriptName);
                if (scriptOptions.indexOf(candidate) != -1) {
                    initialLabel = candidate;
                }
            }
            ddScript.setSelectedItem(initialLabel);
            loadSelectedScript(initialLabel);

            // Bottom action buttons (y = 445)
            runBtn = ApiPromptModal.createButton(ScriptManager.SINGLETON.isRunning ? "Stop Script" : "Start Script", 130, 32, function():Void {
                if (ScriptManager.SINGLETON.isRunning) {
                    ScriptManager.SINGLETON.stop();
                    ApiNotificationManager.notify("Script stopped.");
                } else {
                    var code = inputCode.text;
                    if (code == null || StringTools.trim(code) == "") {
                        ApiNotificationManager.notify("Cannot run empty script!");
                        return;
                    }
                    var sName = StringTools.trim(inputName.text);
                    if (isBundled && sName == currentScriptName + "_Edited") {
                        sName = currentScriptName;
                    } else if (sName == "") {
                        sName = currentScriptName != "" ? currentScriptName : "CustomScript";
                    }
                    ScriptManager.SINGLETON.loadScript(code);
                    ScriptManager.SINGLETON.start();
                    ScriptManager.SINGLETON.activeScriptName = sName;
                    ApiNotificationManager.notify("Started script: " + sName);
                }
                updateStatusDisplay();
            }, false);
            runBtn.x = 20;
            runBtn.y = 445;
            for (i in 0...runBtn.numChildren) {
                if (Std.isOfType(runBtn.getChildAt(i), TextField)) {
                    runBtnTxt = cast runBtn.getChildAt(i);
                    break;
                }
            }
            dlg.addChild(runBtn);

            saveBtn = ApiPromptModal.createButton("Save Script", 120, 32, function():Void {
                var sName = StringTools.trim(inputName.text);
                if (StringTools.endsWith(sName.toLowerCase(), ".hxs")) {
                    sName = sName.substring(0, sName.length - 4);
                }
                if (sName == "") {
                    ApiNotificationManager.notify("Please enter a valid script name.");
                    return;
                }
                if (ScriptManager.SINGLETON.isBundledScript(sName)) {
                    sName = sName + "_Edited";
                }
                var code = inputCode.text;
                var saved = ScriptManager.SINGLETON.saveScript(sName, code);
                if (saved) {
                    ApiNotificationManager.notify("Saved script: " + sName);
                    var refreshed = buildOptionsList();
                    ddScript.setOptions(refreshed);
                    var newSel = formatScriptOption(sName);
                    ddScript.setSelectedItem(newSel);
                    loadSelectedScript(newSel);
                } else {
                    ApiNotificationManager.notify("Failed to save script.");
                }
            }, false);
            saveBtn.x = 165;
            saveBtn.y = 445;
            dlg.addChild(saveBtn);

            deleteBtn = ApiPromptModal.createButton("Delete Script", 120, 32, function():Void {
                if (isBundled || ScriptManager.SINGLETON.isBundledScript(currentScriptName)) {
                    ApiNotificationManager.notify("Cannot delete bundled scripts!");
                    return;
                }
                var toDelete = currentScriptName;
                if (toDelete == "" || toDelete == "MyScript") return;
                var deleted = ScriptManager.SINGLETON.deleteScript(toDelete);
                if (deleted) {
                    ApiNotificationManager.notify("Deleted script: " + toDelete);
                    var refreshed = buildOptionsList();
                    ddScript.setOptions(refreshed);
                    var nextSel = refreshed.length > 0 ? refreshed[0] : "[+ New Script]";
                    ddScript.setSelectedItem(nextSel);
                    loadSelectedScript(nextSel);
                } else {
                    ApiNotificationManager.notify("Failed to delete script.");
                }
            }, false);
            deleteBtn.x = 300;
            deleteBtn.y = 445;
            dlg.addChild(deleteBtn);
            setDeleteEnabled(!isBundled && currentScriptName != "MyScript" && currentScriptName != "");

            var closeBtn = ApiPromptModal.createButton("Close", 100, 32, function():Void {
                ApiPromptModal.close();
            }, false);
            closeBtn.x = 500;
            closeBtn.y = 445;
            dlg.addChild(closeBtn);

            // Real-time synchronization
            var onFrame:Event->Void = null;
            onFrame = function(e:Event):Void {
                if (dlg.parent == null) {
                    dlg.removeEventListener(Event.ENTER_FRAME, onFrame);
                    return;
                }
                updateStatusDisplay();
            };
            dlg.addEventListener(Event.ENTER_FRAME, onFrame);

            ApiPromptModal.show(overlay, dlg);
        } catch (e:Dynamic) {
            ApiNotificationManager.notify("Script Manager error: " + e);
        }
    }
}
#else
class ApiPrompts {
    public static function showCombatModeEditorPrompt(overlay:Dynamic, initialClass:String = null, initialMode:String = null):Void {}
    public static function showScriptManager(overlay:Dynamic):Void {}
}
#end

