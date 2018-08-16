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
    private const string CSS = """
        .variant:dir(rtl) image {
            -gtk-icon-transform: scaleX(-1);
        }

        .blueberry:checked {
            border-color: @BLUEBERRY_500;
        }

        .slate:checked {
            border-color: @SLATE_500;
        }
    """;
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string STYLESHEET_KEY = "gtk-theme";

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var accent_grid = new Gtk.Grid ();
        accent_grid.column_spacing = 6;

        var blueberry_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/accent-example-default.svg");

        var blueberry_button = new Gtk.ToggleButton ();
        blueberry_button.image = blueberry_icon;
        blueberry_button.tooltip_text = _("Blueberry");
        blueberry_button.get_style_context ().add_class ("variant");
        blueberry_button.get_style_context ().add_class ("flat");
        blueberry_button.get_style_context ().add_class ("blueberry");

        var slate_icon = new Gtk.Image.from_resource ("/io/elementary/switchboard/plug/pantheon-shell/accent-example-slate.svg");

        var slate_button = new Gtk.ToggleButton ();
        slate_button.image = slate_icon;
        slate_button.tooltip_text = _("Slate");
        slate_button.get_style_context ().add_class ("variant");
        slate_button.get_style_context ().add_class ("flat");
        slate_button.get_style_context ().add_class ("slate");

        accent_grid.attach (blueberry_button, 0, 0);
        accent_grid.attach (slate_button,     1, 0);

        attach (accent_grid, 0, 0);

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (CSS, CSS.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }

        var schema_source = SettingsSchemaSource.get_default ();
        var interface_schema = schema_source.lookup (INTERFACE_SCHEMA, false);
        var interface_settings = new GLib.Settings (INTERFACE_SCHEMA);

        var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);

        if (current_stylesheet == "elementary") {
            blueberry_button.active = true;
        } else if (current_stylesheet == "elementary-slate") {
            slate_button.active = true;
        }

        blueberry_button.clicked.connect (() => {
            if (slate_button.active) {
                slate_button.active = false;

                interface_settings.set_string (STYLESHEET_KEY, "elementary");
            } else {
                blueberry_button.active = true;
            }
        });

        slate_button.clicked.connect (() => {
            if (blueberry_button.active) {
                blueberry_button.active = false;

                interface_settings.set_string (STYLESHEET_KEY, "elementary-slate");
            } else {
                slate_button.active = true;
            }
        });
    }
}

