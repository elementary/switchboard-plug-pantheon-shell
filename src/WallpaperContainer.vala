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
    private Gtk.Revealer check_revealer;

    public string uri { get; construct; }
    public Gdk.Pixbuf thumb { get; construct; }

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                set_state_flags (Gtk.StateFlags.CHECKED, value);
                check_revealer.reveal_child = value;
            } else {
                unset_state_flags (Gtk.StateFlags.CHECKED);
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

    public WallpaperContainer (string uri) {
        Object (uri: uri, thumb: null);
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

        var image = new Gtk.Image.from_pixbuf (thumb);
        image.get_style_context ().add_class ("card");
        image.halign = Gtk.Align.CENTER;
        image.margin = 6;

        var check = new Gtk.Image.from_icon_name ("selection-checked", Gtk.IconSize.LARGE_TOOLBAR);

        check_revealer = new Gtk.Revealer ();
        check_revealer.add (check);

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (image);
        overlay.add_overlay (check_revealer);

        height_request = thumb.get_height () + 2 * THUMB_MARGIN;
        width_request = thumb.get_width () + 2 * THUMB_MARGIN;
        add (overlay);

        activate.connect (() => {
            checked = true;
        });
    }
}
