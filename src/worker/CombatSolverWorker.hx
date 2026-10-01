package worker;

class CombatSolverWorker {
    /**
     * Solves the optimal skill decision off-thread based on combat state snapshot.
     */
    public static function solve(state:Dynamic):Dynamic {
        if (state == null) {
            return { castSkillIndex: -1, action: "idle", reasoning: "No state" };
        }

        var playerHp:Float = (state.playerHp != null) ? state.playerHp : 100.0;
        var playerMaxHp:Float = (state.playerMaxHp != null && state.playerMaxHp > 0) ? state.playerMaxHp : 100.0;
        var playerHpPct:Float = (playerHp / playerMaxHp) * 100.0;

        var playerMp:Float = (state.playerMp != null) ? state.playerMp : 100.0;
        var targetAlive:Bool = (state.targetAlive != null) ? (state.targetAlive == true) : true;
        var targetHp:Float = (state.targetHp != null) ? state.targetHp : 100.0;

        if (!targetAlive || targetHp <= 0) {
            return { castSkillIndex: -1, action: "wait_target", reasoning: "Target dead or not found" };
        }

        var skills:Array<Dynamic> = (state.skills != null) ? cast state.skills : [];
        if (skills.length == 0) {
            return { castSkillIndex: -1, action: "idle", reasoning: "No skills configured" };
        }

        var currentTime:Float = (state.currentTime != null) ? state.currentTime : 0.0;

        // 1. Emergency Survival Check (Heal / Shield Priority)
        var emergencyThreshold:Float = (state.healThreshold != null) ? state.healThreshold : 50.0;
        if (playerHpPct <= emergencyThreshold) {
            for (s in skills) {
                if (s == null) continue;
                var isHeal:Bool = (s.isHeal == true);
                if (isHeal && isSkillReady(s, playerMp, currentTime)) {
                    return {
                        castSkillIndex: s.index,
                        action: "heal",
                        confidence: 1.0,
                        reasoning: "Emergency heal below " + emergencyThreshold + "% HP"
                    };
                }
            }
        }

        // 2. Taunt / Aura Management Check
        var targetAuras:Array<Dynamic> = (state.targetAuras != null) ? cast state.targetAuras : [];
        var playerAuras:Array<Dynamic> = (state.playerAuras != null) ? cast state.playerAuras : [];

        for (s in skills) {
            if (s == null) continue;
            if (s.requiresAura != null && !hasAura(playerAuras, Std.string(s.requiresAura))) {
                continue; // Missing required self-buff aura
            }
            if (s.refreshBuff != null) {
                var rem:Float = getAuraRemaining(playerAuras, Std.string(s.refreshBuff));
                if (rem < 2.0 && isSkillReady(s, playerMp, currentTime)) {
                    return {
                        castSkillIndex: s.index,
                        action: "buff_refresh",
                        confidence: 0.9,
                        reasoning: "Refreshing buff aura " + s.refreshBuff
                    };
                }
            }
        }

        // 3. Priority-based Rotation Selection
        var bestSkill:Dynamic = null;
        var highestPriority:Int = -9999;

        for (s in skills) {
            if (s == null) continue;
            if (!isSkillReady(s, playerMp, currentTime)) continue;

            // Check custom condition thresholds
            if (s.minHp != null && playerHpPct < s.minHp) continue;
            if (s.maxHp != null && playerHpPct > s.maxHp) continue;
            if (s.minMp != null && playerMp < s.minMp) continue;

            var prio:Int = (s.priority != null) ? Std.int(s.priority) : 10;
            if (prio > highestPriority) {
                highestPriority = prio;
                bestSkill = s;
            }
        }

        if (bestSkill != null) {
            return {
                castSkillIndex: bestSkill.index,
                action: "cast",
                confidence: 0.8,
                reasoning: "Highest priority ready skill (Index " + bestSkill.index + ")"
            };
        }

        return { castSkillIndex: -1, action: "cooldown", reasoning: "All skills on cooldown or insufficient mana" };
    }

    private static inline function isSkillReady(skill:Dynamic, playerMp:Float, currentTime:Float):Bool {
        var manaCost:Int = (skill.mana != null) ? Std.int(skill.mana) : 0;
        if (playerMp < manaCost) return false;

        var cdMs:Float = (skill.cd != null) ? skill.cd : 2000.0;
        var lastCast:Float = (skill.lastCast != null) ? skill.lastCast : 0.0;
        if (currentTime > 0 && (currentTime - lastCast < cdMs)) {
            return false;
        }

        return true;
    }

    private static function hasAura(auras:Array<Dynamic>, auraName:String):Bool {
        if (auras == null || auraName == null) return false;
        var target:String = auraName.toLowerCase();
        for (a in auras) {
            if (a != null && a.name != null && Std.string(a.name).toLowerCase() == target) return true;
        }
        return false;
    }

    private static function getAuraRemaining(auras:Array<Dynamic>, auraName:String):Float {
        if (auras == null || auraName == null) return 0.0;
        var target:String = auraName.toLowerCase();
        for (a in auras) {
            if (a != null && a.name != null && Std.string(a.name).toLowerCase() == target) {
                return (a.remaining != null) ? a.remaining : 0.0;
            }
        }
        return 0.0;
    }
}
