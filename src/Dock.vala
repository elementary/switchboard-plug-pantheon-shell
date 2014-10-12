

public class Dock : Gtk.Grid {
    Gtk.Label primary_monitor_label;
    Gtk.Switch primary_monitor;
    Gtk.Label monitor_label;
    Gtk.ComboBoxText monitor;
    public Dock () {
        column_spacing = 12;
        row_spacing = 6;
        margin = 24;
        column_homogeneous = true;

        var icon_size = new Gtk.ComboBoxText ();
        icon_size.append ("48", _("Normal"));
        icon_size.append ("64", _("Large"));
        icon_size.hexpand = true;

        var plank_settings = PlankSettings.get_default ();
        var current = plank_settings.icon_size;

        if (current != 48 && current != 64) {
            icon_size.append (current.to_string (), _("Custom (%dpx)").printf (current));
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
        string name;
        var dirs = Environment.get_system_data_dirs ();
        dirs += Environment.get_user_data_dir ();

        foreach (string dir in dirs) {
            if (FileUtils.test (dir + "/plank/themes", FileTest.EXISTS)) {
                try {
                    var d = Dir.open(dir + "/plank/themes");
                    while ((name = d.read_name()) != null) {
                        theme.append(theme_index.to_string (), _(name));
                        if (plank_settings.theme.to_string () == name) {
                            theme.active = theme_index;
                        }

                        theme_index++;
                    }
                } catch (GLib.FileError e) {
                    critical (e.message);
                }
            }
        }

        theme.changed.connect (() => plank_settings.theme = theme.get_active_text ());
        theme.halign = Gtk.Align.START;
        theme.hexpand = true;

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

        Gdk.Screen.get_default ().monitors_changed.connect (() => {check_for_screens ();});

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

        attach (fake_label_1, 0, 0, 1, 1);
        attach (fake_label_2, 3, 0, 1, 1);
        attach (icon_label, 1, 0, 1, 1);
        attach (icon_size, 2, 0, 1, 1);
        attach (hide_label, 1, 1, 1, 1);
        attach (hide_mode, 2, 1, 1, 1);
        attach (primary_monitor_label, 1, 3, 1, 1);
        attach (primary_monitor_grid, 2, 3, 1, 1);
        attach (monitor_label, 1, 4, 1, 1);
        attach (monitor, 2, 4, 1, 1);

        if (theme_index > 1) {
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
        var plank_settings = PlankSettings.get_default ();
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
            if (plank_settings.monitor >= 0) {
                monitor.active = plank_settings.monitor;
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