

public class Dock : Gtk.Grid {
    Gtk.Label primary_monitor_label;
    Gtk.Switch primary_monitor;
    Gtk.Label monitor_label;
    Gtk.ComboBoxText monitor;
    Plank.DockPreferences dock_preferences;

    public Dock () {
        column_spacing = 12;
        row_spacing = 6;
        margin = 24;
        column_homogeneous = true;

        var icon_size = new Gtk.ComboBoxText ();
        icon_size.append ("48", _("Normal"));
        icon_size.append ("64", _("Large"));
        icon_size.hexpand = true;

        Plank.Services.Paths.initialize ("plank", Constants.PLANKDATADIR);
        dock_preferences = new Plank.DockPreferences.with_file (Plank.Services.Paths.AppConfigFolder.get_child ("dock1").get_child ("settings"));
        var current = dock_preferences.IconSize;

        if (current != 48 && current != 64) {
            icon_size.append (current.to_string (), _("Custom (%dpx)").printf (current));
        }

        icon_size.active_id = current.to_string ();
        icon_size.halign = Gtk.Align.START;
        icon_size.changed.connect (() => {
            dock_preferences.IconSize = int.parse (icon_size.active_id);
        });

        Gtk.Box hide_mode_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, column_spacing);
        hide_mode_box.hexpand = true;        
        hide_mode_box.halign = Gtk.Align.START;

        Gtk.ComboBoxText hide_mode = new Gtk.ComboBoxText ();
        hide_mode.hexpand = true;        
        hide_mode.halign = Gtk.Align.START;
        hide_mode.append_text (_("Focused window is maximized"));
        hide_mode.append_text (_("Focused application overlaps the dock"));
        hide_mode.append_text (_("Any window overlaps the dock"));
        hide_mode.append_text (_("Not being used"));

        Plank.HideType[] hide_mode_ids = {Plank.HideType.DODGE_MAXIMIZED, Plank.HideType.INTELLIGENT, Plank.HideType.WINDOW_DODGE, Plank.HideType.AUTO};

        Gtk.Switch hide_switch = new Gtk.Switch ();

        var hide_none = (dock_preferences.HideMode != Plank.HideType.NONE);
        hide_switch.set_active (hide_none);
        if (hide_none) {
            for (int i = 0; i < hide_mode_ids.length; i++) {
                if (hide_mode_ids[i] == dock_preferences.HideMode)                    
                    hide_mode.active = i;
            }
        } else {
            hide_mode.set_sensitive (false);
        }

        hide_mode.changed.connect (() => {
            dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
        });

        hide_switch.notify["active"].connect (() => {
            if (hide_switch.active) {
                hide_mode.set_sensitive (true);
                dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
            } else {                
                hide_mode.set_sensitive (false);
                dock_preferences.HideMode = Plank.HideType.NONE;
            }
        });
        hide_mode_box.add (hide_mode);
        hide_mode_box.add (hide_switch);

        monitor = new Gtk.ComboBoxText ();
        monitor.halign = Gtk.Align.START;
        monitor.hexpand = true;

        primary_monitor_label = new Gtk.Label (_("Primary Display:"));
        primary_monitor_label.halign = Gtk.Align.END;
        primary_monitor_label.no_show_all = true;

        monitor_label = new Gtk.Label (_("Display:"));
        monitor_label.no_show_all = true;
        monitor_label.halign = Gtk.Align.END;

        primary_monitor = new Gtk.Switch ();
        primary_monitor.no_show_all = true;
        primary_monitor.notify["active"].connect (() => {
            if (primary_monitor.active == true) {
                dock_preferences.Monitor = "";
                monitor_label.sensitive = false;
                monitor.sensitive = false;
            } else {
                var plug_names = get_monitor_plug_names (get_screen ());
                if (plug_names.length > monitor.active)
                    dock_preferences.Monitor = plug_names[monitor.active];
                monitor_label.sensitive = true;
                monitor.sensitive = true;
            }
        });
        primary_monitor.active = (dock_preferences.Monitor == "");

        monitor.notify["active"].connect (() => {
            if (monitor.active >= 0 && primary_monitor.active == false) {
                var plug_names = get_monitor_plug_names (get_screen ());
                if (plug_names.length > monitor.active)
                    dock_preferences.Monitor = plug_names[monitor.active];
            }
        });

        get_screen ().monitors_changed.connect (() => {check_for_screens ();});

        var icon_label = new Gtk.Label (_("Icon Size:"));
        icon_label.set_halign (Gtk.Align.END);
        var hide_label = new Gtk.Label (_("Hide when:"));
        hide_label.set_halign (Gtk.Align.END);
        hide_label.set_valign (Gtk.Align.START);
        hide_label.set_margin_top (4);
        var primary_monitor_grid = new Gtk.Grid ();
        primary_monitor_grid.add (primary_monitor);

        attach (icon_label, 1, 0, 1, 1);
        attach (icon_size, 2, 0, 1, 1);
        attach (hide_label, 1, 1, 1, 1);
        attach (hide_mode_box, 2, 1, 1, 1);
        attach (primary_monitor_label, 1, 3, 1, 1);
        attach (primary_monitor_grid, 2, 3, 1, 1);
        attach (monitor_label, 1, 4, 1, 1);
        attach (monitor, 2, 4, 1, 1);

        check_for_screens ();
    }

    private void check_for_screens () {
        int i = 0;
        int primary_screen = 0;
        var default_screen = get_screen ();
        monitor.remove_all ();
        try {
            var screen = new Gnome.RRScreen (default_screen);
            for (i = 0; i < default_screen.get_n_monitors () ; i++) {
                var monitor_plug_name = default_screen.get_monitor_plug_name (i);

                if (monitor_plug_name != null) {
                    unowned Gnome.RROutput output = screen.get_output_by_name (monitor_plug_name);
                    if (output != null && output.get_display_name () != null && output.get_display_name () != "") {
                        monitor.append_text (output.get_display_name ());
                        if (output.get_is_primary () == true) {
                            primary_screen = i;
                        }
                        continue;
                    }
                }

                monitor.append_text (_("Monitor %d").printf (i+1) );
            }
        } catch (Error e) {
            critical (e.message);
            for (i = 0; i < default_screen.get_n_monitors () ; i ++) {
                monitor.append_text (_("Display %d").printf (i+1) );
            }
        }

        if (i <= 1) {
            primary_monitor_label.hide ();
            primary_monitor.hide ();
            monitor_label.hide ();
            monitor.no_show_all = true;
            monitor.hide ();
        } else {
            if (dock_preferences.Monitor != "") {
                monitor.active = find_monitor_number (get_screen (), dock_preferences.Monitor);
            } else {
                monitor.active = primary_screen;
            }

            primary_monitor_label.show ();
            primary_monitor.show ();
            monitor_label.show ();
            monitor.show ();
        }
    }

    static string[] get_monitor_plug_names (Gdk.Screen screen) {
        int n_monitors = screen.get_n_monitors ();
        var result = new string[n_monitors];

        for (int i = 0; i < n_monitors; i++)
            result[i] = screen.get_monitor_plug_name (i);

        return result;
    }

    static int find_monitor_number (Gdk.Screen screen, string plug_name) {
        int n_monitors = screen.get_n_monitors ();

        for (int i = 0; i < n_monitors; i++) {
            var name = screen.get_monitor_plug_name (i);
            if (plug_name == name)
                return i;
        }

        return screen.get_primary_monitor ();
    }
}
