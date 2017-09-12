/*
* Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/switchboard-plug-pantheon-shell)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Tom Beckmann
*/

public class GalaPlug : Switchboard.Plug {
    Gtk.Stack stack;
    Gtk.Grid main_grid;

    private Wallpaper wallpaper_view;

    public GalaPlug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("desktop", null);
        settings.set ("desktop/wallpaper", "wallpaper");
        settings.set ("desktop/dock", "dock");
        settings.set ("desktop/hot-corners", "hotc");
        Object (category: Category.PERSONAL,
                code_name: "pantheon-desktop",
                display_name: _("Desktop"),
                description: _("Configure the dock, hot corners, and change wallpaper"),
                icon: "preferences-desktop-wallpaper",
                supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();

            wallpaper_view = new Wallpaper (this);
            var dock = new Dock ();
            var hotcorners = new HotCorners ();

            stack = new Gtk.Stack ();
            stack.add_titled (wallpaper_view, "wallpaper", _("Wallpaper"));
            stack.add_titled (dock, "dock", _("Dock"));
            stack.add_titled (hotcorners, "hotc", _("Hot Corners"));

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = stack;
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.homogeneous = true;
            stack_switcher.margin = 24;

            main_grid.attach (stack_switcher, 0, 0, 1, 1);
            main_grid.attach (stack, 0, 1, 1, 1);
            main_grid.show_all ();
        }

        return main_grid;
    }

    public override void shown () {
        wallpaper_view.update_wallpaper_folder ();
    }

    public override void hidden () {
        wallpaper_view.cancel_thumbnail_generation ();
    }

    public override void search_callback (string location) {
        switch (location) {
            case "wallpaper":
                stack.set_visible_child_name ("wallpaper");
                break;
            case "dock":
                stack.set_visible_child_name ("dock");
                break;
            case "hotc":
                stack.set_visible_child_name ("hotc");
                break;
        }
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Wallpaper")), "wallpaper");
        search_results.set ("%s → %s".printf (display_name, _("Dock")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Theme")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Hide Mode")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Icon Size")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Display")), "dock");
        search_results.set ("%s → %s".printf (display_name, _("Hot Corners")), "hotc");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Desktop plug");
    var plug = new GalaPlug ();
    return plug;
}
