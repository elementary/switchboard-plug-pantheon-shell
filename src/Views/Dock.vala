/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2016-2023 elementary, Inc. (https://elementary.io)
 */

public class PantheonShell.Dock : Gtk.Box {
    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private Gtk.Label primary_monitor_label;
    private Gtk.Switch primary_monitor;
    private Gtk.Label monitor_label;
    private Gtk.ComboBoxText monitor;
    private Plank.DockPreferences dock_preferences;

    construct {
        var icon_header = new Granite.HeaderLabel (_("Dock Icon Size"));

        var icon_size_32 = new Gtk.RadioButton (null) {
            image = new Gtk.Image.from_icon_name ("dock-icon-symbolic", Gtk.IconSize.DND),
            tooltip_text = _("Small")
        };

        var icon_size_48 = new Gtk.RadioButton.from_widget (icon_size_32) {
            image = new Gtk.Image.from_icon_name ("dock-icon-symbolic", Gtk.IconSize.DIALOG),
            tooltip_text = _("Default")
        };

        var image_64 = new Gtk.Image () {
            icon_name = "dock-icon-symbolic",
            pixel_size = 64
        };

        var icon_size_64 = new Gtk.RadioButton.from_widget (icon_size_32) {
            image = image_64,
            tooltip_text = _("Large")
        };

        var icon_size_unsupported = new Gtk.RadioButton.from_widget (icon_size_32);

        var icon_size_box = new Gtk.Box (HORIZONTAL, 24);
        icon_size_box.add (icon_size_32);
        icon_size_box.add (icon_size_48);
        icon_size_box.add (icon_size_64);

        var icon_box = new Gtk.Box (VERTICAL, 0);
        icon_box.add (icon_header);
        icon_box.add (icon_size_box);

        Plank.Paths.initialize ("plank", Constants.PLANKDATADIR);

        var hide_header = new Granite.HeaderLabel (_("Hide Dock"));

        var hide_mode = new Gtk.ComboBoxText () {
            hexpand = true
        };
        hide_mode.append_text (_("When the focused window is maximized"));
        hide_mode.append_text (_("When the focused window overlaps the dock"));
        hide_mode.append_text (_("When any window overlaps the dock"));
        hide_mode.append_text (_("When not being used"));

        var hide_switch = new Gtk.Switch () {
            halign = END,
            hexpand = true,
            valign = CENTER
        };

        var hide_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        hide_grid.attach (hide_header, 0, 0);
        hide_grid.attach (hide_mode, 0, 1);
        hide_grid.attach (hide_switch, 1, 0, 1, 2);

        monitor = new Gtk.ComboBoxText ();

        primary_monitor_label = new Gtk.Label (_("Primary display:"));
        primary_monitor_label.halign = Gtk.Align.END;
        primary_monitor_label.no_show_all = true;

        monitor_label = new Gtk.Label (_("Display:"));
        monitor_label.no_show_all = true;
        monitor_label.halign = Gtk.Align.END;

        primary_monitor = new Gtk.Switch ();
        primary_monitor.no_show_all = true;

        var pressure_header = new Granite.HeaderLabel (_("Pressure Reveal"));

        var pressure_subtitle = new Gtk.Label (_("Prevent accidental reveals by moving the pointer past the display edge. Only works with some devices.")) {
            wrap = true,
            xalign = 0
        };
        pressure_subtitle.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var pressure_switch = new Gtk.Switch () {
            halign = END,
            hexpand = true,
            valign = CENTER
        };

        var pressure_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        pressure_grid.attach (pressure_header, 0, 0);
        pressure_grid.attach (pressure_subtitle, 0, 1);
        pressure_grid.attach (pressure_switch, 1, 0, 1, 2);

        var translucency_header = new Granite.HeaderLabel (_("Panel Translucency"));

        var translucency_subtitle = new Gtk.Label (_("Automatically transparent or opaque based on the wallpaper")) {
            wrap = true,
            xalign = 0
        };
        translucency_subtitle.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var translucency_switch = new Gtk.Switch () {
            halign = END,
            hexpand = true,
            valign = CENTER
        };

        var translucency_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        translucency_grid.attach (translucency_header, 0, 0);
        translucency_grid.attach (translucency_subtitle, 0, 1);
        translucency_grid.attach (translucency_switch, 1, 0, 1, 2);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 18,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 24
        };
        grid.attach (icon_box, 0, 0, 2);
        grid.attach (hide_grid, 0, 1, 2);
        grid.attach (primary_monitor_label, 0, 2);
        grid.attach (primary_monitor, 1, 2);
        grid.attach (monitor_label, 0, 3);
        grid.attach (monitor, 1, 3);
        grid.attach (pressure_grid, 0, 4, 2);
        grid.attach (translucency_grid, 0, 5, 2);

        var clamp = new Hdy.Clamp () {
            child = grid
        };

        add (clamp);

        check_for_screens ();

        switch (dock_preferences.IconSize) {
            case 32:
                icon_size_32.active = true;
                break;
            case 48:
                icon_size_48.active = true;
                break;
            case 64:
                icon_size_64.active = true;
                break;
            default:
                icon_size_unsupported.active = true;
                debug ("Unsupported dock icon size");
        }

        icon_size_32.toggled.connect (() => {
            dock_preferences.IconSize = 32;
        });

        icon_size_48.toggled.connect (() => {
            dock_preferences.IconSize = 48;
        });

        icon_size_64.toggled.connect (() => {
            dock_preferences.IconSize = 64;
        });

        dock_preferences = new Plank.DockPreferences ("dock1");
        dock_preferences.bind_property ("PressureReveal", pressure_switch, "active", SYNC_CREATE | BIDIRECTIONAL);

        Plank.HideType[] hide_mode_ids = {
            Plank.HideType.DODGE_MAXIMIZED,
            Plank.HideType.INTELLIGENT,
            Plank.HideType.WINDOW_DODGE,
            Plank.HideType.AUTO
        };

        var hide_none = (dock_preferences.HideMode != Plank.HideType.NONE);
        hide_switch.active = hide_none;
        if (hide_none) {
            for (int i = 0; i < hide_mode_ids.length; i++) {
                if (hide_mode_ids[i] == dock_preferences.HideMode)
                    hide_mode.active = i;
            }
        } else {
            hide_mode.sensitive = false;
        }

        hide_mode.changed.connect (() => {
            dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
        });

        hide_switch.bind_property ("active", pressure_grid, "sensitive", SYNC_CREATE);
        hide_switch.bind_property ("active", hide_mode, "sensitive", DEFAULT);

        hide_switch.notify["active"].connect (() => {
            if (hide_switch.active) {
                dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
            } else {
                dock_preferences.HideMode = Plank.HideType.NONE;
            }
        });

        primary_monitor.notify["active"].connect (() => {
            if (primary_monitor.active == true) {
                dock_preferences.Monitor = "";
                monitor_label.sensitive = false;
                monitor.sensitive = false;
            } else {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor.active) {
                    dock_preferences.Monitor = plug_names[monitor.active];
                }

                monitor_label.sensitive = true;
                monitor.sensitive = true;
            }
        });
        primary_monitor.active = (dock_preferences.Monitor == "");

        monitor.notify["active"].connect (() => {
            if (monitor.active >= 0 && primary_monitor.active == false) {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor.active)
                    dock_preferences.Monitor = plug_names[monitor.active];
            }
        });

        get_screen ().monitors_changed.connect (() => {check_for_screens ();});

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);
    }

    private void check_for_screens () {
        int i = 0;
        int primary_screen = 0;
        var default_display = get_display ();
        var default_screen = get_screen ();
        monitor.remove_all ();
        try {
            var screen = new Gnome.RRScreen (default_screen);
            for (i = 0; i < default_display.get_n_monitors () ; i++) {
                var monitor_plug_name = default_display.get_monitor (i).model;

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

                monitor.append_text (_("Monitor %d").printf (i + 1) );
            }
        } catch (Error e) {
            critical (e.message);
            for (i = 0; i < default_display.get_n_monitors () ; i ++) {
                monitor.append_text (_("Display %d").printf (i + 1));
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
                monitor.active = find_monitor_number (get_display (), dock_preferences.Monitor);
            } else {
                monitor.active = primary_screen;
            }

            primary_monitor_label.show ();
            primary_monitor.show ();
            monitor_label.show ();
            monitor.show ();
        }
    }

    static string[] get_monitor_plug_names (Gdk.Display display) {
        int n_monitors = display.get_n_monitors ();
        var result = new string[n_monitors];

        for (int i = 0; i < n_monitors; i++) {
            result[i] = display.get_monitor (i).model;
        }

        return result;
    }

    static int find_monitor_number (Gdk.Display display, string plug_name) {
        int n_monitors = display.get_n_monitors ();

        for (int i = 0; i < n_monitors; i++) {
            var monitor = display.get_monitor (i);
            var name = monitor.get_model ();
            if (plug_name == name)
                return i;
        }

        return display.get_n_monitors ();
    }

}
