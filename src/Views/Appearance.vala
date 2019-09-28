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
        .color-button radio,
        .color-button radio:checked {
            border-color: alpha (#000, 0.3);
            box-shadow:
                inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                0 1px 0 0 alpha (@bg_highlight_color, 0.3);
            color: #fff;
            padding: 6px;
            -gtk-icon-shadow: none;
        }

        .color-button.blueberry radio {
            background: shade(@BLUEBERRY_300, 0.85);
        }

        .color-button.slate radio {
            background: @SLATE_300;
        }

        .color-button.bubblegum radio {
            background: #f4679d;
        }
    """;
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string STYLESHEET_KEY = "gtk-theme";
    private const string TEXT_SIZE_KEY = "text-scaling-factor";

    private const string PANEL_SCHEMA = "io.elementary.desktop.wingpanel";
    private const string TRANSLUCENCY_KEY = "use-transparency";

    private const string ANIMATIONS_SCHEMA = "org.pantheon.desktop.gala.animations";
    private const string ANIMATIONS_KEY = "enable-animations";

    private const double[] TEXT_SCALE = {0.75, 1, 1.25, 1.5};

    private Granite.Widgets.ModeButton text_size_modebutton;

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        var accent_label = new Gtk.Label (_("Accent color:"));
        accent_label.halign = Gtk.Align.END;

        var blueberry_button = new Gtk.RadioButton (null);
        blueberry_button.tooltip_text = _("Blueberry");
        blueberry_button.width_request = blueberry_button.height_request = 24;

        var blueberry_button_context = blueberry_button.get_style_context ();
        blueberry_button_context.add_class ("color-button");
        blueberry_button_context.add_class ("blueberry");

        var slate_button = new Gtk.RadioButton.from_widget (blueberry_button);
        slate_button.tooltip_text = _("Slate");
        slate_button.width_request = slate_button.height_request = 24;

        var slate_button_context = slate_button.get_style_context ();
        slate_button_context.add_class ("color-button");
        slate_button_context.add_class ("slate");

        var bubblegum_button = new Gtk.RadioButton.from_widget (blueberry_button);
        bubblegum_button.tooltip_text = _("Bubblegum");
        bubblegum_button.width_request = slate_button.height_request = 24;

        var bubblegum_button_context = bubblegum_button.get_style_context ();
        bubblegum_button_context.add_class ("color-button");
        bubblegum_button_context.add_class ("bubblegum");

        var accent_grid = new Gtk.Grid ();
        accent_grid.column_spacing = 6;
        accent_grid.attach (blueberry_button, 0, 0);
        accent_grid.attach (slate_button, 1, 0);
        accent_grid.attach (bubblegum_button, 2, 0);

        var accent_help_label = new Gtk.Label (_("Used across the system by default. Apps can always use their own accent color."));
        accent_help_label.margin_bottom = 6;
        accent_help_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

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

        text_size_modebutton = new Granite.Widgets.ModeButton ();
        text_size_modebutton.append_text (_("Small"));
        text_size_modebutton.append_text (_("Default"));
        text_size_modebutton.append_text (_("Large"));
        text_size_modebutton.append_text (_("Larger"));

        attach (accent_label, 0, 0);
        attach (accent_grid,  1, 0);
        attach (accent_help_label, 1, 1);
        attach (animations_label, 0, 2);
        attach (animations_switch, 1, 2);
        attach (translucency_label, 0, 3);
        attach (translucency_switch, 1, 3);
        attach (text_size_label, 0, 4);
        attach (text_size_modebutton, 1, 4);

        var animations_settings = new Settings (ANIMATIONS_SCHEMA);
        animations_settings.bind (ANIMATIONS_KEY, animations_switch, "active", SettingsBindFlags.DEFAULT);

        var panel_settings = new Settings (PANEL_SCHEMA);
        panel_settings.bind (TRANSLUCENCY_KEY, translucency_switch, "active", SettingsBindFlags.DEFAULT);

        var interface_settings = new Settings (INTERFACE_SCHEMA);

        update_text_size_modebutton (interface_settings);

        interface_settings.changed.connect (() => {
            update_text_size_modebutton (interface_settings);
        });

        text_size_modebutton.mode_changed.connect (() => {
            set_text_scale (interface_settings, text_size_modebutton.selected);
        });

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

        var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);

        if (current_stylesheet == "elementary") {
            blueberry_button.active = true;
        } else if (current_stylesheet == "elementary-slate") {
            slate_button.active = true;
        } else if (current_stylesheet == "elementary-bubblegum") {
            bubblegum_button.active = true;
        }

        blueberry_button.clicked.connect (() => {
            interface_settings.set_string (STYLESHEET_KEY, "elementary");
        });

        slate_button.clicked.connect (() => {
            interface_settings.set_string (STYLESHEET_KEY, "elementary-slate");
        });

        bubblegum_button.clicked.connect (() => {
            interface_settings.set_string (STYLESHEET_KEY, "elementary-bubblegum");
        });
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
