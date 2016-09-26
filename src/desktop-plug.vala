//
//  Copyright (C) 2011 Tom Beckmann
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public class GalaPlug : Switchboard.Plug {
    Gtk.Stack stack;
    Gtk.Grid main_grid;

    public GalaPlug () {
        Object (category: Category.PERSONAL,
                code_name: "pantheon-desktop",
                display_name: _("Desktop"),
                description: _("Configure the dock, hot corners, and change wallpaper"),
                icon: "preferences-desktop-wallpaper");
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();
            stack = new Gtk.Stack ();
            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = stack;
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.margin_top = 12;
            
            /*wallpaper*/
            var wallpaper = new Wallpaper (this);
            wallpaper.expand = true;
            stack.add_titled (wallpaper, "wallpaper", _("Wallpaper"));
            
            /*dock*/
            var dock = new Dock ();
            dock.expand = true;
            stack.add_titled (dock, "dock", _("Dock"));

            /*hot corners*/
            build_hotcorners_panel ();

            main_grid.attach (stack_switcher, 0, 0, 1, 1);
            main_grid.attach (stack, 0, 1, 1, 1);
            main_grid.show_all ();
        }

        return main_grid;
    }

    private void build_hotcorners_panel () {
        var hotc_grid = new Gtk.Grid ();
        hotc_grid.expand = true;
        hotc_grid.column_spacing = 12;
        hotc_grid.margin = 32;
        hotc_grid.margin_top = 48;

        var expl = new Gtk.Label (_("When the cursor enters the corner of the display:"));
        expl.set_halign (Gtk.Align.START);
        expl.margin_bottom = 10;
        expl.set_hexpand (true);

        var topleft = create_hotcorner ();
        topleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topleft").to_string ();
        topleft.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-topleft", int.parse (topleft.active_id)));
        topleft.valign = Gtk.Align.START;
        var topright = create_hotcorner ();
        topright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topright").to_string ();
        topright.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-topright", int.parse (topright.active_id)));
        topright.valign = Gtk.Align.START;
        var bottomleft = create_hotcorner ();
        bottomleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomleft").to_string ();
        bottomleft.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-bottomleft", int.parse (bottomleft.active_id)));
        bottomleft.valign = Gtk.Align.END;
        var bottomright = create_hotcorner ();
        bottomright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomright").to_string ();
        bottomright.changed.connect (() => BehaviorSettings.get_default ().schema.set_enum ("hotcorner-bottomright", int.parse (bottomright.active_id)));
        bottomright.valign = Gtk.Align.END;

        var icon = new Gtk.Image.from_file (Constants.PKGDATADIR + "/hotcornerdisplay.svg");
        icon.get_style_context ().add_class ("hotcorner-display");
        icon.expand = true;
        var custom_command = new Gtk.Entry ();
        custom_command.text = BehaviorSettings.get_default ().hotcorner_custom_command;
        custom_command.changed.connect (() => BehaviorSettings.get_default ().hotcorner_custom_command = custom_command.text );
        
        var cc_label = new Gtk.Label (_("Custom command:"));
        cc_label.set_halign (Gtk.Align.START);
        
        var cc_grid = new Gtk.Grid ();
        cc_grid.expand = true;
        cc_grid.set_column_spacing (12);
        cc_grid.set_margin_top (48);
        cc_grid.attach (cc_label, 0, 0, 1, 1);
        cc_grid.attach (custom_command, 1, 0, 1, 1);

        hotc_grid.attach (expl, 0, 0, 3, 1);
        hotc_grid.attach (icon, 1, 1, 1, 3);
        hotc_grid.attach (topleft, 0, 1, 1, 1);
        hotc_grid.attach (topright, 2, 1, 1, 1);
        hotc_grid.attach (bottomleft, 0, 3, 1, 1);
        hotc_grid.attach (bottomright, 2, 3, 1, 1);
        hotc_grid.attach (cc_grid, 0, 4, 2, 1);

        stack.add_titled (hotc_grid, "hotc", _("Hot Corners"));
    }

    private Gtk.ComboBoxText create_hotcorner () {
        var box = new Gtk.ComboBoxText ();
        box.append ("0", _("Do nothing"));              // none
        box.append ("1", _("Multitasking View"));       // show-workspace-view
        box.append ("2", _("Maximize current window")); // maximize-current
        box.append ("3", _("Minimize current window")); // minimize-current
        box.append ("4", _("Show Applications Menu"));  // open-launcher
        box.append ("7", _("Show all windows"));        // window-overview-all
        box.append ("5", _("Execute custom command"));  // custom-command

        return box;
    }

    public override void shown () {
        
    }

    public override void hidden () {
        
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
