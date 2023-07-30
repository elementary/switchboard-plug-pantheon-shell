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

public class PantheonShell.SolidColorContainer : WallpaperContainer {
    private static GLib.Settings settings;

    static construct {
        settings = new GLib.Settings ("org.gnome.desktop.background");
    }

    public SolidColorContainer () {
        Object ();
    }

    construct {
        fill_thumb ();
        settings.changed["primary-color"].connect (fill_thumb);
    }

    private void fill_thumb () {
        Gdk.RGBA rgba = {};
        rgba.parse (settings.get_string ("primary-color"));

        var scale = get_style_context ().get_scale ();
        var thumb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, THUMB_WIDTH * scale, THUMB_HEIGHT * scale);
        thumb.fill (rgba_to_pixel (rgba));

        image.gicon = thumb;
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
