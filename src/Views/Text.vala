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

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 12;
        margin_bottom = 24;

        var text_size_label = new Gtk.Label (_("Size:")) {
            halign = Gtk.Align.END
        };

        text_size_modebutton = new Granite.Widgets.ModeButton ();
        text_size_modebutton.append_text (_("Small"));
        text_size_modebutton.append_text (_("Default"));
        text_size_modebutton.append_text (_("Large"));
        text_size_modebutton.append_text (_("Larger"));

        var dyslexia_font_label = new Gtk.Label (_("Dyslexia-friendly:")) {
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

        var antialiasing_header = new Granite.HeaderLabel (_("Anti-aliasing")) {
            margin_top = 12
        };

        string demo_string = _("Anti-aliasing improves text appearance and legibility depending on display hardware. Choose the options below that make this text the most legible on your hardware.");

        var grayscale_font_options = new Cairo.FontOptions ();
        grayscale_font_options.set_antialias (Cairo.Antialias.GRAY);

        var subpixel_font_options = new Cairo.FontOptions ();
        subpixel_font_options.set_antialias (Cairo.Antialias.SUBPIXEL);

        var rgb_font_options = new Cairo.FontOptions ();
        rgb_font_options.set_antialias (Cairo.Antialias.SUBPIXEL);
        rgb_font_options.set_subpixel_order (Cairo.SubpixelOrder.RGB);

        var bgr_font_options = new Cairo.FontOptions ();
        bgr_font_options.set_antialias (Cairo.Antialias.SUBPIXEL);
        bgr_font_options.set_subpixel_order (Cairo.SubpixelOrder.BGR);

        var vrgb_font_options = new Cairo.FontOptions ();
        vrgb_font_options.set_antialias (Cairo.Antialias.SUBPIXEL);
        vrgb_font_options.set_subpixel_order (Cairo.SubpixelOrder.VRGB);

        var vbgr_font_options = new Cairo.FontOptions ();
        vbgr_font_options.set_antialias (Cairo.Antialias.SUBPIXEL);
        vbgr_font_options.set_subpixel_order (Cairo.SubpixelOrder.VBGR);

        var grayscale_demo = new Gtk.Label (demo_string) {
            margin = 12,
            max_width_chars = 1, // Prevent the string from expanding the grid
            wrap = true,
            xalign = 0
        };

        var demo_stack = new Gtk.Stack () {
            margin_bottom = 12
        };
        demo_stack.add (grayscale_demo);

        unowned Gtk.StyleContext demo_stack_context = demo_stack.get_style_context ();
        demo_stack_context.add_class (Granite.STYLE_CLASS_CARD);
        demo_stack_context.add_class (Granite.STYLE_CLASS_ROUNDED);
        demo_stack_context.add_class (Gtk.STYLE_CLASS_VIEW);

        var antialias_label = new Gtk.Label (_("Method:")) {
            halign = Gtk.Align.END
        };

        // Needed to handle options outside of these choices
        var antialias_invalid_radio = new Gtk.RadioButton (null);

        var grayscale_label = new Gtk.Label (_("Default"));
        grayscale_label.set_font_options (grayscale_font_options);

        var grayscale_radio = new Gtk.RadioButton.from_widget (antialias_invalid_radio);
        grayscale_radio.add (grayscale_label);

        var subpixel_label = new Gtk.Label (_("Subpixel"));
        subpixel_label.set_font_options (subpixel_font_options);

        var subpixel_radio = new Gtk.RadioButton.from_widget (antialias_invalid_radio);
        subpixel_radio.add (subpixel_label);

        var antialias_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        antialias_grid.add (grayscale_radio);
        antialias_grid.add (subpixel_radio);

        var subpixel_order_label = new Gtk.Label (_("Subpixel order:")) {
            halign = Gtk.Align.END
        };

        /// TRANSLATORS: Subpixel order for red, green, blue from left to right
        var rgb_label = new Gtk.Label (_("RGB"));
        rgb_label.set_font_options (rgb_font_options);

        var rgb_radio = new Gtk.RadioButton (null);
        rgb_radio.add (rgb_label);

        /// TRANSLATORS: Subpixel order for blue, green, red from left to right
        var bgr_label = new Gtk.Label (_("BGR"));
        bgr_label.set_font_options (bgr_font_options);

        var bgr_radio = new Gtk.RadioButton.from_widget (rgb_radio);
        bgr_radio.add (bgr_label);

        /// TRANSLATORS: Subpixel order for red, green, blue from top to bottom
        var vrgb_label = new Gtk.Label (_("Vertical RGB"));
        vrgb_label.set_font_options (vrgb_font_options);

        var vrgb_radio = new Gtk.RadioButton.from_widget (rgb_radio);
        vrgb_radio.add (vrgb_label);

        /// TRANSLATORS: Subpixel order for blue, green, red from top to bottom
        var vbgr_label = new Gtk.Label (_("Vertical BGR"));
        vbgr_label.set_font_options (vbgr_font_options);

        var vbgr_radio = new Gtk.RadioButton.from_widget (rgb_radio);
        vbgr_radio.add (vbgr_label);

        var subpixel_order_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        subpixel_order_grid.add (rgb_radio);
        subpixel_order_grid.add (bgr_radio);
        subpixel_order_grid.add (vrgb_radio);
        subpixel_order_grid.add (vbgr_radio);

        attach (text_size_label, 0, 0);
        attach (text_size_modebutton, 1, 0);

        attach (dyslexia_font_label, 0, 1);
        attach (dyslexia_font_switch, 1, 1);
        attach (dyslexia_font_description_label, 1, 2);

        attach (antialiasing_header, 0, 3, 2);
        attach (demo_stack, 0, 4, 2);
        attach (antialias_label, 0, 5);
        attach (antialias_grid, 1, 5);

        attach (subpixel_order_label, 0, 6);
        attach (subpixel_order_grid, 1, 6);

        var interface_settings = new GLib.Settings (INTERFACE_SCHEMA);

        update_text_size_modebutton (interface_settings);

        interface_settings.changed.connect (() => {
            update_text_size_modebutton (interface_settings);
        });

        text_size_modebutton.mode_changed.connect (() => {
            set_text_scale (interface_settings, text_size_modebutton.selected);
        });

        subpixel_radio.bind_property (
            "active",
            subpixel_order_label,
            "sensitive",
            BindingFlags.SYNC_CREATE
        );

        subpixel_radio.bind_property (
            "active",
            subpixel_order_grid,
            "sensitive",
            BindingFlags.SYNC_CREATE
        );

        dyslexia_font_switch.set_active (update_dyslexia_font_switch (interface_settings));

        dyslexia_font_switch.state_set.connect (() => {
            toggle_dyslexia_support (interface_settings, dyslexia_font_switch.get_active () );
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
}
