/*-
 * Copyright 2015-2022 elementary, Inc. (https://elementary.io)
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

public class PantheonShell.ImageContainer : UriContainer {
    private bool thumb_valid { get; set; default = false; }
    private string? thumb_path { get; set; default = null; }

    public ImageContainer (string uri) {
        Object (uri: uri);
    }

    construct {
        // load file info            
        var file = File.new_for_uri (uri);
        try {
            var info = file.query_info ("*", FileQueryInfoFlags.NONE);
            load_thumb_info (info);
            move_to_trash.sensitive = info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE);
        } catch (Error e) {
            critical (e.message);
        }

        // load thumb
        if (thumb_valid && thumb_path != null) {
            update_thumb.begin ();
        } else {
            generate_and_load_thumb ();
        }
    }

    private void load_thumb_info (FileInfo info) {
        thumb_valid = info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID);
        thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
    }

    private async void update_thumb () {
        if (!thumb_valid || thumb_path == null) {
            return;
        }

        image.set_filename (thumb_path);

        load_artist_tooltip ();
    }

    private void generate_and_load_thumb () {
        var scale = get_style_context ().get_scale ();
        ThumbnailGenerator.get_default ().get_thumbnail (uri, THUMB_WIDTH * scale, () => {
            try {
                var file = File.new_for_uri (uri);
                var info = file.query_info (
                    string.join (",", FileAttribute.THUMBNAIL_PATH, FileAttribute.THUMBNAIL_IS_VALID),
                    FileQueryInfoFlags.NONE
                );
                load_thumb_info (info);
                update_thumb.begin ();
            } catch (Error e) {
                warning ("Error loading thumbnail for \"%s\": %s", uri, e.message);
            }
        });
    }

    private void load_artist_tooltip () {
        var metadata = new GExiv2.Metadata ();
        try {
            var path = Filename.from_uri (uri);
            metadata.open_path (path);
        } catch (Error e) {
            warning ("Error parsing exif metadata of \"%s\": %s", uri, e.message);
            return;
        }

        if (metadata.has_exif ()) {
            string? artist_name = null;
            try {
                artist_name = metadata.try_get_tag_string ("Exif.Image.Artist");
            } catch (Error e) {
                warning (e.message);
            }

            if (artist_name != null) {
                set_tooltip_text (_("Artist: %s").printf (artist_name));
            }
        }
    }
}
