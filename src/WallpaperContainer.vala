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
 * Authored by: Erasmo Marín
 *
 */

public class WallpaperContainer : Gtk.FlowBoxChild {
    private const int THUMB_MARGIN = 3;
    private static Gdk.Pixbuf checked_icon = null;
    private static string STYLE =
        """GtkFlowBoxChild:selected {
           background-color: @selected_bg_color;
           color: @selected_fg_color;
       }""";

    private Gdk.RGBA selected_color;

    public string uri { get; construct; }
    public Gdk.Pixbuf thumb { get; construct; }

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                set_state_flags (Gtk.StateFlags.CHECKED, false); 
            } else {
                unset_state_flags (Gtk.StateFlags.CHECKED);
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

    public WallpaperContainer (string uri) {
        Object (uri: uri, thumb: null);
    }

    static construct {
        try {
            Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
            checked_icon = icon_theme.load_icon ("selection-checked", 32, Gtk.IconLookupFlags.FORCE_SIZE);
        } catch (GLib.Error err) {
            warning ("Getting selection-checked icon from theme failed");
        }
    }

    construct {
         try {
            if (thumb == null && uri != null) {
                if (Cache.is_cached (uri)) {
                    this.thumb = Cache.get_cached_image (uri);
                } else {
                    this.thumb = new Gdk.Pixbuf.from_file_at_scale (GLib.Filename.from_uri (uri), 150, 100, false);
                    Cache.cache_image_pixbuf (thumb, uri);
                }
            }
        } catch (Error e) {
            critical ("Failed to load wallpaper thumbnail: %s", e.message);
            return;
        }

        //style
        try {
            var item_style_provider = new Gtk.CssProvider ();
            item_style_provider.load_from_data (STYLE, -1);
            get_style_context ().add_provider (item_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (GLib.Error err) {
            warning ("Loading style failed: %s", err.message);
        }

        //load selected color
        selected_color = get_style_context ().get_background_color (Gtk.StateFlags.SELECTED);

        this.height_request = thumb.get_height () + 2 * THUMB_MARGIN;
        this.width_request = thumb.get_width () + 2 * THUMB_MARGIN;

        activate.connect (() => {
            checked = true;
        });
    }

    public override bool draw (Cairo.Context cr) {
        int width = (int) (thumb.get_width () + 2 * THUMB_MARGIN);
        int height = (int) (thumb.get_height () + 2 * THUMB_MARGIN);

        if ((get_state_flags () & Gtk.StateFlags.SELECTED) == Gtk.StateFlags.SELECTED) {
            //paint selection background
            cr.set_source_rgba (selected_color.red, selected_color.green, selected_color.blue, selected_color.alpha);
            Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, 0, 0, width, height, 3);
            cr.fill ();
        }

        cr.save ();
        Gdk.cairo_set_source_pixbuf (cr, thumb, THUMB_MARGIN, THUMB_MARGIN);
        cr.paint ();

        if ((get_state_flags () & Gtk.StateFlags.CHECKED) == Gtk.StateFlags.CHECKED && checked_icon != null) {
            int x = width / 2 - checked_icon.get_width () / 2;
            int y = height / 2 - checked_icon.get_height () / 2;

            Gdk.cairo_set_source_pixbuf (cr, checked_icon, x, y);
            cr.paint ();
        }

        cr.restore ();
        return true;
    }
}
