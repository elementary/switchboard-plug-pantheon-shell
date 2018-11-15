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
    private const string STYLESHEET_KEY = "gtk-theme";

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

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

        // var text_size_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 2, 1);
        // text_size_scale.width_request = 128;
        // text_size_scale.draw_value = false;

        var text_size_mode = new Granite.Widgets.ModeButton ();
        text_size_mode.append_text (_("Normal"));
        text_size_mode.append_text (_("Large"));
        text_size_mode.append_text (_("Larger"));
        text_size_mode.get_style_context ().add_class ("text-size");

        attach (animations_label, 0, 0);
        attach (animations_switch, 1, 0);
        attach (translucency_label, 0, 1);
        attach (translucency_switch, 1, 1);
        attach (text_size_label, 0, 2);
        // attach (text_size_scale, 1, 2);
        attach (text_size_mode, 1, 2);
    }
}

