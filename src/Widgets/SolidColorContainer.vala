/*-
 * Copyright (c) 2015-2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: supaiku <supaiku@protonmail.ch>
 *
 */

public class SolidColorContainer : Gtk.FlowBoxChild, IWallpaperContainer {
    private const int THUMB_WIDTH = 162;
    private const int THUMB_HEIGHT = 100;

    public string color { get; construct; }
    public Gdk.RGBA rgba {
        get {
            Gdk.RGBA rgba = {};
            rgba.parse (color);

            return rgba;
        }
    }

    private Gtk.Revealer check_revealer;
    private Granite.AsyncImage image;

    public string? uri { get; construct; }
    public Gdk.Pixbuf thumb { get; set; }

    private int scale;

    const string CARD_STYLE_CSS = """
        flowboxchild,
        GtkFlowBox .grid-child {
            background-color: transparent;
        }

        flowboxchild:focus .card,
        GtkFlowBox .grid-child:focus .card {
            border: 3px solid alpha (#000, 0.2);
            border-radius: 3px;
        }

        flowboxchild:focus .card:checked,
        GtkFlowBox .grid-child:focus .card:checked {
            border-color: @selected_bg_color;
        }
    """;

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                image.set_state_flags (Gtk.StateFlags.CHECKED, false);
                check_revealer.reveal_child = true;
            } else {
                image.unset_state_flags (Gtk.StateFlags.CHECKED);
                check_revealer.reveal_child = false;
            }

            queue_draw ();
        }
    }

    public bool selected {
        get {
            return Gtk.StateFlags.SELECTED in get_state_flags ();
        } set {
            if (value) {
                set_state_flags (Gtk.StateFlags.SELECTED, false);
            } else {
                unset_state_flags (Gtk.StateFlags.SELECTED);
            }

            queue_draw ();
        }
    }

    public SolidColorContainer (string color_value) {
        Object (color: color_value);
    }

    construct {

        scale = get_style_context ().get_scale ();

        height_request = THUMB_HEIGHT + 18;
        width_request = THUMB_WIDTH + 18;

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (CARD_STYLE_CSS, CARD_STYLE_CSS.length);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            critical (e.message);
        }

        image = new Granite.AsyncImage ();
        image.halign = Gtk.Align.CENTER;
        image.valign = Gtk.Align.CENTER;
        image.get_style_context ().set_scale (1);
        // We need an extra grid to not apply a scale == 1 to the "card" style.
        var card_box = new Gtk.Grid ();
        card_box.get_style_context ().add_class ("card");
        card_box.add (image);
        card_box.margin = 9;

        var check = new Gtk.Image.from_icon_name ("selection-checked", Gtk.IconSize.LARGE_TOOLBAR);
        check.halign = Gtk.Align.START;
        check.valign = Gtk.Align.START;

        check_revealer = new Gtk.Revealer ();
        check_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        check_revealer.add (check);

        var overlay = new Gtk.Overlay ();
        overlay.add (card_box);
        // overlay.add_overlay (check_revealer);

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;

        margin = 6;
        add (overlay);

        activate.connect (() => {
            checked = true;
        });

        thumb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, THUMB_WIDTH * scale, THUMB_HEIGHT * scale);
        thumb.fill (rgba_to_pixel (rgba));
    }

    // Borrowed from
    // https://github.com/GNOME/california/blob/master/src/util/util-gfx.vala
    private static uint32 rgba_to_pixel (Gdk.RGBA rgba) {
        return (uint32) fp_to_uint8 (rgba.red) << 24
            | (uint32) fp_to_uint8 (rgba.green) << 16
            | (uint32) fp_to_uint8 (rgba.blue) << 8
            | (uint32) fp_to_uint8 (rgba.alpha);
    }

    private static uint8 fp_to_uint8 (double value) {
        return (uint8) (value * uint8.MAX);
    }
}
