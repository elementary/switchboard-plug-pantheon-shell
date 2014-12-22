

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

        Gtk.Box hide_mode = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        string[] hide_mode_labels = new string[4];
        hide_mode_labels[0] = _("Hide when focused window is maximized");
        hide_mode_labels[1] = _("Hide when focused window overlaps the dock");
        hide_mode_labels[2] = _("Automatically hide when not being used");
        hide_mode_labels[3] = _("Never hide");
        Plank.HideType[] hide_mode_ids = {Plank.HideType.DODGE_MAXIMIZED, Plank.HideType.INTELLIGENT, Plank.HideType.AUTO, Plank.HideType.NONE};

        Gtk.RadioButton button = new Gtk.RadioButton(null);
        for (int i = 0; i < hide_mode_labels.length; i++) {
            int index = i;
            button = new Gtk.RadioButton.with_label_from_widget (button, hide_mode_labels[i]);
            hide_mode.pack_start (button, false, false, 2);
            if (hide_mode_ids[i] == dock_preferences.HideMode)
                button.set_active (true);
            button.toggled.connect ((b) => {
                if (b.get_active ()) {
                    dock_preferences.HideMode = hide_mode_ids[index];
                }
            });
        }

        var theme = new Gtk.ComboBoxText ();
        theme.halign = Gtk.Align.START;
        theme.hexpand = true;
        var themes_list = Plank.Drawing.Theme.get_theme_list ();
        foreach (string theme_name in themes_list) {
            switch (theme_name) {
                case Plank.Drawing.Theme.GTK_THEME_NAME:
                    theme.append (theme_name, _("Desktop Theme"));
                    break;
                case Plank.Drawing.Theme.DEFAULT_NAME:
                    theme.append (theme_name, _("Default"));
                    break;
                default:
                    theme.append (theme_name, theme_name);
                    break;
            }
        }

        theme.active_id = dock_preferences.Theme;
        theme.changed.connect (() => {
            dock_preferences.Theme = theme.get_active_id ();
        });

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
                dock_preferences.Monitor = -1;
                monitor_label.sensitive = false;
                monitor.sensitive = false;
            } else {
                dock_preferences.Monitor = monitor.active;
                monitor_label.sensitive = true;
                monitor.sensitive = true;
            }
        });
        primary_monitor.active = (dock_preferences.Monitor == -1);

        monitor.notify["active"].connect (() => {
            if (monitor.active >= 0 && primary_monitor.active == false) {
                dock_preferences.Monitor = monitor.active;
            }
        });

        Gdk.Screen.get_default ().monitors_changed.connect (() => {check_for_screens ();});

        var icon_label = new Gtk.Label (_("Icon Size:"));
        icon_label.set_halign (Gtk.Align.END);
        var hide_label = new Gtk.Label (_("Hide Mode:"));
        hide_label.set_halign (Gtk.Align.END);
        hide_label.set_valign (Gtk.Align.START);
        hide_label.set_margin_top (4);
        var primary_monitor_grid = new Gtk.Grid ();
        primary_monitor_grid.add (primary_monitor);

        attach (icon_label, 1, 0, 1, 1);
        attach (icon_size, 2, 0, 1, 1);
        attach (hide_label, 1, 1, 1, 1);
        attach (hide_mode, 2, 1, 1, 1);
        attach (primary_monitor_label, 1, 3, 1, 1);
        attach (primary_monitor_grid, 2, 3, 1, 1);
        attach (monitor_label, 1, 4, 1, 1);
        attach (monitor, 2, 4, 1, 1);

        if (themes_list.size > 0) {
            var theme_label = new Gtk.Label (_("Theme:"));
            theme_label.set_halign (Gtk.Align.END);
            attach (theme_label, 1, 2, 1, 1);
            attach (theme, 2, 2, 1, 1);
        }

        check_for_screens ();
    }

    private void check_for_screens () {
        int i = 0;
        int primary_screen = 0;
        var default_screen = Gdk.Screen.get_default ();
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
            if (dock_preferences.Monitor >= 0) {
                monitor.active = dock_preferences.Monitor;
            } else {
                monitor.active = primary_screen;
            }

            primary_monitor_label.show ();
            primary_monitor.show ();
            monitor_label.show ();
            monitor.show ();
        }
    }
}
