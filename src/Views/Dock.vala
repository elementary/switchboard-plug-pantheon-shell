/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2016-2023 elementary, Inc. (https://elementary.io)
 */

public class PantheonShell.Dock : Granite.SimpleSettingsPage {
    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private Gtk.Grid display_grid;
    private Gtk.ComboBoxText display_combo;
    private Plank.DockPreferences dock_preferences;

    public Dock () {
        Object (
            title: _("Dock & Panel"),
            icon_name: "preferences-desktop"
        );
    }

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

        var hide_header = new Granite.HeaderLabel (_("Hide Dock"));

        var never_radio = new Gtk.RadioButton.with_label (
            null,
            _("Never")
        );

        var dodge_maximized_radio = new Gtk.RadioButton.with_label_from_widget (
            never_radio,
            _("When the focused window is maximized")
        );

        var intelligent_radio = new Gtk.RadioButton.with_label_from_widget (
            never_radio,
            _("When the focused window overlaps the dock")
        );

        var window_dodge_radio = new Gtk.RadioButton.with_label_from_widget (
            never_radio,
            _("When any window overlaps the dock")
        );

        var auto_radio = new Gtk.RadioButton.with_label_from_widget (
            never_radio,
            _("When not being used")
        );

        var hide_radio_box = new Gtk.Box (VERTICAL, 6);
        hide_radio_box.add (never_radio);
        hide_radio_box.add (dodge_maximized_radio);
        hide_radio_box.add (intelligent_radio);
        hide_radio_box.add (window_dodge_radio);
        hide_radio_box.add (auto_radio);

        var hide_box = new Gtk.Box (VERTICAL, 0);
        hide_box.add (hide_header);
        hide_box.add (hide_radio_box);

        display_combo = new Gtk.ComboBoxText () {
            hexpand = true
        };

        var display_header = new Granite.HeaderLabel (_("Dock on Primary Display"));

        var display_switch = new Gtk.Switch () {
            valign = CENTER
        };

        display_grid = new Gtk.Grid () {
            column_spacing = 12,
            no_show_all = true
        };
        display_grid.attach (display_header, 0, 0);
        display_grid.attach (display_combo, 0, 1);
        display_grid.attach (display_switch, 1, 0, 1, 2);

        var pressure_header = new Granite.HeaderLabel (_("Dock Pressure Reveal"));

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

        var indicators_header = new Granite.HeaderLabel (_("Show in Panel"));

        var indicators_box = new Gtk.Box (VERTICAL, 6);
        indicators_box.add (indicators_header);

        var a11y_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.wingpanel.a11y", true);
        if (a11y_schema != null && a11y_schema.has_key ("show-indicator")) {
            var a11y_check = new Gtk.CheckButton.with_label (_("Accessibility"));

            indicators_box.add (a11y_check);

            var a11y_settings = new Settings ("io.elementary.desktop.wingpanel.a11y");
            a11y_settings.bind ("show-indicator", a11y_check, "active", DEFAULT);
        }

        var keyboard_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.wingpanel.keyboard", true);
        if (keyboard_schema != null && keyboard_schema.has_key ("capslock")) {
            var caps_check = new Gtk.CheckButton.with_label (_("Caps Lock ⇪"));
            var num_check = new Gtk.CheckButton.with_label (_("Num Lock"));

            indicators_box.add (caps_check);
            indicators_box.add (num_check);

            var keyboard_settings = new Settings ("io.elementary.wingpanel.keyboard");
            keyboard_settings.bind ("capslock", caps_check, "active", DEFAULT);
            keyboard_settings.bind ("numlock", num_check, "active", DEFAULT);
        }

        var box = new Gtk.Box (VERTICAL, 18);
        box.add (icon_box);
        box.add (hide_box);
        box.add (pressure_grid);
        box.add (display_grid);
        box.add (translucency_grid);

        // Only add this box if it has more than the header in it
        if (indicators_box.get_children ().length () > 1) {
            box.add (indicators_box);
        }

        var clamp = new Hdy.Clamp () {
            child = box
        };

        content_area.add (clamp);

        dock_preferences = new Plank.DockPreferences ("dock1");
        dock_preferences.bind_property ("PressureReveal", pressure_switch, "active", SYNC_CREATE | BIDIRECTIONAL);

        Plank.Paths.initialize ("plank", Constants.PLANKDATADIR);

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

        pressure_grid.sensitive = dock_preferences.HideMode != NONE;
        switch (dock_preferences.HideMode) {
            case Plank.HideType.NONE:
                never_radio.active = true;
                break;
            case Plank.HideType.DODGE_MAXIMIZED:
                dodge_maximized_radio.active = true;
                break;
            case Plank.HideType.INTELLIGENT:
                intelligent_radio.active = true;
                break;
            case Plank.HideType.WINDOW_DODGE:
                window_dodge_radio.active = true;
                break;
            case Plank.HideType.AUTO:
                auto_radio.active = true;
                break;
        }

        never_radio.toggled.connect (() => {
            pressure_grid.sensitive = false;
            if (never_radio.active) {
                dock_preferences.HideMode = NONE;
            }
        });

        dodge_maximized_radio.toggled.connect (() => {
            pressure_grid.sensitive = true;
            if (dodge_maximized_radio.active) {
                dock_preferences.HideMode = DODGE_MAXIMIZED;
            }
        });

        intelligent_radio.toggled.connect (() => {
            pressure_grid.sensitive = true;
            if (intelligent_radio.active) {
                dock_preferences.HideMode = INTELLIGENT;
            }
        });

        window_dodge_radio.toggled.connect (() => {
            pressure_grid.sensitive = true;
            if (window_dodge_radio.active) {
                dock_preferences.HideMode = WINDOW_DODGE;
            }
        });

        auto_radio.toggled.connect (() => {
            pressure_grid.sensitive = true;
            if (auto_radio.active) {
                dock_preferences.HideMode = AUTO;
            }
        });

        display_switch.notify["active"].connect (() => {
            if (display_switch.active == true) {
                dock_preferences.Monitor = "";
            } else {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > display_combo.active) {
                    dock_preferences.Monitor = plug_names[display_combo.active];
                }
            }
        });
        display_switch.active = (dock_preferences.Monitor == "");
        display_switch.bind_property ("active", display_combo, "sensitive", INVERT_BOOLEAN);

        display_combo.notify["active"].connect (() => {
            if (display_combo.active >= 0 && display_switch.active == false) {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > display_combo.active)
                    dock_preferences.Monitor = plug_names[display_combo.active];
            }
        });

        get_screen ().monitors_changed.connect (check_for_screens);

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);
    }

    private void check_for_screens () {
        int i = 0;
        int primary_screen = 0;
        var default_display = get_display ();
        var default_screen = get_screen ();
        display_combo.remove_all ();
        try {
            var screen = new Gnome.RRScreen (default_screen);
            for (i = 0; i < default_display.get_n_monitors () ; i++) {
                var monitor_plug_name = default_display.get_monitor (i).model;

                if (monitor_plug_name != null) {
                    unowned Gnome.RROutput output = screen.get_output_by_name (monitor_plug_name);
                    if (output != null && output.get_display_name () != null && output.get_display_name () != "") {
                        display_combo.append_text (output.get_display_name ());
                        if (output.get_is_primary () == true) {
                            primary_screen = i;
                        }
                        continue;
                    }
                }

                display_combo.append_text (_("Monitor %d").printf (i + 1) );
            }
        } catch (Error e) {
            critical (e.message);
            for (i = 0; i < default_display.get_n_monitors () ; i ++) {
                display_combo.append_text (_("Display %d").printf (i + 1));
            }
        }

        if (i <= 1) {
            display_grid.no_show_all = true;
            display_grid.hide ();
        } else {
            if (dock_preferences.Monitor != "") {
                display_combo.active = find_monitor_number (get_display (), dock_preferences.Monitor);
            } else {
                display_combo.active = primary_screen;
            }

            display_grid.no_show_all = false;
            display_grid.show_all ();
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
