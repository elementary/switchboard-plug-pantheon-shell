/*
* Copyright 2018–2021 elementary, Inc. (https://elementary.io)
* Copyright 2021 Justin Haygood (jhaygood86@gmail.com)
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

public class PantheonShell.Text : Gtk.Grid {
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string XSETTINGS_SCHEMA = "org.gnome.settings-daemon.plugins.xsettings";
    private const string TEXT_SIZE_KEY = "text-scaling-factor";
    private const string ANTIALIAS_KEY = "antialiasing";
    private const string SUBPIXELORDER_KEY = "rgba-order";

    private const string DYSLEXIA_KEY = "dyslexia-friendly-support";
    private const string FONT_KEY = "font-name";
    private const string DOCUMENT_FONT_KEY = "document-font-name";
    private const string MONOSPACE_FONT_KEY = "monospace-font-name";

    private const string OD_REG_FONT = "OpenDyslexic Regular 9";
    private const string OD_DOC_FONT = "OpenDyslexic Regular 10";
    private const string OD_MON_FONT = "OpenDyslexicMono Regular 10";

    private const double[] TEXT_SCALE = {0.75, 1, 1.25, 1.5};

    private Granite.Widgets.ModeButton text_size_modebutton;
    private TextFontOptionRadioGroup text_antialias_group;
    private TextFontOptionRadioGroup text_subpixelorder_group;
    private Gtk.Label text_subpixelorder_label;
    private Gtk.Label text_subpixelorder_description_label;

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 12;
        margin_bottom = 24;

        var text_size_label = new Gtk.Label (_("Size:")) {
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

        var text_antialias_label = new Gtk.Label (_("Anti-aliasing:")) {
            halign = Gtk.Align.END,
            margin_top = 18
        };

        text_antialias_group = new TextFontOptionRadioGroup () {
            margin_top = 18
        };

        text_antialias_group.append_option (_("Default"), (font_options) => {
            font_options.set_antialias (Cairo.Antialias.GRAY);
        });

        text_antialias_group.append_option (_("Subpixel"), (font_options) => {
            font_options.set_antialias (Cairo.Antialias.SUBPIXEL);
        });

        text_antialias_description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        text_subpixelorder_label = new Gtk.Label (_("Subpixel order:")) {
            halign = Gtk.Align.END,
            margin_top = 18
        };

        text_subpixelorder_group = new TextFontOptionRadioGroup () {
            margin_top = 18
        };

        text_subpixelorder_group.append_option (_("RGB"), (font_options) => {
            font_options.set_subpixel_order (Cairo.SubpixelOrder.RGB);
        });

        text_subpixelorder_group.append_option (_("BGR"), (font_options) => {
            font_options.set_subpixel_order (Cairo.SubpixelOrder.BGR);
        });

        text_subpixelorder_group.append_option (_("Vertical RGB"), (font_options) => {
            font_options.set_subpixel_order (Cairo.SubpixelOrder.VRGB);
        });

        text_subpixelorder_group.append_option (_("Vertical BGR"), (font_options) => {
            font_options.set_subpixel_order (Cairo.SubpixelOrder.VBGR);
        });

        text_subpixelorder_description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);


        var dyslexia_font_label = new Gtk.Label (_("Dyslexia-friendly font:")) {
            halign = Gtk.Align.END,
            margin_top = 18
        };

        var dyslexia_font_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            margin_top = 18
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
        attach (text_size_label, 0, 8);
        attach (text_size_modebutton, 1, 8, 2);

        attach (text_antialias_label, 0, 9);
        attach (text_antialias_group, 1, 9, 2);
        attach (text_antialias_description_label, 1, 10, 2);

        attach (text_subpixelorder_label, 0, 11);
        attach (text_subpixelorder_group, 1, 11, 2);
        attach (text_subpixelorder_description_label, 1, 12, 2);

        attach (dyslexia_font_label, 0, 13);
        attach (dyslexia_font_switch, 1, 13);
        attach (dyslexia_font_description_label, 1, 14, 2);

        var interface_settings = new GLib.Settings (INTERFACE_SCHEMA);

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

        var xsettings_settings = new GLib.Settings (XSETTINGS_SCHEMA);

        update_text_antialias_modebutton (xsettings_settings);

        xsettings_settings.changed.connect (() => {
            update_text_antialias_modebutton (xsettings_settings);
            update_text_subpixelorder_modebutton (xsettings_settings);
        });

        text_antialias_group.changed.connect (() => {
            set_text_antialias (xsettings_settings, text_antialias_group.selected);
        });

        update_text_subpixelorder_modebutton (xsettings_settings);

        text_subpixelorder_group.changed.connect (() => {
            set_text_subpixelorder (xsettings_settings, text_subpixelorder_group.selected);
        });
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

    private int get_text_antialias (GLib.Settings xsettings_settings) {
        return xsettings_settings.get_enum (ANTIALIAS_KEY);
    }

    private void set_text_antialias (GLib.Settings xsettings_settings, int option) {
        xsettings_settings.set_enum (ANTIALIAS_KEY, option);
    }

    private void update_text_antialias_modebutton (GLib.Settings xsettings_settings) {
        text_antialias_group.set_active (get_text_antialias (xsettings_settings));
    }

    private int get_text_subpixelorder (GLib.Settings xsettings_settings) {
        return xsettings_settings.get_enum (SUBPIXELORDER_KEY) - 1;
    }

    private void set_text_subpixelorder (GLib.Settings xsettings_settings, int option) {
        xsettings_settings.set_enum (SUBPIXELORDER_KEY, option + 1);
    }

    private void update_text_subpixelorder_modebutton (GLib.Settings xsettings_settings) {

        var antialias = get_text_antialias (xsettings_settings);

        if (antialias != 2) {
           text_subpixelorder_label.visible = false;
           text_subpixelorder_group.visible = false;
           text_subpixelorder_description_label.visible = false;
        } else {
           text_subpixelorder_label.visible = true;
           text_subpixelorder_group.visible = true;
           text_subpixelorder_description_label.visible = true;
        }

        text_subpixelorder_group.set_active (get_text_subpixelorder (xsettings_settings));
    }

}
