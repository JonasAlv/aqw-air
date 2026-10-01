class Config {
    public static inline var GAME_BASE_URL:String = "https://game.aq.com/game/";
    public static var API_VERSION_URL:String = GAME_BASE_URL + "api/data/gameversion";
    public static var API_LOGIN_URL:String = GAME_BASE_URL + "api/login/now";
    public static inline var APP_VERSION:String = "1.0.0";

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
