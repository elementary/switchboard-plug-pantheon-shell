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
                description: _("Change your wallpaper and customize your dock"),
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
            build_dock_panel ();
            
            /*hot corners*/
            build_hotcorners_panel ();
            
            main_grid.attach (stack_switcher, 0, 0, 1, 1);
            main_grid.attach (stack, 0, 1, 1, 1);
            main_grid.show_all ();
        }
        
        return main_grid;
    }

    private void build_dock_panel () {
        var dock_grid = new Gtk.Grid ();
        dock_grid.expand = true;
        dock_grid.column_spacing = 12;
        dock_grid.row_spacing = 6;
        dock_grid.margin = 24;
        dock_grid.column_homogeneous = true;

        var icon_size = new Gtk.ComboBoxText ();
        icon_size.append ("32", _("Small"));
        icon_size.append ("48", _("Medium"));
        icon_size.append ("64", _("Large"));
        icon_size.append ("128", _("Extra Large"));
        icon_size.hexpand = true;

        var plank_settings = PlankSettings.get_default ();
        var current = plank_settings.icon_size;

        if (current != 32 && current != 48 && current != 64 && current != 128) {
            icon_size.append (current.to_string (), _(@"Custom ($(current)px)" ));
        }

        icon_size.active_id = current.to_string ();
        icon_size.changed.connect (() => plank_settings.icon_size = int.parse (icon_size.active_id));
        icon_size.halign = Gtk.Align.START;

        var hide_mode = new Gtk.ComboBoxText ();
        hide_mode.append ("0", _("Don't hide"));
        hide_mode.append ("1", _("Intelligent hide"));
        hide_mode.append ("2", _("Auto hide"));
        hide_mode.append ("3", _("Hide on maximize"));
        hide_mode.active_id = plank_settings.hide_mode.to_string ();
        hide_mode.changed.connect (() => plank_settings.hide_mode = int.parse (hide_mode.active_id));
        hide_mode.halign = Gtk.Align.START;
        hide_mode.hexpand = true;

        var theme = new Gtk.ComboBoxText ();

        int theme_index = 0;
        try {
            string name;
            var dirs = Environment.get_system_data_dirs ();
            dirs += Environment.get_user_data_dir ();

            foreach (string dir in dirs) {
                if (FileUtils.test (dir + "/plank/themes", FileTest.EXISTS)) {
                    var d = Dir.open(dir + "/plank/themes");
                    while ((name = d.read_name()) != null) {
                        theme.append(theme_index.to_string (), _(name));
                        if (plank_settings.theme.to_string () == name) {
                            theme.active = theme_index;
                        }

                        theme_index++;
                    }
                }
            }
        } catch (GLib.FileError e) {
            warning (e.message);
        }

        theme.changed.connect (() => plank_settings.theme = theme.get_active_text ());
        theme.halign = Gtk.Align.START;
        theme.hexpand = true;

        var monitor = new Gtk.ComboBoxText ();
        int i = 0;
        var default_screen = Gdk.Screen.get_default ();
        try {
            var screen = new Gnome.RRScreen (Gdk.Screen.get_default ());
            for (i = 0; i < default_screen.get_n_monitors (); i++) {
                var monitor_plug_name = default_screen.get_monitor_plug_name (i);
                unowned Gnome.RROutput output = screen.get_output_by_name (monitor_plug_name);
                if (output != null) {
                    if (output.get_display_name () != null && output.get_display_name () != "") {
                        monitor.append_text (output.get_display_name ());
                    } else {
                        monitor.append_text (_("Monitor %d").printf (i+1) );
                    }
                } else {
                    monitor.append_text (_("Monitor %d").printf (i+1) );
                }
            }
        } catch (Error e) {
            critical (e.message);
            for (i = 0; i < default_screen.get_n_monitors (); i++) {
                monitor.append_text (_("Monitor %d").printf (i+1) );
            }
        }

        monitor.active = plank_settings.monitor;
        monitor.halign = Gtk.Align.START;
        monitor.hexpand = true;

        var primary_monitor_label = new Gtk.Label (_("Primary Monitor:"));
        primary_monitor_label.set_halign (Gtk.Align.END);
        var monitor_label = new Gtk.Label (_("Monitor:"));
        monitor_label.set_halign (Gtk.Align.END);

        var primary_monitor = new Gtk.Switch ();
        primary_monitor.notify["active"].connect (() => {
            if (primary_monitor.active == true) {
                plank_settings.monitor = -1;
                monitor_label.sensitive = false;
                monitor.sensitive = false;
            } else {
                plank_settings.monitor = monitor.active;
                monitor_label.sensitive = true;
                monitor.sensitive = true;
            }
        });
        primary_monitor.active = (plank_settings.monitor == -1);

        monitor.notify["active"].connect (() => {
            if (monitor.active >= 0 && primary_monitor.active == false)
                plank_settings.monitor = monitor.active;
        });

        default_screen.monitors_changed.connect (() => {
            monitor.remove_all ();
            try {
                var screen = new Gnome.RRScreen (Gdk.Screen.get_default ());
                for (i = 0; i < default_screen.get_n_monitors () ; i++) {
                    var monitor_plug_name = default_screen.get_monitor_plug_name (i);
                    unowned Gnome.RROutput output = screen.get_output_by_name (monitor_plug_name);
                    if (output != null) {
                        if (output.get_display_name () != null && output.get_display_name () != "") {
                            monitor.append_text (output.get_display_name ());
                        } else {
                            monitor.append_text (_("Monitor %d").printf (i+1) );
                        }
                    } else {
                        monitor.append_text (_("Monitor %d").printf (i+1) );
                    }
                }
            } catch (Error e) {
                critical (e.message);
                for (i = 0; i < default_screen.get_n_monitors () ; i ++) {
                    monitor.append_text (_("Monitor %d").printf (i+1) );
                }
            }

            if (plank_settings.monitor >= 0)
                monitor.active = plank_settings.monitor;
            else
                monitor.active = 0;

            if (i <= 1) {
                primary_monitor_label.no_show_all = true;
                primary_monitor_label.hide ();
                primary_monitor.no_show_all = true;
                primary_monitor.hide ();
                monitor_label.no_show_all = true;
                monitor_label.hide ();
                monitor.no_show_all = true;
                monitor.hide ();
            } else {
                primary_monitor_label.no_show_all = false;
                primary_monitor_label.show_all ();
                primary_monitor.no_show_all = false;
                primary_monitor.show_all ();
                monitor_label.no_show_all = false;
                monitor_label.show_all ();
                monitor.no_show_all = false;
                monitor.show_all ();
            }
        });

        var icon_label = new Gtk.Label (_("Icon Size:"));
        icon_label.set_halign (Gtk.Align.END);
        var hide_label = new Gtk.Label (_("Hide Mode:"));
        hide_label.set_halign (Gtk.Align.END);
        var fake_label_1 = new Gtk.Label ("");
        fake_label_1.hexpand = true;
        var fake_label_2 = new Gtk.Label ("");
        fake_label_2.hexpand = true;
        var primary_monitor_grid = new Gtk.Grid ();
        primary_monitor_grid.add (primary_monitor);

        dock_grid.attach (fake_label_1, 0, 0, 1, 1);
        dock_grid.attach (fake_label_2, 3, 0, 1, 1);
        dock_grid.attach (icon_label, 1, 0, 1, 1);
        dock_grid.attach (icon_size, 2, 0, 1, 1);
        dock_grid.attach (hide_label, 1, 1, 1, 1);
        dock_grid.attach (hide_mode, 2, 1, 1, 1);
        dock_grid.attach (primary_monitor_label, 1, 3, 1, 1);
        dock_grid.attach (primary_monitor_grid, 2, 3, 1, 1);
        dock_grid.attach (monitor_label, 1, 4, 1, 1);
        dock_grid.attach (monitor, 2, 4, 1, 1);

        if (theme_index > 1) {
            var theme_label = new Gtk.Label (_("Theme:"));
            theme_label.set_halign (Gtk.Align.END);
            dock_grid.attach (theme_label, 1, 2, 1, 1);
            dock_grid.attach (theme, 2, 2, 1, 1);
        }

        if (i <= 1) {
            primary_monitor_label.no_show_all = true;
            primary_monitor.no_show_all = true;
            monitor_label.no_show_all = true;
            monitor.no_show_all = true;
        } else {
            if (plank_settings.monitor >= 0)
                monitor.active = plank_settings.monitor;
            else
                monitor.active = 0;
        }

        stack.add_titled (dock_grid, "dock", _("Dock"));
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

        var icon = new Gtk.Image.from_file (Constants.PKGDATADIR + "/hotcornerdisplay.png");
        var custom_command = new Gtk.Entry ();
        custom_command.text = BehaviorSettings.get_default ().hotcorner_custom_command;
        custom_command.changed.connect (() => BehaviorSettings.get_default ().hotcorner_custom_command = custom_command.text );
        
        var cc_label = new Gtk.Label (_("Custom Command:"));
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
        box.append ("0", _("Do Nothing"));
        box.append ("1", _("Workspace Overview"));
        box.append ("2", _("Maximize Current Window"));
        box.append ("3", _("Minimize Current Window"));
        box.append ("4", _("Show Applications Menu"));
        box.append ("6", _("Window Overview"));
        box.append ("7", _("Show All Windows"));
        box.append ("5", _("Execute Custom Command"));

        return box;
    }
    
    public override void shown () {
        
    }
    
    public override void hidden () {
        
    }
    
    public override void search_callback (string location) {
    
    }
    
    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        return new Gee.TreeMap<string, string> (null, null);
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Desktop plug");
    var plug = new GalaPlug ();
    return plug;
}