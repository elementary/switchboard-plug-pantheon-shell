/*
* Copyright 2018-2020 elementary, Inc. (https://elementary.io)
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
    private const string STYLESHEET_KEY = "gtk-theme";
    private const string STYLESHEET_PREFIX = "io.elementary.stylesheet.";
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

        var dark_label = new Gtk.Label (_("Style:"));
        dark_label.halign = Gtk.Align.END;

        var prefer_default_image = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/appearance-default.svg");

        var prefer_default_card = new Gtk.Grid ();
        prefer_default_card.margin = 6;
        prefer_default_card.margin_start = 12;
        prefer_default_card.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        prefer_default_card.add (prefer_default_image);

        var prefer_default_grid = new Gtk.Grid ();
        prefer_default_grid.row_spacing = 6;
        prefer_default_grid.attach (prefer_default_card, 0, 0);
        prefer_default_grid.attach (new Gtk.Label (_("Default")), 0, 1);

        var prefer_default_radio = new Gtk.RadioButton (null);
        prefer_default_radio.halign = Gtk.Align.START;
        prefer_default_radio.get_style_context ().add_class ("image-button");
        prefer_default_radio.add (prefer_default_grid);

        var prefer_dark_image = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/appearance-dark.svg");

        var prefer_dark_card = new Gtk.Grid ();
        prefer_dark_card.margin = 6;
        prefer_dark_card.margin_start = 12;
        prefer_dark_card.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        prefer_dark_card.add (prefer_dark_image);

        var prefer_dark_grid = new Gtk.Grid ();
        prefer_dark_grid.row_spacing = 6;
        prefer_dark_grid.attach (prefer_dark_card, 0, 0);
        prefer_dark_grid.attach (new Gtk.Label (_("Dark")), 0, 1);

        var prefer_dark_radio = new Gtk.RadioButton.from_widget (prefer_default_radio);
        prefer_dark_radio.halign = Gtk.Align.START;
        prefer_dark_radio.hexpand = true;
        prefer_dark_radio.get_style_context ().add_class ("image-button");
        prefer_dark_radio.add (prefer_dark_grid);

        var dark_info = new Gtk.Label (_("Visual style for system components like the Dock and Panel indicators."));
        dark_info.max_width_chars = 60;
        dark_info.margin_bottom = 18;
        dark_info.wrap = true;
        dark_info.xalign = 0;
        dark_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        /// TRANSLATORS: as in "Accent color"
        var accent_label = new Gtk.Label (_("Accent:"));
        accent_label.halign = Gtk.Align.END;

        var interface_settings = new GLib.Settings (INTERFACE_SCHEMA);

        // TODO: Maybe foreach over an array of arrays of color names and human names?
        var blueberry_button = new ColorButton (
            "blueberry",
            _("Blueberry"),
            interface_settings
        );
        var strawberry_button = new ColorButton (
            "strawberry",
            _("Strawberry"),
            interface_settings,
            blueberry_button
        );
        var orange_button = new ColorButton (
            "orange",
            _("Orange"),
            interface_settings,
            blueberry_button
        );
        var banana_button = new ColorButton (
            "banana",
            _("Banana"),
            interface_settings,
            blueberry_button
        );
        var lime_button = new ColorButton (
            "lime",
            _("Lime"),
            interface_settings,
            blueberry_button
        );
        var mint_button = new ColorButton (
            "mint",
            _("Mint"),
            interface_settings,
            blueberry_button
        );
        var grape_button = new ColorButton (
            "grape",
            _("Grape"),
            interface_settings,
            blueberry_button
        );
        var bubblegum_button = new ColorButton (
            "bubblegum",
            _("Bubblegum"),
            interface_settings,
            blueberry_button
        );

        var accent_grid = new Gtk.Grid ();
        accent_grid.column_spacing = 6;
        accent_grid.add (blueberry_button);
        accent_grid.add (strawberry_button);
        accent_grid.add (orange_button);
        accent_grid.add (banana_button);
        accent_grid.add (lime_button);
        accent_grid.add (mint_button);
        accent_grid.add (grape_button);
        accent_grid.add (bubblegum_button);

        var accent_info = new Gtk.Label (_("Used across the system by default. Apps can always use their own accent color."));
        accent_info.margin_bottom = 18;
        accent_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

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

        // Row 0 and 1 are for the dark style UI that gets attached only if we
        // can connect to the DBus API
        attach (accent_label, 0, 2);
        attach (accent_grid, 1, 2, 2);
        attach (accent_info, 1, 3, 2);
        attach (animations_label, 0, 4);
        attach (animations_switch, 1, 4);
        attach (translucency_label, 0, 5);
        attach (translucency_switch, 1, 5);
        attach (text_size_label, 0, 6);
        attach (text_size_modebutton, 1, 6, 2);

        var animations_settings = new GLib.Settings (ANIMATIONS_SCHEMA);
        animations_settings.bind (ANIMATIONS_KEY, animations_switch, "active", SettingsBindFlags.DEFAULT);

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);

        update_text_size_modebutton (interface_settings);

        Pantheon.AccountsService? pantheon_act = null;

        string? user_path = null;
        try {
            FDO.Accounts? accounts_service = GLib.Bus.get_proxy_sync (
                GLib.BusType.SYSTEM,
               "org.freedesktop.Accounts",
               "/org/freedesktop/Accounts"
            );

            user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());
        } catch (Error e) {
            critical (e.message);
        }

        if (user_path != null) {
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
        }

        if (((GLib.DBusProxy) pantheon_act).get_cached_property ("PrefersColorScheme") != null) {
            attach (dark_label, 0, 0);
            attach (prefer_default_radio, 1, 0);
            attach (prefer_dark_radio, 2, 0);
            attach (dark_info, 1, 1, 2);

            switch (pantheon_act.prefers_color_scheme) {
                case Granite.Settings.ColorScheme.DARK:
                    prefer_dark_radio.active = true;
                    break;
                default:
                    prefer_default_radio.active = true;
                    break;
            }

            prefer_default_radio.toggled.connect (() => {
                pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.NO_PREFERENCE;
            });

            prefer_dark_radio.toggled.connect (() => {
                pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.DARK;
            });
        }

        interface_settings.changed.connect (() => {
            update_text_size_modebutton (interface_settings);
        });

        text_size_modebutton.mode_changed.connect (() => {
            set_text_scale (interface_settings, text_size_modebutton.selected);
        });
    }

    private class ColorButton : Gtk.RadioButton {
        public string color_name { get; construct; }
        public string human_name { get; construct; }
        public GLib.Settings interface_settings { get; construct; }
        public Gtk.RadioButton? radio_group_member { get; construct; }

        public ColorButton (
            string _color_name,
            string _human_name,
            GLib.Settings _interface_settings,
            Gtk.RadioButton? _radio_group_member = null
        ) {
            Object (
                color_name: _color_name,
                human_name: _human_name,
                interface_settings: _interface_settings,
                radio_group_member: _radio_group_member
            );
        }

        construct {
            tooltip_text = _(human_name);
            width_request = height_request = 24;

            var context = get_style_context ();
            context.add_class ("color-button");
            context.add_class (color_name);

            if (radio_group_member != null) {
                set_group (radio_group_member.get_group ());
            }

            realize.connect (() => {
                var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);
                var current_accent = current_stylesheet.replace (STYLESHEET_PREFIX, "");
                if (current_accent == color_name) {
                    this.active = true;
                }
            });

            clicked.connect (() => {
                interface_settings.set_string (
                    STYLESHEET_KEY,
                    STYLESHEET_PREFIX + color_name
                );
            });
        }
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
