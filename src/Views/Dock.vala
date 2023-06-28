/*
* Copyright (c) 2016 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
        var dock_header = new Granite.HeaderLabel (_("Dock"));

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

        Plank.Paths.initialize ("plank", Constants.PLANKDATADIR);
        dock_preferences = new Plank.DockPreferences ("dock1");

        var pressure_switch = new Gtk.Switch ();
        pressure_switch.halign = Gtk.Align.START;
        pressure_switch.valign = Gtk.Align.CENTER;

        dock_preferences.bind_property ("PressureReveal", pressure_switch, "active", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.BIDIRECTIONAL);

        var hide_mode = new Gtk.ComboBoxText () {
            hexpand = true
        };
        hide_mode.append_text (_("Focused window is maximized"));
        hide_mode.append_text (_("Focused window overlaps the dock"));
        hide_mode.append_text (_("Any window overlaps the dock"));
        hide_mode.append_text (_("Not being used"));

        Plank.HideType[] hide_mode_ids = {Plank.HideType.DODGE_MAXIMIZED, Plank.HideType.INTELLIGENT, Plank.HideType.WINDOW_DODGE, Plank.HideType.AUTO};

        var hide_switch = new Gtk.Switch ();
        hide_switch.halign = Gtk.Align.START;
        hide_switch.valign = Gtk.Align.CENTER;

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

        hide_switch.bind_property ("active", pressure_switch, "sensitive", BindingFlags.SYNC_CREATE);
        hide_switch.bind_property ("active", hide_mode, "sensitive", BindingFlags.DEFAULT);

        hide_switch.notify["active"].connect (() => {
            if (hide_switch.active) {
                dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
            } else {
                dock_preferences.HideMode = Plank.HideType.NONE;
            }
        });

        monitor = new Gtk.ComboBoxText ();

        primary_monitor_label = new Gtk.Label (_("Primary display:"));
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
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor.active)
                    dock_preferences.Monitor = plug_names[monitor.active];
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

        var icon_label = new Gtk.Label (_("Icon size:"));
        icon_label.halign = Gtk.Align.END;
        var hide_label = new Gtk.Label (_("Hide when:"));
        hide_label.halign = Gtk.Align.END;
        var primary_monitor_grid = new Gtk.Grid ();
        primary_monitor_grid.add (primary_monitor);
        var pressure_label = new Gtk.Label (_("Pressure reveal:"));
        pressure_label.halign = Gtk.Align.END;

        var panel_header = new Granite.HeaderLabel (_("Panel")) {
            margin_top = 12
        };

        var translucency_label = new Gtk.Label (_("Panel translucency:")) {
            halign = Gtk.Align.END
        };

        var translucency_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

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

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 24
        };
        grid.attach (dock_header, 0, 0, 3);
        grid.attach (icon_label, 0, 1);
        grid.attach (icon_size_box, 1, 1, 2);
        grid.attach (hide_label, 0, 2);
        grid.attach (hide_mode, 1, 2);
        grid.attach (hide_switch, 2, 2);
        grid.attach (primary_monitor_label, 0, 3);
        grid.attach (primary_monitor_grid, 1, 3);
        grid.attach (monitor_label, 0, 4);
        grid.attach (monitor, 1, 4);
        grid.attach (pressure_label, 0, 5);
        grid.attach (pressure_switch, 1, 5);
        grid.attach (panel_header, 0, 6, 3);
        grid.attach (translucency_label, 0, 7);
        grid.attach (translucency_switch, 1, 7);

        // Only add this box if it has more than the header in it
        if (indicators_box.get_children ().length () > 1) {
            grid.attach (indicators_box, 0, 8);
        }

        var clamp = new Hdy.Clamp ();
        clamp.add (grid);

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
