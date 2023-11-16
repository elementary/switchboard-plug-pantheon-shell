/*
* Copyright 2018–2021 elementary, Inc. (https://elementary.io)
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

public class PantheonShell.Appearance : Gtk.Box {
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string STYLESHEET_KEY = "gtk-theme";
    private const string STYLESHEET_PREFIX = "io.elementary.stylesheet.";

    private enum AccentColor {
        NO_PREFERENCE,
        RED,
        ORANGE,
        YELLOW,
        GREEN,
        MINT,
        BLUE,
        PURPLE,
        PINK,
        BROWN,
        GRAY;

        public string to_string () {
            switch (this) {
                case RED:
                    return "strawberry";
                case ORANGE:
                    return "orange";
                case YELLOW:
                    return "banana";
                case GREEN:
                    return "lime";
                case MINT:
                    return "mint";
                case BLUE:
                    return "blueberry";
                case PURPLE:
                    return "grape";
                case PINK:
                    return "bubblegum";
                case BROWN:
                    return "cocoa";
                case GRAY:
                    return "slate";
            }

            return "auto";
        }
    }

    construct {
        var dark_label = new Granite.HeaderLabel (_("Style"));

        var prefer_default_image = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/appearance-default.svg");

        var prefer_default_card = new Gtk.Box (HORIZONTAL, 0) {
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 12
        };
        prefer_default_card.append (prefer_default_image);
        prefer_default_card.add_css_class (Granite.STYLE_CLASS_CARD);
        prefer_default_card.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var prefer_default_grid = new Gtk.Grid () {
            row_spacing = 6
        };
        prefer_default_grid.attach (prefer_default_card, 0, 0);
        prefer_default_grid.attach (new Gtk.Label (_("Default")), 0, 1);

        var prefer_default_radio = new Gtk.CheckButton () {
            halign = Gtk.Align.START
        };
        prefer_default_radio.add_css_class ("image-button");
        prefer_default_grid.set_parent (prefer_default_radio);

        var prefer_dark_image = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/appearance-dark.svg");

        var prefer_dark_card = new Gtk.Box (HORIZONTAL, 6) {
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 12
        };
        prefer_dark_card.append (prefer_dark_image);
        prefer_dark_card.add_css_class (Granite.STYLE_CLASS_CARD);
        prefer_dark_card.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var prefer_dark_grid = new Gtk.Grid () {
            row_spacing = 6
        };
        prefer_dark_grid.attach (prefer_dark_card, 0, 0);
        prefer_dark_grid.attach (new Gtk.Label (_("Dark")), 0, 1);

        var prefer_dark_radio = new Gtk.CheckButton () {
            group = prefer_default_radio,
            halign = Gtk.Align.START,
            hexpand = true
        };
        prefer_dark_radio.add_css_class ("image-button");
        prefer_dark_grid.set_parent (prefer_dark_radio);

        var prefer_style_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        prefer_style_box.append (prefer_default_radio);
        prefer_style_box.append (prefer_dark_radio);

        var dark_info = new Gtk.Label (_("Preferred visual style for system components. Apps may also choose to follow this preference.")) {
            wrap = true,
            xalign = 0
        };
        dark_info.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var schedule_label = new Granite.HeaderLabel (_("Schedule"));

        var schedule_disabled_radio = new Gtk.CheckButton.with_label (_("Disabled")) {
            margin_bottom = 3
        };

        var schedule_sunset_radio = new Gtk.CheckButton.with_label (
            _("Sunset to Sunrise")
        ) {
            group = schedule_disabled_radio
        };

        var from_label = new Gtk.Label (_("From:"));

        var from_time = new Granite.TimePicker () {
            hexpand = true,
            margin_end = 6
        };

        var to_label = new Gtk.Label (_("To:"));

        var to_time = new Granite.TimePicker () {
            hexpand = true
        };

        var schedule_manual_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        schedule_manual_box.append (from_label);
        schedule_manual_box.append (from_time);
        schedule_manual_box.append (to_label);
        schedule_manual_box.append (to_time);

        var schedule_manual_radio = new Gtk.CheckButton () {
            group = schedule_disabled_radio
        };

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

        var grid = new Gtk.Grid () {
            column_spacing = 7, // Off by one with Gtk.CheckButton
            row_spacing = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 24
        };

        if (((GLib.DBusProxy) pantheon_act).get_cached_property ("PrefersColorScheme") != null) {
            grid.attach (dark_label, 0, 0, 2);
            grid.attach (dark_info, 0, 1, 2);
            grid.attach (prefer_style_box, 0, 2, 2);
            grid.attach (schedule_label, 0, 3, 2);
            grid.attach (schedule_disabled_radio, 0, 4, 2);
            grid.attach (schedule_sunset_radio, 0, 5, 2);
            grid.attach (schedule_manual_radio, 0, 6);
            grid.attach (schedule_manual_box, 1, 6);

            switch (pantheon_act.prefers_color_scheme) {
                case Granite.Settings.ColorScheme.DARK:
                    prefer_dark_radio.active = true;
                    break;
                default:
                    prefer_default_radio.active = true;
                    break;
            }

            var settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

            settings.bind_with_mapping (
                "prefer-dark-schedule", schedule_disabled_radio, "active", GLib.SettingsBindFlags.DEFAULT,
                (value, variant, user_data) => {
                    value.set_boolean (variant.get_string () == "disabled");
                    return true;
                },
                (value, expected_type, user_data) => {
                    if (value.get_boolean ()) {
                        return new Variant ("s", "disabled");
                    }

                    return null;
                },
                null, null
            );

            settings.bind_with_mapping (
                "prefer-dark-schedule", schedule_manual_radio, "active", GLib.SettingsBindFlags.DEFAULT,
                (value, variant, user_data) => {
                    value.set_boolean (variant.get_string () == "manual");
                    return true;
                },
                (value, expected_type, user_data) => {
                    if (value.get_boolean ()) {
                        return new Variant ("s", "manual");
                    }

                    return null;
                },
                null, null
            );

            settings.bind_with_mapping (
                "prefer-dark-schedule", schedule_sunset_radio, "active", GLib.SettingsBindFlags.DEFAULT,
                (value, variant, user_data) => {
                    value.set_boolean (variant.get_string () == "sunset-to-sunrise");
                    return true;
                },
                (value, expected_type, user_data) => {
                    if (value.get_boolean ()) {
                        return new Variant ("s", "sunset-to-sunrise");
                    }

                    return null;
                },
                null, null
            );

            prefer_default_radio.toggled.connect (() => {
                pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.NO_PREFERENCE;
            });

            prefer_dark_radio.toggled.connect (() => {
                pantheon_act.prefers_color_scheme = Granite.Settings.ColorScheme.DARK;
            });

            /* Connect to focus_in_event so that this is only triggered
             * through user interaction, not if scheduling changes the selection
             */
            // prefer_default_radio.focus_in_event.connect (() => {
            //     // Check if selection changed
            //     if (pantheon_act.prefers_color_scheme != Granite.Settings.ColorScheme.NO_PREFERENCE) {
            //         schedule_disabled_radio.active = true;
            //     }
            //     return Gdk.EVENT_PROPAGATE;
            // });

            // prefer_dark_radio.focus_in_event.connect (() => {
            //     // Check if selection changed
            //     if (pantheon_act.prefers_color_scheme != Granite.Settings.ColorScheme.DARK) {
            //         schedule_disabled_radio.active = true;
            //     }
            //     return Gdk.EVENT_PROPAGATE;
            // });

            ((GLib.DBusProxy) pantheon_act).g_properties_changed.connect ((changed, invalid) => {
                var color_scheme = changed.lookup_value ("PrefersColorScheme", new VariantType ("i"));
                if (color_scheme != null) {
                    switch ((Granite.Settings.ColorScheme) color_scheme.get_int32 ()) {
                        case Granite.Settings.ColorScheme.DARK:
                            prefer_dark_radio.active = true;
                            break;
                        default:
                            prefer_default_radio.active = true;
                            break;
                    }
                }
            });

            from_time.time = double_date_time (settings.get_double ("prefer-dark-schedule-from"));
            from_time.time_changed.connect (() => {
                settings.set_double ("prefer-dark-schedule-from", date_time_double (from_time.time));
            });
            to_time.time = double_date_time (settings.get_double ("prefer-dark-schedule-to"));
            to_time.time_changed.connect (() => {
                settings.set_double ("prefer-dark-schedule-to", date_time_double (to_time.time));
            });

            schedule_manual_radio.bind_property ("active", schedule_manual_box, "sensitive", BindingFlags.SYNC_CREATE);
        }

        var interface_settings = new GLib.Settings (INTERFACE_SCHEMA);
        var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);

        debug ("Current stylesheet: %s", current_stylesheet);

        if (current_stylesheet.has_prefix (STYLESHEET_PREFIX)) {
            var accent_label = new Granite.HeaderLabel (_("Accent Color")) {
                margin_top = 18
            };

            var blueberry_button = new PrefersAccentColorButton (pantheon_act, AccentColor.BLUE);
            blueberry_button.tooltip_text = _("Blueberry");

            var mint_button = new PrefersAccentColorButton (pantheon_act, AccentColor.MINT, blueberry_button);
            mint_button.tooltip_text = _("Mint");

            var lime_button = new PrefersAccentColorButton (pantheon_act, AccentColor.GREEN, blueberry_button);
            lime_button.tooltip_text = _("Lime");

            var banana_button = new PrefersAccentColorButton (pantheon_act, AccentColor.YELLOW, blueberry_button);
            banana_button.tooltip_text = _("Banana");

            var orange_button = new PrefersAccentColorButton (pantheon_act, AccentColor.ORANGE, blueberry_button);
            orange_button.tooltip_text = _("Orange");

            var strawberry_button = new PrefersAccentColorButton (pantheon_act, AccentColor.RED, blueberry_button);
            strawberry_button.tooltip_text = _("Strawberry");

            var bubblegum_button = new PrefersAccentColorButton (pantheon_act, AccentColor.PINK, blueberry_button);
            bubblegum_button.tooltip_text = _("Bubblegum");

            var grape_button = new PrefersAccentColorButton (pantheon_act, AccentColor.PURPLE, blueberry_button);
            grape_button.tooltip_text = _("Grape");

            var cocoa_button = new PrefersAccentColorButton (pantheon_act, AccentColor.BROWN, blueberry_button);
            cocoa_button.tooltip_text = _("Cocoa");

            var slate_button = new PrefersAccentColorButton (pantheon_act, AccentColor.GRAY, blueberry_button);
            slate_button.tooltip_text = _("Slate");

            var auto_button = new PrefersAccentColorButton (pantheon_act, AccentColor.NO_PREFERENCE, blueberry_button);
            auto_button.tooltip_text = _("Automatic based on wallpaper");

            var accent_box = new Gtk.Box (HORIZONTAL, 6);
            accent_box.append (blueberry_button);
            accent_box.append (mint_button);
            accent_box.append (lime_button);
            accent_box.append (banana_button);
            accent_box.append (orange_button);
            accent_box.append (strawberry_button);
            accent_box.append (bubblegum_button);
            accent_box.append (grape_button);
            accent_box.append (cocoa_button);
            accent_box.append (slate_button);
            accent_box.append (auto_button);

            var accent_info = new Gtk.Label (_("Used across the system by default. Apps can always use their own accent color.")) {
                xalign = 0,
                wrap = true
            };
            accent_info.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            grid.attach (accent_label, 0, 7, 2);
            grid.attach (accent_info, 0, 8, 2);
            grid.attach (accent_box, 0, 9, 2);
        }

        var animations_label = new Granite.HeaderLabel (_("Reduce Motion")) {
            margin_top = 18
        };

        var animations_description = new Gtk.Label (_("Disable animations in the window manager and some other interface elements.")) {
            wrap = true,
            xalign = 0
        };
        animations_description.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var animations_switch = new Gtk.Switch () {
            halign = Gtk.Align.END,
            hexpand = true,
            valign = Gtk.Align.CENTER
        };

        var animations_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        animations_grid.attach (animations_label, 0, 0);
        animations_grid.attach (animations_description, 0, 1);
        animations_grid.attach (animations_switch, 1, 0, 1, 2);

        grid.attach (animations_grid, 0, 10, 2);

        var clamp = new Adw.Clamp () {
            child = grid
        };

        append (clamp);

        var animations_settings = new Settings ("org.pantheon.desktop.gala.animations");
        animations_settings.bind ("enable-animations", animations_switch, "active", SettingsBindFlags.INVERT_BOOLEAN);
    }

    private class PrefersAccentColorButton : Gtk.CheckButton {
        public AccentColor color { get; construct; }
        public Pantheon.AccountsService? pantheon_act { get; construct; default = null; }

        private static GLib.Settings interface_settings;

        public PrefersAccentColorButton (Pantheon.AccountsService? pantheon_act, AccentColor color, Gtk.CheckButton? group_member = null) {
            Object (
                pantheon_act: pantheon_act,
                color: color,
                group: group_member
            );
        }

        static construct {
            interface_settings = new GLib.Settings (INTERFACE_SCHEMA);

            var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);
        }

        construct {
            unowned Gtk.StyleContext context = get_style_context ();
            context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            context.add_class (color.to_string ());

            realize.connect (() => {
                active = color == pantheon_act.prefers_accent_color;

                toggled.connect (() => {
                    if (color != AccentColor.NO_PREFERENCE) {
                        interface_settings.set_string (
                            STYLESHEET_KEY,
                            STYLESHEET_PREFIX + color.to_string ()
                        );
                    }

                    if (((GLib.DBusProxy) pantheon_act).get_cached_property ("PrefersAccentColor") != null) {
                        pantheon_act.prefers_accent_color = color;
                    }
                });
            });
        }
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
