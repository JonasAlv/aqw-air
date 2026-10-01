package ui;

import flash.Vector;
import ui.option.Menu;
import ui.api.ApiMenus as ApiMenusImpl;

class ApiMenus {
    public static var anthonyMenus(get, set):Dynamic;
    static inline function get_anthonyMenus():Dynamic return ApiMenusImpl.anthonyMenus;
    static inline function set_anthonyMenus(v:Dynamic):Dynamic return ApiMenusImpl.anthonyMenus = v;

    public static var apiMenus(get, set):Vector<Menu>;
    static inline function get_apiMenus():Vector<Menu> return ApiMenusImpl.apiMenus;
    static inline function set_apiMenus(v:Vector<Menu>):Vector<Menu> return ApiMenusImpl.apiMenus = v;

    public static var lastSelectedMenu(get, set):Menu;
    static inline function get_lastSelectedMenu():Menu return ApiMenusImpl.lastSelectedMenu;
    static inline function set_lastSelectedMenu(v:Menu):Menu return ApiMenusImpl.lastSelectedMenu = v;

    public static inline function inject(overlay:Dynamic):Void {
        ApiMenusImpl.inject(overlay);
    }

    public static inline function resetMenuButtonPosition():Void {
        ApiMenusImpl.resetMenuButtonPosition();
    }
}
