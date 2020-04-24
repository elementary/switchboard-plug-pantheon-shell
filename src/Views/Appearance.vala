/*
* Copyright (c) 2018 elementary, Inc. (https://elementary.io)
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

public class Appearance : Gtk.Grid {
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string TEXT_SIZE_KEY = "text-scaling-factor";

    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private const string ANIMATIONS_SCHEMA = "org.pantheon.desktop.gala.animations";
    private const string ANIMATIONS_KEY = "enable-animations";

    private const double[] TEXT_SCALE = {0.75, 1, 1.25, 1.5};

    private Granite.Widgets.ModeButton text_size_modebutton;

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var dark_label = new Gtk.Label (_("Prefer dark style:"));
        dark_label.halign = Gtk.Align.END;

        var dark_switch = new Gtk.Switch ();
        dark_switch.halign = Gtk.Align.START;

        var dark_info = new Gtk.Label (_("Use a dark visual style for system components like the Panel indicators."));
        dark_info.max_width_chars = 60;
        dark_info.margin_bottom = 18;
        dark_info.wrap = true;
        dark_info.xalign = 0;
        dark_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var animations_label = new Gtk.Label (_("Window animations:"));
        animations_label.halign = Gtk.Align.END;

        var animations_switch = new Gtk.Switch ();
        animations_switch.halign = Gtk.Align.START;

        var translucency_label = new Gtk.Label (_("Panel translucency:"));
        translucency_label.halign = Gtk.Align.END;

        var translucency_switch = new Gtk.Switch ();
        translucency_switch.halign = Gtk.Align.START;

        var text_size_label = new Gtk.Label (_("Text size:"));
        text_size_label.halign = Gtk.Align.END;

        text_size_modebutton = new Granite.Widgets.ModeButton ();
        text_size_modebutton.append_text (_("Small"));
        text_size_modebutton.append_text (_("Default"));
        text_size_modebutton.append_text (_("Large"));
        text_size_modebutton.append_text (_("Larger"));

        attach (dark_label, 0, 0);
        attach (dark_switch, 1, 0);
        attach (dark_info, 1, 1);
        attach (animations_label, 0, 2);
        attach (animations_switch, 1, 2);
        attach (translucency_label, 0, 3);
        attach (translucency_switch, 1, 3);
        attach (text_size_label, 0, 4);
        attach (text_size_modebutton, 1, 4);

        var animations_settings = new Settings (ANIMATIONS_SCHEMA);
        animations_settings.bind (ANIMATIONS_KEY, animations_switch, "active", SettingsBindFlags.DEFAULT);

        var panel_settings = new Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);

        var interface_settings = new Settings (INTERFACE_SCHEMA);

        update_text_size_modebutton (interface_settings);

        Pantheon.AccountsService? pantheon_act = null;
        FDO.Accounts? accounts_service = null;
        string? user_path = null;
        try {
            accounts_service = GLib.Bus.get_proxy_sync (
                GLib.BusType.SYSTEM,
               "org.freedesktop.Accounts",
               "/org/freedesktop/Accounts"
            );

            user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());
        } catch (Error e) {
            critical (e.message);
        }

        try {
            pantheon_act = GLib.Bus.get_proxy_sync (
                GLib.BusType.SYSTEM,
                "org.freedesktop.Accounts",
                user_path,
                GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
            );
        } catch (Error e) {
            warning ("Unable to get AccountsService proxy, color scheme preference may be incorrect");
        }

        critical (pantheon_act.prefers_color_scheme.to_string ());

        // FIXME: This seems… not ideal. Can't we bind this?
        switch (pantheon_act.prefers_color_scheme) {
            case Granite.Settings.ColorScheme.DARK:
                dark_switch.active = true;
                break;
            default:
                dark_switch.active = false;
                break;
        }

        // FIXME: and bind this
        dark_switch.notify["active"].connect (() => {
            if (dark_switch.active) {
                pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.DARK;
            } else {
                pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.NO_PREFERENCE;
            }
        });

        interface_settings.changed.connect (() => {
            update_text_size_modebutton (interface_settings);
        });

        text_size_modebutton.mode_changed.connect (() => {
            set_text_scale (interface_settings, text_size_modebutton.selected);
        });
    }

    private int get_text_scale (GLib.Settings interface_settings) {
        double text_scaling_factor = interface_settings.get_double (TEXT_SIZE_KEY);

        if (text_scaling_factor <= TEXT_SCALE[0]) {
            return 0;
        } else if (text_scaling_factor <= TEXT_SCALE[1]) {
            return 1;
        } else if (text_scaling_factor <= TEXT_SCALE[2]) {
            return 2;
        } else {
            return 3;
        }
    }

    private void set_text_scale (GLib.Settings interface_settings, int option) {
        interface_settings.set_double (TEXT_SIZE_KEY, TEXT_SCALE[option]);
    }

    private void update_text_size_modebutton (GLib.Settings interface_settings) {
        text_size_modebutton.set_active (get_text_scale (interface_settings));
    }
}
