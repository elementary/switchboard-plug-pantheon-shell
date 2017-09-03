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
 */

namespace Utils {
    public const string[] WALLPAPER_ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    public static bool is_valid_wallpaper (GLib.FileInfo info) {
        // Check for correct file type, don't try to load directories and such
        if (info.get_file_type () != GLib.FileType.REGULAR) {
            return false;
        }

        foreach (var type in WALLPAPER_ACCEPTED_TYPES) {
            if (GLib.ContentType.equals (info.get_content_type (), type)) {
                return true;
            }
        }

        return false;
    }    
}
