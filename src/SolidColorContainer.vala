//
//  Copyright (c) 2015 supaiku (supaiku@protonmail.ch)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public class SolidColorContainer : WallpaperContainer {

    public string color { get; construct; }

    public SolidColorContainer (string color_value) {
        Object (color: color_value, thumb: new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 150, 100));
    }

    construct {
        thumb.fill (rgba_to_pixel (get_rgba ()));
    }

    public Gdk.RGBA get_rgba () {
        Gdk.RGBA rgba = {};
        rgba.parse (color);

        return rgba;
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
