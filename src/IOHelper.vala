/*-
 * Copyright (c) 2017-2018 elementary LLC.
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
public class IOHelper : GLib.Object {
    public const string [] REQUIRED_FILE_ATTRS = {
        FileAttribute.STANDARD_NAME,
        FileAttribute.STANDARD_TYPE,
        FileAttribute.STANDARD_CONTENT_TYPE,
        FileAttribute.STANDARD_IS_HIDDEN,
        FileAttribute.STANDARD_IS_BACKUP,
        FileAttribute.THUMBNAIL_PATH,
        FileAttribute.THUMBNAIL_IS_VALID
    };

    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    // Check if the filename has a picture file extension.
    public static bool is_valid_file_type (GLib.FileInfo file_info) {
        // Check for correct file type, don't try to load directories and such
        if (file_info.get_file_type () != GLib.FileType.REGULAR) {
            return false;
        }

        foreach (var type in ACCEPTED_TYPES) {
            if (GLib.ContentType.equals (file_info.get_content_type (), type)) {
                return true;
            }
        }

        return false;
    }
}
