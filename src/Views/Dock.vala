/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2016-2023 elementary, Inc. (https://elementary.io)
 */

public class PantheonShell.Dock : Gtk.Box {
    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";


    construct {
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

        var box = new Gtk.Box (VERTICAL, 18) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        box.add (translucency_grid);

        // Only add this box if it has more than the header in it
        if (indicators_box.get_children ().length () > 1) {
            box.add (indicators_box);
        }

        var clamp = new Hdy.Clamp () {
            child = box
        };

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = clamp
        };

        add (scrolled);

        var panel_settings = new GLib.Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);
    }
}
