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

public class PantheonShell.Dock : Gtk.Widget {
    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private Gtk.Label primary_monitor_label;
    private Gtk.Switch primary_monitor;
    private Gtk.Label monitor_label;
    private Gtk.ComboBoxText monitor_combo;
    private Settings dock_preferences;

    private enum PlankHideTypes {
        NONE,
        INTELLIGENT,
        AUTO,
        DODGE_MAXIMIZED,
        WINDOW_DODGE,
        DODGE_ACTIVE
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        var dock_header = new Granite.HeaderLabel (_("Dock"));

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/io/elementary/switchboard/plug/pantheon-shell");

        var icon_size_32 = new Gtk.CheckButton () {
            tooltip_text = _("Small")
        };
        var icon_size_32_image = new Gtk.Image.from_icon_name ("application-default-icon-symbolic") {
            pixel_size = 32
        };
        icon_size_32_image.set_parent (icon_size_32);

        var icon_size_48 = new Gtk.CheckButton () {
            tooltip_text = _("Default")
        };
        icon_size_48.group = icon_size_32;
        var icon_size_48_image = new Gtk.Image.from_icon_name ("application-default-icon-symbolic") {
            pixel_size = 48
        };
        icon_size_48_image.set_parent (icon_size_48);

        var image_64 = new Gtk.Image () {
            icon_name = "application-default-icon-symbolic",
            pixel_size = 64
        };

        var icon_size_64 = new Gtk.CheckButton () {
            tooltip_text = _("Large"),
            group = icon_size_32
        };
        image_64.set_parent (icon_size_64);

        var icon_size_unsupported = new Gtk.CheckButton () {
            group = icon_size_32
        };

        var icon_size_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 24);
        icon_size_grid.append (icon_size_32);
        icon_size_grid.append (icon_size_48);
        icon_size_grid.append (icon_size_64);

        var schema_id = "net.launchpad.plank.dock.settings";
        var schema = GLib.SettingsSchemaSource.get_default ().lookup (schema_id, true);
        if (schema == null) {
          error ("GSettingsSchema '%s' not found", schema_id);
        }

        dock_preferences = new Settings.full (schema, null, "/net/launchpad/plank/docks/dock1/");

        var pressure_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER
        };

        dock_preferences.bind ("pressure-reveal", pressure_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var hide_mode = new Gtk.ComboBoxText () {
            hexpand = true
        };
        hide_mode.append_text (_("Focused window is maximized"));
        hide_mode.append_text (_("Focused window overlaps the dock"));
        hide_mode.append_text (_("Any window overlaps the dock"));
        hide_mode.append_text (_("Not being used"));

        PlankHideTypes[] hide_mode_ids = {PlankHideTypes.DODGE_MAXIMIZED, PlankHideTypes.INTELLIGENT, PlankHideTypes.WINDOW_DODGE, PlankHideTypes.AUTO};

        var hide_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER
        };

        var hide_none = (dock_preferences.get_enum ("hide-mode") != PlankHideTypes.NONE);
        hide_switch.active = hide_none;
        if (hide_none) {
            for (var i = 0; i < hide_mode_ids.length; i++) {
                if (hide_mode_ids[i] == dock_preferences.get_enum ("hide-mode")) {
                    hide_mode.active = i;
                }
            }
        } else {
            hide_mode.sensitive = false;
        }

        hide_switch.bind_property ("active", pressure_switch, "sensitive", BindingFlags.SYNC_CREATE);
        hide_switch.bind_property ("active", hide_mode, "sensitive", BindingFlags.DEFAULT);

        hide_mode.changed.connect (() => {
            dock_preferences.set_enum ("hide-mode", hide_mode_ids[hide_mode.active]);
        });

        hide_switch.notify["active"].connect (() => {
            if (hide_switch.active) {
                dock_preferences.set_enum ("hide-mode", hide_mode_ids[hide_mode.active]);
            } else {
                dock_preferences.set_enum ("hide-mode", PlankHideTypes.NONE);
            }
        });

        monitor_combo = new Gtk.ComboBoxText ();

        primary_monitor_label = new Gtk.Label (_("Primary display:")) {
            halign = Gtk.Align.END
        };

        monitor_label = new Gtk.Label (_("Display:")) {
            halign = Gtk.Align.END
        };

        primary_monitor = new Gtk.Switch ();
        primary_monitor.notify["active"].connect (() => {
            if (primary_monitor.active == true) {
                dock_preferences.set_string ("monitor", "");
                monitor_label.sensitive = false;
                monitor_combo.sensitive = false;
            } else {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor.active)
                    dock_preferences.set_string ("monitor", plug_names[monitor.active]);
                monitor_label.sensitive = true;
                monitor_combo.sensitive = true;
            }
        });
        primary_monitor.active = (dock_preferences.get_string ("monitor") == "");

        monitor_combo.notify["active"].connect (() => {
            if (monitor_combo.active >= 0 && primary_monitor.active == false) {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor_combo.active)
                    dock_preferences.set_string ("monitor", plug_names[monitor_combo.active]);
            }
        });

        var icon_label = new Gtk.Label (_("Icon size:")) {
            halign = Gtk.Align.END
        };
        var hide_label = new Gtk.Label (_("Hide when:")) {
            halign = Gtk.Align.END
        };
        var primary_monitor_grid = new Gtk.Grid ();
        primary_monitor_grid.attach (primary_monitor, 0, 0);
        var pressure_label = new Gtk.Label (_("Pressure reveal:")) {
            halign = Gtk.Align.END
        };

        var panel_header = new Granite.HeaderLabel (_("Panel")) {
            margin_top = 12
        };

        var translucency_label = new Gtk.Label (_("Panel translucency:")) {
            halign = Gtk.Align.END
        };

        var translucency_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 24
        };
        grid.attach (dock_header, 0, 0, 3);
        grid.attach (icon_label, 0, 1);
        grid.attach (icon_size_grid, 1, 1, 2);
        grid.attach (hide_label, 0, 2);
        grid.attach (hide_mode, 1, 2);
        grid.attach (hide_switch, 2, 2);
        grid.attach (primary_monitor_label, 0, 3);
        grid.attach (primary_monitor_grid, 1, 3);
        grid.attach (monitor_label, 0, 4);
        grid.attach (monitor_combo, 1, 4);
        grid.attach (pressure_label, 0, 5);
        grid.attach (pressure_switch, 1, 5);
        grid.attach (panel_header, 0, 6, 3);
        grid.attach (translucency_label, 0, 7);
        grid.attach (translucency_switch, 1, 7);

        var clamp = new Adw.Clamp () {
            child = grid
        };

        clamp.set_parent (this);

        var display = get_display ();
        var monitors_list = display.get_monitors ();
        monitors_list.items_changed.connect (() => {
            check_for_screens (monitors_list);
        );

        check_for_screens (monitors_list);

        switch (dock_preferences.get_int ("icon-size")) {
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
            dock_preferences.set_int ("icon-size", 32);
        });

        icon_size_48.toggled.connect (() => {
            dock_preferences.set_int ("icon-size", 48);
        });

        icon_size_64.toggled.connect (() => {
            dock_preferences.set_int ("icon-size", 64);
        });

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);
    }

    private void check_for_screens (ListModel monitors) {
        int index = 0;
        int primary_screen = 0;
        monitor_combo.remove_all ();

        // TODO: get primary display

        for (index = 0; index < monitors.get_n_items (); index++) {
            var monitor = (Gdk.Monitor) monitors.get_item (index);
            if (monitor.connector != null || monitor.connector != "") {
                monitor_combo.append_text (monitor.connector);
            } else {
                monitor_combo.append_text ("Display %d", index + 1);
            }
        }

        if (index <= 1) {
            primary_monitor_label.hide ();
            primary_monitor.hide ();
            monitor_label.hide ();
            monitor_combo.hide ();
        } else {
            if (dock_preferences.get_string ("monitor") != "") {
                monitor_combo.active = find_monitor_number (get_display (), dock_preferences.get_string ("monitor"));
            } else {
                monitor_combo.active = primary_screen;
            }

            primary_monitor_label.show ();
            primary_monitor.show ();
            monitor_label.show ();
            monitor_combo.show ();
        }
    }

    static string[] get_monitor_plug_names (Gdk.Display display) {
        var monitors = display.get_monitors ();
        var n_monitors = monitors.get_n_items ();
        var result = new string[n_monitors];

        for (int i = 0; i < n_monitors; i++) {
            result[i] = ((Gdk.Monitor) monitors.get_item (i)).model;
        }

        return result;
    }

    static int find_monitor_number (Gdk.Display display, string plug_name) {
        var monitors = display.get_monitors ();

        for (int i = 0; i < monitors.get_n_items (); i++) {
            var monitor = (Gdk.Monitor) monitors.get_item (i);
            var name = monitor.get_model ();
            if (plug_name == name)
                return i;
        }

        return (int) monitors.get_n_items ();
    }

    ~Dock () {
        this.get_last_child ().unparent ();
    }
}
