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

public class PantheonShell.Appearance : Gtk.Grid {
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string STYLESHEET_KEY = "gtk-theme";
    private const string STYLESHEET_PREFIX = "io.elementary.stylesheet.";
    private const string TEXT_SIZE_KEY = "text-scaling-factor";

    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private const string ANIMATIONS_SCHEMA = "org.pantheon.desktop.gala.animations";
    private const string ANIMATIONS_KEY = "enable-animations";

    private const string DYSLEXIA_KEY = "dyslexia-friendly-support";
    private const string FONT_KEY = "font-name";
    private const string DOCUMENT_FONT_KEY = "document-font-name";
    private const string MONOSPACE_FONT_KEY = "monospace-font-name";

    private const string OD_REG_FONT = "OpenDyslexic Regular 9";
    private const string OD_DOC_FONT = "OpenDyslexic Regular 10";
    private const string OD_MON_FONT = "OpenDyslexicMono Regular 10";

    private const double[] TEXT_SCALE = {0.75, 1, 1.25, 1.5};

    private Granite.Widgets.ModeButton text_size_modebutton;

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var dark_label = new Gtk.Label (_("Style:")) {
            halign = Gtk.Align.END
        };

        var prefer_default_image = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/appearance-default.svg");

        var prefer_default_card = new Gtk.Grid () {
            margin = 6,
            margin_start = 12
        };
        prefer_default_card.add (prefer_default_image);

        unowned Gtk.StyleContext prefer_default_card_context = prefer_default_card.get_style_context ();
        prefer_default_card_context.add_class (Granite.STYLE_CLASS_CARD);
        prefer_default_card_context.add_class (Granite.STYLE_CLASS_ROUNDED);

        var prefer_default_grid = new Gtk.Grid () {
            row_spacing = 6
        };
        prefer_default_grid.attach (prefer_default_card, 0, 0);
        prefer_default_grid.attach (new Gtk.Label (_("Default")), 0, 1);

        var prefer_default_radio = new Gtk.RadioButton (null) {
            halign = Gtk.Align.START
        };
        prefer_default_radio.get_style_context ().add_class ("image-button");
        prefer_default_radio.add (prefer_default_grid);

        var prefer_dark_image = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/appearance-dark.svg");

        var prefer_dark_card = new Gtk.Grid () {
            margin = 6,
            margin_start = 12
        };
        prefer_dark_card.add (prefer_dark_image);

        unowned Gtk.StyleContext prefer_dark_card_context = prefer_dark_card.get_style_context ();
        prefer_dark_card_context.add_class (Granite.STYLE_CLASS_CARD);
        prefer_dark_card_context.add_class (Granite.STYLE_CLASS_ROUNDED);

        var prefer_dark_grid = new Gtk.Grid () {
            row_spacing = 6
        };
        prefer_dark_grid.attach (prefer_dark_card, 0, 0);
        prefer_dark_grid.attach (new Gtk.Label (_("Dark")), 0, 1);

        var prefer_dark_radio = new Gtk.RadioButton.from_widget (prefer_default_radio) {
            halign = Gtk.Align.START,
            hexpand = true
        };
        prefer_dark_radio.get_style_context ().add_class ("image-button");
        prefer_dark_radio.add (prefer_dark_grid);

        var dark_info = new Gtk.Label (_("Visual style for system components like the Dock and Panel indicators.")) {
            max_width_chars = 60,
            margin_bottom = 18,
            wrap = true,
            xalign = 0
        };
        dark_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var schedule_label = new Gtk.Label (_("Schedule:")) {
            halign = Gtk.Align.END,
            xalign = 1
        };

        var schedule_mode_button = new Granite.Widgets.ModeButton ();
        schedule_mode_button.append_text (_("Disabled"));
        schedule_mode_button.append_text (_("Sunset to Sunrise"));
        schedule_mode_button.append_text (_("Manual"));

        var from_label = new Gtk.Label (_("From:"));

        var from_time = new Granite.Widgets.TimePicker () {
            hexpand = true
        };

        var to_label = new Gtk.Label (_("To:"));

        var to_time = new Granite.Widgets.TimePicker () {
            hexpand = true
        };

        var schedule_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_bottom = 24
        };

        schedule_grid.add (from_label);
        schedule_grid.add (from_time);
        schedule_grid.add (to_label);
        schedule_grid.add (to_time);

        var animations_label = new Gtk.Label (_("Window animations:")) {
            halign = Gtk.Align.END,
            margin_top = 12
        };

        var animations_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            margin_top = 12
        };

        var translucency_label = new Gtk.Label (_("Panel translucency:")) {
            halign = Gtk.Align.END
        };

        var translucency_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        var text_size_label = new Gtk.Label (_("Text size:")) {
            halign = Gtk.Align.END,
            margin_top = 24
        };

        text_size_modebutton = new Granite.Widgets.ModeButton () {
            margin_top = 24
        };
        text_size_modebutton.append_text (_("Small"));
        text_size_modebutton.append_text (_("Default"));
        text_size_modebutton.append_text (_("Large"));
        text_size_modebutton.append_text (_("Larger"));

        var dyslexia_font_label = new Gtk.Label (_("Dyslexia-friendly text:")) {
            halign = Gtk.Align.END
        };

        var dyslexia_font_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        var dyslexia_font_description_label = new Gtk.Label (
            _("Bottom-heavy shapes and increased character spacing can help improve legibility and reading speed.")
        ) {
            max_width_chars = 60,
            wrap = true,
            xalign = 0
        };
        dyslexia_font_description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        /* Rows 0 to 3 are for the dark style UI that gets attached only if we
         * can connect to the DBus API
         *
         * Row 4 and 5 are for accent color UI that gets constructed only if the
         * current stylesheet is supported (begins with the STYLESHEET_PREFIX)
         */
        attach (animations_label, 0, 6);
        attach (animations_switch, 1, 6);
        attach (translucency_label, 0, 7);
        attach (translucency_switch, 1, 7);
        attach (text_size_label, 0, 8);
        attach (text_size_modebutton, 1, 8, 2);
        attach (dyslexia_font_label, 0, 9);
        attach (dyslexia_font_switch, 1, 9);
        attach (dyslexia_font_description_label, 1, 10, 2);

        var animations_settings = new GLib.Settings (ANIMATIONS_SCHEMA);
        animations_settings.bind (ANIMATIONS_KEY, animations_switch, "active", SettingsBindFlags.DEFAULT);

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);

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
            attach (schedule_label, 0, 2, 1, 1);
            attach (schedule_mode_button, 1, 2, 2, 1);
            attach (schedule_grid, 1, 3, 2, 1);

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
            
            /* Connect to button_release_event so that this is only triggered
             * through user interaction, not if scheduling changes the selection
             */
            prefer_default_radio.button_release_event.connect (() => {
                schedule_mode_button.selected = 0;
                return Gdk.EVENT_PROPAGATE;
            });

            prefer_dark_radio.button_release_event.connect (() => {
                schedule_mode_button.selected = 0;
                return Gdk.EVENT_PROPAGATE;
            });

            ((GLib.DBusProxy) pantheon_act).g_properties_changed.connect ((changed, invalid) => {
                var color_scheme = changed.lookup_value ("PrefersColorScheme", new VariantType ("i"));
                switch ((Granite.Settings.ColorScheme) color_scheme.get_int32 ()) {
                    case Granite.Settings.ColorScheme.DARK:
                        prefer_dark_radio.active = true;
                        break;
                    default:
                        prefer_default_radio.active = true;
                        break;
                }
            });

            var settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

            from_time.time = double_date_time (settings.get_double ("prefer-dark-schedule-from"));
            from_time.time_changed.connect (() => {
                settings.set_double ("prefer-dark-schedule-from", date_time_double (from_time.time));
            });
            to_time.time = double_date_time (settings.get_double ("prefer-dark-schedule-to"));
            to_time.time_changed.connect (() => {
                settings.set_double ("prefer-dark-schedule-to", date_time_double (to_time.time));
            });

            var schedule = settings.get_string ("prefer-dark-schedule");
            from_label.sensitive = schedule == "manual";
            from_time.sensitive = schedule == "manual";
            to_label.sensitive = schedule == "manual";
            to_time.sensitive = schedule == "manual";

            if (schedule == "sunset-to-sunrise") {
                schedule_mode_button.selected = 1;
            } else if (schedule == "manual") {
                schedule_mode_button.selected = 2;
            } else {
                schedule_mode_button.selected = 0;
            }

            schedule_mode_button.mode_changed.connect (() => {
                if (schedule_mode_button.selected == 1) {
                    settings.set_string ("prefer-dark-schedule", "sunset-to-sunrise");
                    from_label.sensitive = false;
                    from_time.sensitive = false;
                    to_label.sensitive = false;
                    to_time.sensitive = false;
                } else if (schedule_mode_button.selected == 2) {
                    settings.set_string ("prefer-dark-schedule", "manual");
                    from_label.sensitive = true;
                    from_time.sensitive = true;
                    to_label.sensitive = true;
                    to_time.sensitive = true;
                } else {
                    settings.set_string ("prefer-dark-schedule", "disabled");
                    from_label.sensitive = false;
                    from_time.sensitive = false;
                    to_label.sensitive = false;
                    to_time.sensitive = false;
                }
            });
        }

        var interface_settings = new GLib.Settings (INTERFACE_SCHEMA);
        var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);

        debug ("Current stylesheet: %s", current_stylesheet);

        if (current_stylesheet.has_prefix (STYLESHEET_PREFIX)) {
            /// TRANSLATORS: as in "Accent color"
            var accent_label = new Gtk.Label (_("Accent:"));
            accent_label.halign = Gtk.Align.END;

            var blueberry_button = new ColorButton ("blueberry");
            blueberry_button.tooltip_text = _("Blueberry");

            var strawberry_button = new ColorButton ("strawberry", blueberry_button);
            strawberry_button.tooltip_text = _("Strawberry");

            var orange_button = new ColorButton ("orange", blueberry_button);
            orange_button.tooltip_text = _("Orange");

            var banana_button = new ColorButton ("banana", blueberry_button);
            banana_button.tooltip_text = _("Banana");

            var lime_button = new ColorButton ("lime", blueberry_button);
            lime_button.tooltip_text = _("Lime");

            var mint_button = new ColorButton ("mint", blueberry_button);
            mint_button.tooltip_text = _("Mint");

            var grape_button = new ColorButton ("grape", blueberry_button);
            grape_button.tooltip_text = _("Grape");

            var bubblegum_button = new ColorButton ("bubblegum", blueberry_button);
            bubblegum_button.tooltip_text = _("Bubblegum");

            var cocoa_button = new ColorButton ("cocoa", blueberry_button);
            cocoa_button.tooltip_text = _("Cocoa");

            var slate_button = new ColorButton ("slate", blueberry_button);
            slate_button.tooltip_text = _("Slate");

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
            accent_grid.add (cocoa_button);
            accent_grid.add (slate_button);

            var accent_info = new Gtk.Label (_("Used across the system by default. Apps can always use their own accent color."));
            accent_info.margin_bottom = 18;
            accent_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            attach (accent_label, 0, 4);
            attach (accent_grid, 1, 4, 2);
            attach (accent_info, 1, 5, 2);
        }

        update_text_size_modebutton (interface_settings);

        interface_settings.changed.connect (() => {
            update_text_size_modebutton (interface_settings);
        });

        text_size_modebutton.mode_changed.connect (() => {
            set_text_scale (interface_settings, text_size_modebutton.selected);
        });

        dyslexia_font_switch.set_active (update_dyslexia_font_switch (interface_settings));

        dyslexia_font_switch.state_set.connect (() => {
            toggle_dyslexia_support (interface_settings, dyslexia_font_switch.get_active () );
        });
    }

    private class ColorButton : Gtk.RadioButton {
        public string color_name { get; construct; }

        private static GLib.Settings interface_settings;
        private static string current_accent;

        public ColorButton (string _color_name, Gtk.RadioButton? group_member = null) {
            Object (
                color_name: _color_name,
                group: group_member
            );
        }

        static construct {
            interface_settings = new GLib.Settings (INTERFACE_SCHEMA);

            var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);
            current_accent = current_stylesheet.replace (STYLESHEET_PREFIX, "");
        }

        construct {
            unowned Gtk.StyleContext context = get_style_context ();
            context.add_class ("color-button");
            context.add_class (color_name);

            realize.connect (() => {
                active = current_accent == color_name;

                toggled.connect (() => {
                    interface_settings.set_string (
                        STYLESHEET_KEY,
                        STYLESHEET_PREFIX + color_name
                    );
                });
            });
        }
    }

    private void toggle_dyslexia_support (GLib.Settings interface_settings, bool state) {
        if (state == true) {
            interface_settings.set_string (FONT_KEY, OD_REG_FONT);
            interface_settings.set_string (DOCUMENT_FONT_KEY, OD_DOC_FONT);
            interface_settings.set_string (MONOSPACE_FONT_KEY, OD_MON_FONT);
        }
        else {
            interface_settings.reset (FONT_KEY);
            interface_settings.reset (DOCUMENT_FONT_KEY);
            interface_settings.reset (MONOSPACE_FONT_KEY);
        }
    }

    private bool update_dyslexia_font_switch (GLib.Settings interface_settings) {
        var interface_font = interface_settings.get_string (FONT_KEY);
        var document_font = interface_settings.get_string (DOCUMENT_FONT_KEY);
        var monospace_font = interface_settings.get_string (MONOSPACE_FONT_KEY);

        if (interface_font == OD_REG_FONT || document_font == OD_DOC_FONT || monospace_font == OD_MON_FONT ) {
            return true;
        }

        else {
            return false;
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

    private static DateTime double_date_time (double dbl) {
        var hours = (int) dbl;
        var minutes = (int) Math.round ((dbl - hours) * 60);

        var date_time = new DateTime.local (1, 1, 1, hours, minutes, 0.0);

        return date_time;
    }

    private static double date_time_double (DateTime date_time) {
        double time_double = 0;
        time_double += date_time.get_hour ();
        time_double += (double) date_time.get_minute () / 60;

        return time_double;
    }
}
