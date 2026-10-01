class Config {
    public static inline var GAME_BASE_URL:String = "https://game.aq.com/game/";
    public static var API_VERSION_URL:String = GAME_BASE_URL + "api/data/gameversion";
    public static var API_LOGIN_URL:String = GAME_BASE_URL + "api/login/now";
    public static var APP_VERSION:String = getVersion();
    public static inline var GITHUB_RELEASES_URL:String = "https://api.github.com/repos/anthony-hyo/aqw-mobile/releases/latest";

    private static function getVersion():String {
        try {
            #if flash
            var nativeAppCls:Dynamic = untyped __global__["flash.desktop.NativeApplication"];
            if (nativeAppCls != null) {
                var appDesc:Dynamic = nativeAppCls.nativeApplication.applicationDescriptor;
                if (appDesc != null) {
                    var str:String = Std.string(appDesc);
                    var r = ~/<versionNumber>([^<]+)<\/versionNumber>/;
                    if (r.match(str)) {
                        return "v" + r.matched(1);
                    }
                }
            }
            #end
        } catch (e:Dynamic) {}
        return "v1.0.0";
    }

    public var option_pagination:Bool = true;
    public var option_equipped_on_top:Bool = true;

    public var option_animation_monster_off:Bool = false;
    public var option_animation_helm_off:Bool = false;
    public var option_animation_armor_off:Bool = false;
    public var option_animation_cape_off:Bool = false;
    public var option_animation_hair_off:Bool = false;
    public var option_animation_misc_off:Bool = false;
    public var option_animation_pet_off:Bool = false;
    public var option_animation_weapon_off:Bool = false;

    public var option_filter_off:Bool = false;

    public var option_language:String = "en";
    public var option_skill_tooltips:Bool = true;
    public var option_disable_cutscenes:Bool = false;
    public var option_slow_walk:Bool = false;

    public var option_player_animation_skill:Bool = true;
    public var option_player_animation_aura:Bool = true;

    public var option_monster_animation_skill:Bool = true;
    public var option_monster_animation_aura:Bool = true;

    public var option_self_animation_skill:Bool = true;
    public var option_self_animation_aura:Bool = true;

    public function new() {}
}
