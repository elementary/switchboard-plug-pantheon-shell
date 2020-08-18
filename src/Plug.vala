/*
* Copyright (c) 2011–2018 elementary, Inc. (https://elementary.io)
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
*/

public class PantheonShell.Plug : Switchboard.Plug {
    private Gtk.Stack stack;
    private Gtk.Grid main_grid;

    private Wallpaper wallpaper_view;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("desktop", null);
        settings.set ("desktop/appearance/wallpaper", "wallpaper");
        settings.set ("desktop/appearance", "appearance");
        settings.set ("desktop/dock", "dock");
        settings.set ("desktop/multitasking, "multitasking");

        // DEPRECATED
        settings.set ("desktop/wallpaper", "wallpaper");
        settings.set ("desktop/hot-corners", "multitasking");

        Object (category: Category.PERSONAL,
                code_name: "io.elementary.switchboard.pantheon-shell",
                display_name: _("Desktop"),
                description: _("Configure the dock, hot corners, and change wallpaper"),
                icon: "preferences-desktop-wallpaper",
                supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();

            wallpaper_view = new Wallpaper (this);

            var multitasking = new Multitasking ();

            stack = new Gtk.Stack ();
            stack.add_titled (wallpaper_view, "wallpaper", _("Wallpaper"));

            var appearance = new Appearance ();
            stack.add_titled (appearance, "appearance", _("Appearance"));

            if (GLib.Environment.find_program_in_path ("plank") != null) {
                var dock = new Dock ();
                stack.add_titled (dock, "dock", _("Dock"));
            }

            stack.add_titled (multitasking, "multitasking", _("Multitasking"));

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
            case "appearance":
                stack.set_visible_child_name ("appearance");
                break;
            case "dock":
                stack.set_visible_child_name ("dock");
                break;
            case "multitasking":
                stack.set_visible_child_name ("multitasking");
                break;
        }
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ();
        search_results.set ("%s → %s".printf (display_name, _("Wallpaper")), "wallpaper");
        search_results.set ("%s → %s".printf (display_name, _("Dock")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Hide Mode")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Icon Size")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Pressure reveal")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock"), _("Display")), "dock");
        search_results.set ("%s → %s".printf (display_name, _("Appearance")), "appearance");
        search_results.set ("%s → %s → %s".printf (display_name, _("Appearance"), _("Window animations")), "appearance");
        search_results.set ("%s → %s → %s".printf (display_name, _("Appearance"), _("Panel translucency")), "appearance");
        search_results.set ("%s → %s → %s".printf (display_name, _("Appearance"), _("Text size")), "appearance");
        search_results.set ("%s → %s → %s".printf (display_name, _("Appearance"), _("Dyslexia-friendly text")), "appearance");
        search_results.set ("%s → %s".printf (display_name, _("Multitasking")), "multitasking");
        search_results.set ("%s → %s → %s".printf (display_name, _("Multitasking"), _("Hot Corners")), "multitasking");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Desktop plug");
    var plug = new PantheonShell.Plug ();
    return plug;
}
