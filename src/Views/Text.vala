/*
* Copyright 2021 elementary, Inc. (https://elementary.io)
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

public class PantheonShell.Text : Gtk.Box {
    private const string DYSLEXIA_KEY = "dyslexia-friendly-support";
    private const string FONT_KEY = "font-name";
    private const string DOCUMENT_FONT_KEY = "document-font-name";
    private const string MONOSPACE_FONT_KEY = "monospace-font-name";

    private const string OD_REG_FONT = "OpenDyslexic Regular 9";
    private const string OD_DOC_FONT = "OpenDyslexic Regular 10";
    private const string OD_MON_FONT = "OpenDyslexicMono Regular 10";

    private uint scale_timeout;

    construct {
        var size_label = new Granite.HeaderLabel (_("Size"));

        var size_adjustment = new Gtk.Adjustment (-1, 0.75, 1.5, 0.05, 0, 0);

        var size_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, size_adjustment) {
            draw_value = false,
            hexpand = true
        };
        size_scale.add_mark (1, Gtk.PositionType.TOP, null);
        size_scale.add_mark (1.25, Gtk.PositionType.TOP, null);

        var size_spinbutton = new Gtk.SpinButton (size_adjustment, 0.25, 2);

        var size_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        size_grid.attach (size_label, 0, 0);
        size_grid.attach (size_scale, 0, 1);
        size_grid.attach (size_spinbutton, 1, 1);

        var dyslexia_font_label = new Granite.HeaderLabel (_("Dyslexia-friendly"));

        var dyslexia_font_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };

        var dyslexia_font_description_label = new Gtk.Label (
            _("Bottom-heavy shapes and increased character spacing can help improve legibility and reading speed.")
        ) {
            wrap = true,
            xalign = 0
        };
        dyslexia_font_description_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var dyslexia_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        dyslexia_grid.attach (dyslexia_font_label, 0, 0);
        dyslexia_grid.attach (dyslexia_font_description_label, 0, 1);
        dyslexia_grid.attach (dyslexia_font_switch, 1, 0, 1, 2);

        var box = new Gtk.Box (VERTICAL, 24) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 24
        };
        box.append (size_grid);
        box.append (dyslexia_grid);

        var clamp = new Adw.Clamp () {
            child = box
        };

        append (clamp);

        var interface_settings = new Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("text-scaling-factor", size_adjustment, "value", SettingsBindFlags.GET);

        // Setting scale is slow, so we wait while pressed to keep UI responsive
        size_adjustment.value_changed.connect (() => {
            if (scale_timeout != 0) {
                GLib.Source.remove (scale_timeout);
            }

            scale_timeout = Timeout.add (300, () => {
                scale_timeout = 0;
                interface_settings.set_double ("text-scaling-factor", size_adjustment.value);
                return false;
            });
        });

        var interface_font = interface_settings.get_string (FONT_KEY);
        var document_font = interface_settings.get_string (DOCUMENT_FONT_KEY);
        var monospace_font = interface_settings.get_string (MONOSPACE_FONT_KEY);

        dyslexia_font_switch.active = interface_font == OD_REG_FONT || document_font == OD_DOC_FONT || monospace_font == OD_MON_FONT;

        dyslexia_font_switch.state_set.connect (() => {
            if (dyslexia_font_switch.active) {
                interface_settings.set_string (FONT_KEY, OD_REG_FONT);
                interface_settings.set_string (DOCUMENT_FONT_KEY, OD_DOC_FONT);
                interface_settings.set_string (MONOSPACE_FONT_KEY, OD_MON_FONT);
            } else {
                interface_settings.reset (FONT_KEY);
                interface_settings.reset (DOCUMENT_FONT_KEY);
                interface_settings.reset (MONOSPACE_FONT_KEY);
            }
            return Gdk.EVENT_PROPAGATE;
        });
    }
}
