package util;

import flash.net.SharedObject;

class HelperSetting {
    private static inline var SAVE_KEY:String = "aqw_pocket_settings";

    public static inline var OPTION_SHOW_JOYSTICK_MOUSE:String = "option_show_joystick";
    public static inline var OPTION_SHOW_JOYSTICK_KEYBOARD:String = "option_show_joystick_keyboard";
    public static inline var OPTION_JOYSTICK_DASH:String = "option_joystick_dash";
    public static inline var OPTION_SHOW_SKILL_BAR:String = "option_show_skill_bar";
    public static inline var OPTION_SNAP_TO_GRID:String = "option_snap_to_grid";
    public static inline var OPTION_FPS:String = "option_fps";
    public static inline var OPTION_LANGUAGE:String = "option_language";
    public static inline var OPTION_LOCK_ORIENTATION:String = "option_lock_orientation";

    public static inline var OPTION_PAGINATION:String = "option_pagination";
    public static inline var OPTION_EQUIPPED_ON_TOP:String = "option_equipped_on_top";
    public static inline var OPTION_FAVORITE_ITEMS:String = "option_favorite_items";

    public static inline var OPTION_SKILL_TOOLTIPS:String = "option_skill_tooltips";
    public static inline var OPTION_DISABLE_CUTSCENES:String = "option_disable_cutscenes";
    public static inline var OPTION_SLOW_WALK:String = "option_slow_walk";

    public static inline var OPTION_PLAYER_ANIMATION_SKILL:String = "option_player_animation_skill";
    public static inline var OPTION_PLAYER_ANIMATION_AURA:String = "option_player_animation_aura";

    public static inline var OPTION_MONSTER_ANIMATION_SKILL:String = "option_monster_animation_skill";
    public static inline var OPTION_MONSTER_ANIMATION_AURA:String = "option_monster_animation_aura";

    public static inline var OPTION_SELF_ANIMATION_SKILL:String = "option_self_animation_skill";
    public static inline var OPTION_SELF_ANIMATION_AURA:String = "option_self_animation_aura";

    public static inline var OPTION_SHORTCUTS:String = "shortcut_buttons";

    public static inline var OPTION_RASTERIZER:String = "option_rasterizer";
    public static inline var OPTION_RASTERIZER_LEVELS:String = "option_rasterizer_levels";

    public static inline var OPTION_ANIMATION_MONSTER:String = "option_animation_monster";
    public static inline var OPTION_ANIMATION_HELM:String = "option_animation_helm";
    public static inline var OPTION_ANIMATION_ARMOR:String = "option_animation_armor";
    public static inline var OPTION_ANIMATION_CAPE:String = "option_animation_cape";
    public static inline var OPTION_ANIMATION_HAIR:String = "option_animation_hair";
    public static inline var OPTION_ANIMATION_PET:String = "option_animation_pet";
    public static inline var OPTION_ANIMATION_MISC:String = "option_animation_misc";
    public static inline var OPTION_ANIMATION_WEAPON:String = "option_animation_weapon";
    public static inline var OPTION_ANIMATION_MAP:String = "option_animation_map";

    public static inline var OPTION_FILTER:String = "option_filter";
    public static inline var OPTION_SWF_CACHE:String = "option_swf_cache";
    public static inline var OPTION_RENDER_RESOLUTION:String = "option_render_resolution";
    public static inline var OPTION_RESOLUTION_LETTERBOX:String = "option_resolution_letterbox";

    public static inline var LAYOUT_JOYSTICK_MOUSE:String = "layout_joystick";
    public static inline var LAYOUT_JOYSTICK_KEYBOARD:String = "layout_joystick_keyboard";
    public static inline var LAYOUT_SKILL_BAR:String = "layout_skill_bar";

    private static var _so:SharedObject;

    private static function get_so():SharedObject {
        if (_so == null) {
            try {
                _so = SharedObject.getLocal(SAVE_KEY);
            } catch (e:Dynamic) {}
        }
        return _so;
    }

    public static function _get(key:String, ?defaultValue:Dynamic):Dynamic {
        var so = get_so();
        if (so == null) return defaultValue;
        #if flash
        untyped {
            if (so.data != null && so.data.hasOwnProperty(key)) {
                return so.data[key];
            }
        }
        #end
        _set(key, defaultValue);
        return defaultValue;
    }

    public static function _set(key:String, value:Dynamic):Void {
        var so = get_so();
        if (so == null) return;
        #if flash
        untyped {
            if (so.data != null) {
                so.data[key] = value;
                try {
                    so.flush();
                } catch (e:Dynamic) {}
            }
        }
        #end
    }

    public static function _delete(key:String):Void {
        var so = get_so();
        if (so == null) return;
        #if flash
        untyped {
            if (so.data != null) {
                __delete__(so.data, key);
                try {
                    so.flush();
                } catch (e:Dynamic) {}
            }
        }
        #end
    }

    public static function getBool(key:String, defaultValue:Bool = false):Bool {
        var val = _get(key, defaultValue);
        if (val == null) return defaultValue;
        var s = Std.string(val);
        return s == "true" || s == "1";
    }

    public static function setBool(key:String, value:Bool):Void {
        _set(key, value);
    }

    public static function getInt(key:String, defaultValue:Int = 0):Int {
        var val = _get(key, defaultValue);
        if (val == null) return defaultValue;
        return Std.int(val);
    }

    public static function setInt(key:String, value:Int):Void {
        _set(key, value);
    }

    public static function getString(key:String, defaultValue:String = ""):String {
        var val = _get(key, defaultValue);
        if (val == null) return defaultValue;
        return Std.string(val);
    }

    public static function setString(key:String, value:String):Void {
        _set(key, value);
    }

    public static function getArray(key:String, ?defaultValue:Array<Dynamic>):Array<Dynamic> {
        var val = _get(key, defaultValue != null ? defaultValue : []);
        if (val == null) return defaultValue != null ? defaultValue : [];
        if (Std.isOfType(val, Array)) return cast val;
        #if flash
        if (untyped __is__(val, __global__["Array"])) {
            return [for (item in (cast val : Array<Dynamic>)) item];
        }
        #end
        return defaultValue != null ? defaultValue : [];
    }

    public static function setArray(key:String, value:Array<Dynamic>):Void {
        _set(key, value);
    }

    public static function syncToPocket(pocket:Dynamic):Void {
        if (pocket == null) return;
        var cfg:Dynamic = pocket.config;
        if (cfg != null) {
            cfg.option_pagination = getBool(OPTION_PAGINATION, true);
            cfg.option_equipped_on_top = getBool(OPTION_EQUIPPED_ON_TOP, true);
            cfg.option_skill_tooltips = getBool(OPTION_SKILL_TOOLTIPS, true);
            cfg.option_disable_cutscenes = getBool(OPTION_DISABLE_CUTSCENES, false);
            cfg.option_slow_walk = getBool(OPTION_SLOW_WALK, false);

            cfg.option_player_animation_skill = getBool(OPTION_PLAYER_ANIMATION_SKILL, true);
            cfg.option_player_animation_aura = getBool(OPTION_PLAYER_ANIMATION_AURA, true);
            cfg.option_monster_animation_skill = getBool(OPTION_MONSTER_ANIMATION_SKILL, true);
            cfg.option_monster_animation_aura = getBool(OPTION_MONSTER_ANIMATION_AURA, true);
            cfg.option_self_animation_skill = getBool(OPTION_SELF_ANIMATION_SKILL, true);
            cfg.option_self_animation_aura = getBool(OPTION_SELF_ANIMATION_AURA, true);

            cfg.option_filter_off = getBool(OPTION_FILTER, false);
            cfg.option_animation_monster_off = getBool(OPTION_ANIMATION_MONSTER, false);
            cfg.option_animation_helm_off = getBool(OPTION_ANIMATION_HELM, false);
            cfg.option_animation_armor_off = getBool(OPTION_ANIMATION_ARMOR, false);
            cfg.option_animation_cape_off = getBool(OPTION_ANIMATION_CAPE, false);
            cfg.option_animation_hair_off = getBool(OPTION_ANIMATION_HAIR, false);
            cfg.option_animation_pet_off = getBool(OPTION_ANIMATION_PET, false);
            cfg.option_animation_weapon_off = getBool(OPTION_ANIMATION_WEAPON, false);
            cfg.option_animation_misc_off = getBool(OPTION_ANIMATION_MISC, false);

            var langIdx = getInt(OPTION_LANGUAGE, 0);
            var langCodes = ["en", "pt", "tl", "es", "id", "ceb"];
            if (langIdx >= 0 && langIdx < langCodes.length) {
                cfg.option_language = langCodes[langIdx];
            }

            var fpsValues = [24, 30, 60, 75, 120];
            var fpsIdx = getInt(OPTION_FPS, 2);
            if (fpsIdx < 0 || fpsIdx >= fpsValues.length) fpsIdx = 2;
            cfg.option_fps = fpsValues[fpsIdx];
        }

        // Apply stage settings (FPS, Orientation)
        var stg:Dynamic = null;
        if (pocket.stage != null) stg = pocket.stage;
        else if (pocket.game != null && pocket.game.stage != null) stg = pocket.game.stage;
        else if (pocket.overlay != null && pocket.overlay.stage != null) stg = pocket.overlay.stage;

        if (stg != null) {
            var fpsValues = [24, 30, 60, 75, 120];
            var fpsIdx = getInt(OPTION_FPS, 2);
            if (fpsIdx < 0 || fpsIdx >= fpsValues.length) fpsIdx = 2;
            stg.frameRate = fpsValues[fpsIdx];

            var orientIdx = getInt(OPTION_LOCK_ORIENTATION, 0);
            try {
                if (orientIdx == 2) {
                    untyped stg.autoOrients = true;
                    untyped stg.setAspectRatio("any");
                } else if (orientIdx == 1) {
                    untyped stg.autoOrients = false;
                    untyped stg.setAspectRatio("portrait");
                } else {
                    untyped stg.autoOrients = false;
                    untyped stg.setAspectRatio("landscape");
                }
            } catch (_:Dynamic) {}
        }
    }
}
