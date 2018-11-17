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
    private const string DESKTOP_SCHEMA = "io.elementary.desktop";
    private const string DARK_KEY = "prefer-dark";

    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string TEXT_SIZE_KEY = "text-scaling-factor";

    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private const string ANIMATIONS_SCHEMA = "org.pantheon.desktop.gala.animations";
    private const string ANIMATIONS_KEY = "enable-animations";

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var dark_label = new Gtk.Label (_("Prefer dark style:"));
        dark_label.halign = Gtk.Align.END;

        var dark_switch = new Gtk.Switch ();
        dark_switch.halign = Gtk.Align.START;

        var dark_info = new Gtk.Label (_("Ask apps to use a dark visual style. Not all apps support this, and it is up to each app to implement. Does not affect notifications or non-native apps. If the app has a built-in style switcher it will likely ignore this setting."));
        dark_info.max_width_chars = 60;
        dark_info.margin_bottom = 18;
        dark_info.wrap = true;
        dark_info.xalign = 0;
        dark_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var test_button = new Gtk.ToggleButton.with_label (_("Test Speakers…"));

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
        text_size_label.valign = Gtk.Align.START;

        var text_size_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.75, 1.75, 0.05);
        text_size_scale.width_request = 128;
        text_size_scale.draw_value = false;

        text_size_scale.add_mark (1, Gtk.PositionType.BOTTOM, null);

        var small_icon = new Gtk.Image.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
        small_icon.valign = Gtk.Align.START;

        var large_icon = new Gtk.Image.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        large_icon.valign = Gtk.Align.START;

        var text_size_grid = new Gtk.Grid ();
        text_size_grid.column_spacing = 6;
        text_size_grid.add (small_icon);
        text_size_grid.add (text_size_scale);
        text_size_grid.add (large_icon);

        attach (dark_label, 0, 0);
        attach (dark_switch, 1, 0);
        attach (dark_info, 1, 1);
        attach (animations_label, 0, 2);
        attach (animations_switch, 1, 2);
        attach (translucency_label, 0, 3);
        attach (translucency_switch, 1, 3);
        attach (text_size_label, 0, 4);
        attach (text_size_grid, 1, 4);

        var gtk_settings = Gtk.Settings.get_default ();

        var desktop_settings = new Settings (DESKTOP_SCHEMA);
        desktop_settings.bind (DARK_KEY, dark_switch, "active", SettingsBindFlags.DEFAULT);
        dark_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");

        var animations_settings = new Settings (ANIMATIONS_SCHEMA);
        animations_settings.bind (ANIMATIONS_KEY, animations_switch, "active", SettingsBindFlags.DEFAULT);

        var panel_settings = new Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);

        var interface_settings = new Settings (INTERFACE_SCHEMA);
        interface_settings.bind (TEXT_SIZE_KEY, text_size_scale.adjustment, "value", SettingsBindFlags.DEFAULT);
    }
}

