/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2016-2023 elementary, Inc. (https://elementary.io)
 */

public class PantheonShell.Dock : Switchboard.SettingsPage {
    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    public Dock () {
        Object (
            title: _("Dock & Panel"),
            icon: new ThemedIcon ("preferences-desktop"),
            show_end_title_buttons: true
        );
    }

    construct {
        var icon_header = new Granite.HeaderLabel (_("Dock Icon Size"));

        var image_32 = new Gtk.Image.from_icon_name ("dock-icon-symbolic") {
            pixel_size = 32
        };

        var icon_size_32 = new Gtk.CheckButton () {
            tooltip_text = _("Small")
        };
        image_32.set_parent (icon_size_32);

        var image_48 = new Gtk.Image.from_icon_name ("dock-icon-symbolic") {
            pixel_size = 48
        };

        var icon_size_48 = new Gtk.CheckButton () {
            group = icon_size_32,
            tooltip_text = _("Default")
        };
        image_48.set_parent (icon_size_48);

        var image_64 = new Gtk.Image.from_icon_name ("dock-icon-symbolic") {
            pixel_size = 64
        };

        var icon_size_64 = new Gtk.CheckButton () {
            group = icon_size_32,
            tooltip_text = _("Large")
        };
        image_64.set_parent (icon_size_64);

        var icon_size_unsupported = new Gtk.CheckButton () {
            group = icon_size_32
        };

        var icon_size_box = new Gtk.Box (HORIZONTAL, 24);
        icon_size_box.append (icon_size_32);
        icon_size_box.append (icon_size_48);
        icon_size_box.append (icon_size_64);

        var icon_box = new Gtk.Box (VERTICAL, 0);
        icon_box.append (icon_header);
        icon_box.append (icon_size_box);

        var hide_header = new Granite.HeaderLabel (_("Hide Dock"));

        var never_radio = new Gtk.CheckButton.with_label (_("Never"));

        var dodge_maximized_radio = new Gtk.CheckButton.with_label (
            _("When the focused window is maximized")
        ) {
            group = never_radio
        };

        var dodge_focused_radio = new Gtk.CheckButton.with_label (
            _("When the focused window overlaps the dock")
        ) {
            group = never_radio
        };

        var dodge_all_radio = new Gtk.CheckButton.with_label (
            _("When any window overlaps the dock")
        ) {
            group = never_radio
        };

        var always_radio = new Gtk.CheckButton.with_label (
            _("When not being used")
        ) {
            group = never_radio
        };

        var hide_box = new Gtk.Box (VERTICAL, 6);
        hide_box.append (hide_header);
        hide_box.append (never_radio);
        hide_box.append (dodge_maximized_radio);
        hide_box.append (dodge_focused_radio);
        hide_box.append (dodge_all_radio);
        hide_box.append (always_radio);

        var translucency_switch = new Gtk.Switch () {
            halign = END,
            hexpand = true,
            valign = CENTER
        };

        var translucency_header = new Granite.HeaderLabel (_("Panel Translucency")) {
            mnemonic_widget = translucency_switch,
            secondary_text = _("Automatically transparent or opaque based on the wallpaper")
        };

        var translucency_box = new Gtk.Box (HORIZONTAL, 12);
        translucency_box.append (translucency_header);
        translucency_box.append (translucency_switch);

        var indicators_header = new Granite.HeaderLabel (_("Show in Panel"));

        var indicators_box = new Gtk.Box (VERTICAL, 6);
        indicators_box.append (indicators_header);

        var quicksettings_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.quick-settings", true);
        if (quicksettings_schema != null && quicksettings_schema.has_key ("show-a11y")) {
            var a11y_check = new Gtk.CheckButton.with_label (_("Accessibility"));

            indicators_box.append (a11y_check);

            var a11y_settings = new Settings ("io.elementary.desktop.quick-settings");
            a11y_settings.bind ("show-a11y", a11y_check, "active", DEFAULT);
        }

        var keyboard_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.wingpanel.keyboard", true);
        if (keyboard_schema != null && keyboard_schema.has_key ("capslock")) {
            var caps_check = new Gtk.CheckButton.with_label (_("Caps Lock ⇪"));
            var num_check = new Gtk.CheckButton.with_label (_("Num Lock"));

            indicators_box.append (caps_check);
            indicators_box.append (num_check);

            var keyboard_settings = new Settings ("io.elementary.wingpanel.keyboard");
            keyboard_settings.bind ("capslock", caps_check, "active", DEFAULT);
            keyboard_settings.bind ("numlock", num_check, "active", DEFAULT);
        }

        var box = new Gtk.Box (VERTICAL, 18) {
        };
        box.append (icon_box);
        box.append (hide_box);
        box.append (translucency_box);

        // Only add this box if it has more than the header in it
        if (indicators_header.get_next_sibling () != null) {
            box.append (indicators_box);
        }

        child = box;

        var dock_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.dock", true);
        if (dock_schema != null) {
            var dock_settings = new Settings ("io.elementary.dock");

            if (dock_schema.has_key ("icon-size")) {
                dock_settings.bind_with_mapping (
                    "icon-size", icon_size_32, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_int32 () == 32);
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.int32 (32);
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "icon-size", icon_size_48, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_int32 () == 48);
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.int32 (48);
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "icon-size", icon_size_64, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_int32 () == 64);
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.int32 (64);
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "icon-size", icon_size_unsupported, "active", DEFAULT,
                    (value, variant, user_data) => {
                        var icon_size = variant.get_int32 ();
                        value.set_boolean (
                            icon_size != 32 &&
                            icon_size != 48 &&
                            icon_size != 64
                        );
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        return new Variant.maybe (null, null);
                    },
                    null, null
                );
            } else {
                box.remove (icon_box);
            }

            if (dock_schema.has_key ("autohide-mode")) {
                dock_settings.bind_with_mapping (
                    "autohide-mode", never_radio, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_string () == "never");
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.string ("never");
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "autohide-mode", dodge_maximized_radio, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_string () == "maximized-focus-window");
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.string ("maximized-focus-window");
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "autohide-mode", dodge_focused_radio, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_string () == "overlapping-focus-window");
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.string ("overlapping-focus-window");
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "autohide-mode", dodge_all_radio, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_string () == "overlapping-window");
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.string ("overlapping-window");
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );

                dock_settings.bind_with_mapping (
                    "autohide-mode", always_radio, "active", DEFAULT,
                    (value, variant, user_data) => {
                        value.set_boolean (variant.get_string () == "always");
                        return true;
                    },
                    (value, expected_type, user_data) => {
                        if (value.get_boolean ()) {
                            return new Variant.string ("always");
                        }

                        return new Variant.maybe (null, null);
                    },
                    null, null
                );
            } else {
                box.remove (hide_box);
            }
        }

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);
    }
}
